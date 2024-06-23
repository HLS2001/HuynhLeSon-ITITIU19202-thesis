import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../pages/LoginPage.dart';
import 'ClassOperations.dart';
import 'package:http/http.dart' as http;

class TeacherHomePage extends StatefulWidget {
  final String token;

  const TeacherHomePage({Key? key, required this.token}) : super(key: key);

  @override
  _TeacherHomePageState createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  final TextEditingController _classIdController = TextEditingController();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _classIdForStudentController = TextEditingController();
  final TextEditingController _attendanceClassIdController = TextEditingController();
  bool _showCreateClassForm = false;
  bool _showAddStudentForm = false;
  bool _showAttendanceRecordsForm = false;
  bool _showClassList = false;
  List<dynamic> classList = [];
  List<dynamic> attendanceRecords = [];
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  void _fetchClassData() async {
    final apiUrl = Uri.parse('https://46b0-171-235-43-47.ngrok-free.app/get_created_classes');

    try {
      var response = await http.get(
        apiUrl,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      var responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          classList = responseBody['created_classes'];
          _showClassList = true;
        });
      } else {
        print('Error fetching class list: ${responseBody['error']}');
      }
    } catch (e) {
      print('Exception fetching class list: $e');
    }
  }

  void _showCreateClass() {
    setState(() {
      _showCreateClassForm = true;
      _showAddStudentForm = false;
      _showAttendanceRecordsForm = false;
      _showClassList = false;
    });
  }

  void _showAddStudent() {
    setState(() {
      _showAddStudentForm = true;
      _showCreateClassForm = false;
      _showAttendanceRecordsForm = false;
      _showClassList = false;
    });
  }

  void _showAttendanceRecords() {
    setState(() {
      _showAttendanceRecordsForm = true;
      _showCreateClassForm = false;
      _showAddStudentForm = false;
      _showClassList = false;
    });
  }

  Future<void> _createClass() async {
    final result = await createClass(
      _classIdController.text,
      _classNameController.text,
      widget.token,
    );
    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Class created successfully!')),
      );
      _fetchClassData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create class.')),
      );
    }
  }

  Future<void> _addStudentToClass() async {
    final result = await addStudentToClass(
      _classIdForStudentController.text,
      _studentIdController.text,
      widget.token,
    );
    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student added successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add student.')),
      );
    }
  }

  Future<void> _fetchAttendanceRecords() async {
    List<dynamic>? result = await fetchAttendanceRecords(
      _attendanceClassIdController.text,
      widget.token,
    );

    if (result != null) {
      setState(() {
        attendanceRecords = result;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch attendance records.')),
      );
    }
  }
Future<void> _logout() async {
    await _storage.delete(key: 'token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),  
      (route) => false,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Home Page'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _showCreateClass,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF8000FF),
                  padding: EdgeInsets.all(12),
                ),
                child: Text(
                  'Create Class',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _showAddStudent,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF8000FF),
                  padding: EdgeInsets.all(12),
                ),
                child: Text(
                  'Add Student',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _showAttendanceRecords,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF8000FF),
                  padding: EdgeInsets.all(12),
                ),
                child: Text(
                  'Attendance Records',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _fetchClassData,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF8000FF),
                  padding: EdgeInsets.all(12),
                ),
                child: Text(
                  'Show Created Classes',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 20),
              if (_showCreateClassForm) ...[
                Text(
                  'Create a Class',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _classIdController,
                  decoration: InputDecoration(
                    labelText: 'Class ID',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _classNameController,
                  decoration: InputDecoration(
                    labelText: 'Class Name',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _createClass,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Create Class'),
                ),
              ],
              if (_showAddStudentForm) ...[
                Text(
                  'Add Student to Class',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _classIdForStudentController,
                  decoration: InputDecoration(
                    labelText: 'Class ID',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _studentIdController,
                  decoration: InputDecoration(
                    labelText: 'Student ID',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addStudentToClass,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Add Student to Class'),
                ),
              ],
              if (_showAttendanceRecordsForm) ...[
                Text(
                  'Get Attendance Records',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _attendanceClassIdController,
                  decoration: InputDecoration(
                    labelText: 'Class ID',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _fetchAttendanceRecords,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Get Attendance Records'),
                ),
              ],
              SizedBox(height: 20),
              if (_showClassList) ...[
                Text(
                  'Created Classes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Container(
                  height: 200,
                  child: ListView.builder(
                    itemCount: classList.length,
                    itemBuilder: (context, index) {
                      var item = classList[index];
                      if (item is Map<String, dynamic> && item.containsKey('class_name') && item.containsKey('class_id')) {
                        return Card(
                          child: ListTile(
                            title: Text(item['class_name']),
                            subtitle: Text(item['class_id']),
                          ),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ],
              SizedBox(height: 20),
              if (attendanceRecords.isNotEmpty) ...[
                Text(
                  'Attendance Records for Selected Class',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Container(
                  height: 200,
                  child: ListView.builder(
                    itemCount: attendanceRecords.length,
                    itemBuilder: (context, index) {
                      var record = attendanceRecords[index];
                      return Card(
                        child: ListTile(
                          title: Text('User ID: ${record['user_id']}'),
                          subtitle: Text('Timestamp: ${record['timestamp']}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
