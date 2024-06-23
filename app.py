from functools import wraps
import cv2
from flask import Flask, request, jsonify
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, auth, db
import numpy as np
import pyrebase
import datetime
import logging
from facenet_pytorch import MTCNN, InceptionResnetV1
import torch
import pandas as pd
import requests
from scipy.spatial.distance import cosine
import jwt
from flask import g
from keras.models import Sequential, load_model

app = Flask(__name__)
CORS(app)  # This will enable CORS for all routes

# Set secret key for JWT
app.config['SECRET_KEY'] = 'secretkey'  
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

cred = credentials.Certificate("pre-thesis-c1f05-firebase-adminsdk-lqnb3-c6ea7bff1a.json")
firebase_admin.initialize_app(cred, {'databaseURL': 'https://pre-thesis-c1f05-default-rtdb.firebaseio.com/'})



firebase = pyrebase.initialize_app(firebase_config)
firebase_auth = firebase.auth()

# Initialize MTCNN and FaceNet
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
mtcnn = MTCNN(keep_all=True, device=device)

facenet_model = InceptionResnetV1(pretrained='vggface2').eval().to(device)
# model_path = 'facenet512_weights.h5'  
# facenet_model = load_model(model_path)

ALLOWED_IMAGE_EXTENSIONS = {'png', 'jpg', 'jpeg'}

