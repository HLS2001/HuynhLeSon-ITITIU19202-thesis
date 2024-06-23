import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> createClass(String classId, String className, String token) async {
  final apiUrl = Uri.parse('https://46b0-171-235-43-47.ngrok-free.app/create_class');

  try {
    var response = await http.post(
      apiUrl,
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        'class_id': classId,
        'class_name': className,
      },
    );

    var responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      print('Class created successfully: ${responseBody['class_id']}');
      return true;
    } else {
      print('Error: ${responseBody['error']}');
      return false;
    }
  } catch (e) {
    print('Exception during class creation: $e');
    return false;
  }
}

Future<bool> addStudentToClass(String classId, String userId, String token) async {
  final apiUrl = Uri.parse('https://46b0-171-235-43-47.ngrok-free.app/add_user_to_class');

  try {
    var response = await http.post(
      apiUrl,
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        'class_id': classId,
        'user_id': userId,
      },
    );

    var responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      print('Student added successfully: ${responseBody['user_id']}');
      return true;
    } else {
      print('Error: ${responseBody['error']}');
      return false;
    }
  } catch (e) {
    print('Exception during adding student: $e');
    return false;
  }
}

Future<List<dynamic>?> fetchAttendanceRecords(String classId, String token) async {
  final apiUrl = Uri.parse('https://46b0-171-235-43-47.ngrok-free.app/attendance_records');

  try {
    var response = await http.post(
      apiUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'class_id': classId,
      },
    );

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      List<dynamic> attendanceRecords = responseBody['attendance_records'];
      print('Attendance records: $attendanceRecords');
      return attendanceRecords;
    } else {
      var responseBody = jsonDecode(response.body);
      print('Error fetching attendance records: ${responseBody['error']}');
      return null;
    }
  } catch (e) {
    print('Exception fetching attendance records: $e');
    return null;
  }
}

Future<void> fetchClassData(String token) async {
  final apiUrl = Uri.parse('https://46b0-171-235-43-47.ngrok-free.app/get_created_classes');

  try {
    var response = await http.get(
      apiUrl,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      List<dynamic> classes = responseBody['created_classes'];
      print('Updated class list: $classes');
      // Handle data, update UI, etc.
    } else {
      print('Error fetching class list: ${responseBody['error']}');
    }
  } catch (e) {
    print('Exception fetching class list: $e');
  }
}

Future<void> fetchStudentData(String classId, String token) async {
  final apiUrl = Uri.parse('https://46b0-171-235-43-47.ngrok-free.app/get_class_details/$classId');

  try {
    var response = await http.get(
      apiUrl,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      List<dynamic> users = responseBody['class_details']['users'];
      print('Updated student list in class $classId: $users');
      // Handle data, update UI, etc.
    } else {
      print('Error fetching student list: ${responseBody['error']}');
    }
  } catch (e) {
    print('Exception fetching student list: $e');
  }
}