# Error handling decorator
def handle_errors(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            logging.exception(f"An error occurred: {str(e)}")
            return jsonify({"error": str(e)}), 500
    return wrapper
def generate_token(user_id, role):
    # Use timezone-aware UTC datetime object
    now = datetime.datetime.now(datetime.timezone.utc)
    exp = now + datetime.timedelta(hours=24)
    
    payload = {
        'user_id': user_id,
        'role': role,
        'exp': exp
    }
    
    token = jwt.encode(payload, app.config['SECRET_KEY'], algorithm='HS256')
    return token

TOKEN_BLACKLIST = set()

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            token = request.headers['Authorization'].split(" ")[1]
        if not token:
            return jsonify({"error": "Token is missing"}), 401
        try:
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
            current_user = data['user_id']
            current_role = data['role']
        except Exception as e:
            return jsonify({"error": "Token is invalid or expired"}), 401
        # Ensure correct argument passing
        kwargs['current_user'] = current_user
        kwargs['current_role'] = current_role
        return f(*args, **kwargs)
    return decorated


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_IMAGE_EXTENSIONS

def extract_face(img, box, margin=40):
    x1, y1, x2, y2 = box
    x1 = int(max(x1 - margin / 2, 0))
    y1 = int(max(y1 - margin / 2, 0))
    x2 = int(min(x2 + margin / 2, img.shape[1]))
    y2 = int(min(y2 + margin / 2, img.shape[0]))
    face = img[y1:y2, x1:x2]
    face = cv2.resize(face, (160, 160))
    face = torch.tensor(face).permute(2, 0, 1).float() / 255.0
    return face

def face_recognition(face_embedding):
    database_ref = db.reference("users")
    database_snapshot = database_ref.get()

    if database_snapshot:
        for db_user_id, db_data in database_snapshot.items():
            db_embedding = db_data.get("embedding", [])
            if db_embedding:
                db_embedding = np.array(db_embedding)
                face_embedding = np.array(face_embedding)
                distance = np.linalg.norm(face_embedding - db_embedding)
                logging.info(f"Comparing with user: {db_user_id}, distance: {distance}")
                if distance < 0.7:  # Adjust the threshold as necessary
                    return db_user_id

    return None


def save_to_firebase(user_name, uid, user_id, embedding, role):
    user_ref = db.reference(f"users/{user_id}")
    user_ref.set({
        "uid": uid,
        "name": user_name,
        "embedding": embedding,
        "role": role
    })
    logging.info(f"Saved user to Firebase: user_id={user_id}, uid={uid}")

def is_registered(user_id):
    user_ref = db.reference(f"users/{user_id}")
    user_data = user_ref.get()
    logging.debug(f"Checking registration for user_id={user_id}, found={user_data is not None}")
    return user_data is not None

def is_duplicate_embedding(embedding, threshold=0.5):
    database_ref = db.reference("users")
    users_snapshot = database_ref.get()
    if users_snapshot:
        for _, data in users_snapshot.items():
            saved_embedding = data.get("embedding", [])
            if len(saved_embedding) == len(embedding):
                distance = cosine(saved_embedding, embedding)
                if distance < threshold:
                    return True
    return False



########################################################################################################################
@app.route('/register', methods=['POST'])
@handle_errors
def register():
    if 'file' not in request.files or 'id' not in request.form or 'name' not in request.form or 'email' not in request.form or 'password' not in request.form:
        return jsonify({"error": "Invalid request"}), 400
    
    email = request.form.get('email')
    password = request.form.get('password')
    file = request.files['file']
    user_id = request.form['id']
    user_name = request.form['name']
    role = request.form.get('role', 'user')

    if file.filename == '':
        return jsonify({"error": "File name is empty"}), 400

    if is_registered(user_id):
        return jsonify({"error": "User is already registered"}), 400

    img_stream = file.read()
    nparr = np.frombuffer(img_stream, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    faces, _ = mtcnn.detect(img)
    if faces is not None:
        face = extract_face(img, faces[0], margin=40)
        embedding = facenet_model(face.unsqueeze(0).to(device)).squeeze().detach().cpu().numpy().tolist()

        if is_duplicate_embedding(embedding):
            return jsonify({"error": "Face already registered"}), 400

        user = firebase_auth.create_user_with_email_and_password(email, password)
        uid = user['localId']
        auth.set_custom_user_claims(uid, {'role': role})
        
        # Ensure user_id is saved correctly
        save_to_firebase(user_name, uid, user_id, embedding, role)
        logging.info(f"User registered successfully: user_id={user_id}, uid={uid}")
        return jsonify({"message": "User registered successfully", "uid": uid}), 201
    else:
        return jsonify({"error": "No face detected"}), 400

########################################################################################################################
@app.route('/login', methods=['POST'])
@handle_errors
def login():
    email = request.form.get('email')
    password = request.form.get('password')

    user = firebase_auth.sign_in_with_email_and_password(email, password)
    id_token = user['idToken']
    decoded_token = auth.verify_id_token(id_token)
    user_id = decoded_token.get('user_id', decoded_token.get('uid'))
    role = decoded_token.get('role', 'user')

    token = generate_token(user_id, role)
    return jsonify({"message": "Login successful", "token": token, "role": role, "user_id": user_id}), 200
########################################################################################################################
@app.route('/logout', methods=['POST'])
@token_required
@handle_errors
def logout(current_user, current_role):
    token = request.headers['Authorization'].split(" ")[1]
    
    # Add the token to the blacklist
    TOKEN_BLACKLIST.add(token)
    
    return jsonify({"message": "Logout successful"}), 200

########################################################################################################################
@app.route('/attendance', methods=['POST'])
@token_required
@handle_errors
def attendance(current_user, current_role):
    if 'file' not in request.files or 'class_id' not in request.form:
        return jsonify({"error": "File or class_id not found"}), 400

    file = request.files['file']
    class_id = request.form['class_id']

    if file.filename == '':
        return jsonify({"error": "File name is empty"}), 400

    try:
        img_stream = file.read()
        nparr = np.frombuffer(img_stream, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        faces, _ = mtcnn.detect(img)
        if faces is not None:
            logging.info(f"Detected faces: {faces}")
            face = extract_face(img, faces[0], margin=40)
            embedding = facenet_model(face.unsqueeze(0).to(device)).squeeze().detach().cpu().numpy()
            logging.info(f"Generated embedding: {embedding}")

            matched_student = face_recognition(embedding)
            if matched_student:
                logging.info(f"Matched student: {matched_student}")
                if matched_student :
                    update_attendance(class_id, matched_student)
                    return jsonify({"message": f"Attendance recorded for {matched_student} in class {class_id}"}), 200
                else:
                    return jsonify({"error": "Face does not match the logged-in user"}), 400
            else:
                logging.info("No match found")
                return jsonify({"error": "No match found"}), 400
        else:
            logging.info("No face detected")
            return jsonify({"error": "No face detected"}), 400

    except Exception as e:
        logging.exception("An error occurred during attendance")
        return jsonify({"error": str(e)}), 500

def update_attendance(class_id, user_id):
    attendance_ref = db.reference(f"attendance/{class_id}/{user_id}")
    attendance_ref.push().set({
        'timestamp': datetime.datetime.now().isoformat(),
    })


########################################################################################################################
@app.route('/add_students_to_class_bulk', methods=['POST'])
@token_required
@handle_errors
def add_students_to_class_bulk(current_user, current_role):
    if 'class_id' not in request.form or 'file' not in request.files:
        return jsonify({"error": "Invalid request"}), 400

    class_id = request.form['class_id']
    file = request.files['file']

    if file.filename == '':
        return jsonify({"error": "File name is empty"}), 400

    try:
        data = pd.read_excel(file)

        if 'id' not in data.columns:
            return jsonify({"error": "Excel file must contain 'id' column"}), 400

        class_ref = db.reference(f"classes/{class_id}")
        class_data = class_ref.get()

        if not class_data:
            return jsonify({"error": "Class not found"}), 404

        users = class_data.get("users", [])

        results = []
        for _, row in data.iterrows():
            user_id = row['id']
            if user_id in users:
                results.append({"id": user_id, "error": "User already in class"})
                continue

            users.append(user_id)
            results.append({"id": user_id, "message": "User added to class successfully"})

        class_ref.update({"users": users})

        return jsonify(results), 200

    except Exception as e:
        logging.error(f"Error during bulk user addition: {e}")
        return jsonify({"error": str(e)}), 500



########################################################################################################################
@app.route('/get_user_classes', methods=['GET'])
@token_required
@handle_errors
def get_user_classes(current_user, current_role):
    try:
        logging.info(f"Fetching classes for user: {current_user} with role: {current_role}")

        # Reference to the "classes" node in the Firebase Realtime Database
        database_ref = db.reference("classes")
        classes = database_ref.get()

        if classes is None:
            logging.warning("No classes found in the database.")
            return jsonify({"user_classes": []}), 200

        logging.info(f"Classes retrieved from database: {classes}")

        # Find the classes the current user is part of
        user_classes = []
        for class_id, class_data in classes.items():
            logging.info(f"Checking class: {class_id} with data: {class_data}")
            users_in_class = class_data.get("users", [])
            logging.info(f"Users in class {class_id}: {users_in_class}")

            if isinstance(users_in_class, list) and current_user in users_in_class:
                logging.info(f"User {current_user} is in class: {class_id}")
                user_classes.append({
                    "class_id": class_id,
                    "class_name": class_data.get("class_name")
                })
            else:
                logging.info(f"User {current_user} is not in class: {class_id}")

        logging.info(f"User classes: {user_classes}")
        return jsonify({"user_classes": user_classes}), 200
    except Exception as e:
        logging.exception(f"An error occurred while fetching user classes: {str(e)}")
        return jsonify({"error": str(e)}), 500









########################################################################################################################
@app.route('/create_admin', methods=['POST'])
@token_required
@handle_errors
def create_admin(current_user, current_role):
    if current_role != 'admin':
        return jsonify({"error": "Unauthorized access"}), 403

    if 'email' not in request.json or 'password' not in request.json:
        return jsonify({"error": "Invalid request"}), 400

    email = request.json['email']
    password = request.json['password']

    try:
        user = firebase_auth.create_user_with_email_and_password(email, password)
        uid = user['localId']

        auth.set_custom_user_claims(uid, {'role': 'admin'})

        logging.info(f"Admin account created successfully: email={email}, uid={uid}")
        return jsonify({"message": "Admin account created successfully", "uid": uid}), 200
    except Exception as e:
        logging.error(f"Error creating admin: {e}")
        return jsonify({"error": str(e)}), 500


# ########################################################################################################################
@app.route('/create_class', methods=['POST'])
@token_required
@handle_errors
def create_class(current_user, current_role):
    if 'class_id' not in request.form or 'class_name' not in request.form:
        return jsonify({"error": "Invalid request"}), 400

    class_id = request.form['class_id']
    class_name = request.form['class_name']

    try:
        database_ref = db.reference("classes")
        class_data = {
            "class_name": class_name,
            "users": [],
            "creator_uid": current_user  # Store the creator's UID
        }
        database_ref.child(class_id).set(class_data)
        return jsonify({"message": "Class created successfully", "class_id": class_id, "class_name": class_name}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
########################################################################################################################
@app.route('/add_user_to_class', methods=['POST'])
@token_required
@handle_errors
def add_user_to_class(current_user, current_role):
    if 'class_id' not in request.form or 'user_id' not in request.form:
        return jsonify({"error": "Invalid request"}), 400

    class_id = request.form['class_id']
    user_id = request.form['user_id']

    try:
        # Check if the user_id exists in the users reference
        if not is_registered(user_id):
            logging.error(f"User ID does not exist: {user_id}")
            return jsonify({"error": "User ID does not exist"}), 404

        # Fetch the uid for the given user_id
        user_ref = db.reference(f"users/{user_id}")
        user_data = user_ref.get()
        if not user_data:
            return jsonify({"error": "User data not found"}), 404
        user_uid = user_data.get("uid")

        class_ref = db.reference(f"classes/{class_id}")
        class_data = class_ref.get()

        if not class_data:
            return jsonify({"error": "Class not found"}), 404

        users = class_data.get("users", [])
        if user_uid in users:
            return jsonify({"error": "User already in class"}), 400

        users.append(user_uid)
        class_ref.update({"users": users})

        logging.info(f"User added to class successfully: class_id={class_id}, user_id={user_id}")
        return jsonify({"message": "User added to class successfully", "class_id": class_id, "user_id": user_id}), 200
    except Exception as e:
        logging.exception(f"An error occurred while adding user to class: {str(e)}")
        return jsonify({"error": str(e)}), 500
########################################################################################################################
@app.route('/get_created_classes', methods=['GET'])
@token_required
@handle_errors
def get_created_classes(current_user, current_role):
    try:
        # Reference to the "classes" node in the Firebase Realtime Database
        database_ref = db.reference("classes")
        classes = database_ref.get()

        # Find the classes created by the current user
        created_classes = []
        for class_id, class_data in classes.items():
            if class_data.get("creator_uid") == current_user:
                created_classes.append({
                    "class_id": class_id,
                    "class_name": class_data.get("class_name")
                })

        return jsonify({"created_classes": created_classes}), 200
    except Exception as e:
        logging.exception(f"An error occurred while fetching created classes: {str(e)}")
        return jsonify({"error": str(e)}), 500
########################################################################################################################
@app.route('/get_class_details/<class_id>', methods=['GET'])
@token_required
@handle_errors
def get_class_details(class_id, current_user=None, current_role=None):
    try:
        # Reference to the specific class in the database
        class_ref = db.reference(f"classes/{class_id}")
        class_data = class_ref.get()

        if not class_data:
            return jsonify({"error": "Class not found"}), 404

        # Check if the current user is the creator of the class
        if class_data.get("creator_uid") != current_user:
            return jsonify({"error": "You do not have permission to view this class"}), 403

        class_details = {
            "class_id": class_id,
            "class_name": class_data.get("class_name"),
            "users": class_data.get("users", [])
        }
        print("Class details:", class_details)

        return jsonify({"class_details": class_details}), 200
    except Exception as e:
        logging.exception(f"An error occurred while fetching class details: {str(e)}")
        return jsonify({"error": str(e)}), 500

########################################################################################################################
@app.route('/attendance_records', methods=['POST'])
@token_required
@handle_errors
def get_attendance_records(current_user=None, current_role=None):
    try:
        # Get class_id from the form data
        class_id = request.form.get('class_id')

        if not class_id:
            return jsonify({"error": "class_id is required"}), 400

        # Reference to the specific class attendance records in the database
        attendance_ref = db.reference(f"attendance/{class_id}")
        attendance_data = attendance_ref.get()

        if not attendance_data:
            return jsonify({"attendance_records": []}), 200

        attendance_records = []
        for user_id, records in attendance_data.items():
            for record_id, record in records.items():
                attendance_records.append({
                    "user_id": user_id,
                    "record_id": record_id,
                    "timestamp": record.get("timestamp")
                })

        return jsonify({"attendance_records": attendance_records}), 200
    except Exception as e:
        logging.exception(f"An error occurred while fetching attendance records: {str(e)}")
        return jsonify({"error": str(e)}), 500
    
    
@app.route('/notify_attendance', methods=['POST'])
@token_required
@handle_errors
def notify_attendance(current_user, current_role):
    """
    Endpoint for notifying enrolled users in a class to mark attendance.

    Requires:
    - class_id: ID of the class for which attendance is being notified.
    """
    if 'class_id' not in request.form:
        return jsonify({"error": "Class ID is required"}), 400

    class_id = request.form['class_id']

    try:
        # Verify if the current user is the creator or has appropriate privileges for the class
        class_ref = db.reference(f"classes/{class_id}")
        class_data = class_ref.get()

        if not class_data:
            return jsonify({"error": "Class not found"}), 404

        users_in_class = class_data.get("users", [])

        if current_user != class_data.get("creator_uid") and current_user not in users_in_class:
            return jsonify({"error": "Unauthorized access to notify attendance"}), 403

        # Example logic to notify users (print for demonstration)
        notified_users = []
        for user_id in users_in_class:
            # Example: send notification via email, push notification, etc.
            # Here we are printing the user_id for demonstration purposes
            notified_users.append(user_id)
            print(f"Notifying user {user_id} for attendance in class {class_id}")

        return jsonify({"message": "Attendance notification sent successfully", "notified_users": notified_users}), 200

    except Exception as e:
        logging.exception(f"An error occurred while notifying attendance: {str(e)}")
        return jsonify({"error": str(e)}), 500
    
if __name__ == "__main__":
    app.run(debug=True)
