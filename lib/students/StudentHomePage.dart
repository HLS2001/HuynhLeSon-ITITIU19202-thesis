import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../pages/AttendancePage.dart';
import '../pages/LoginPage.dart';

class StudentsHomePage extends StatefulWidget {
  final String token;

  const StudentsHomePage({Key? key, required this.token}) : super(key: key);

  @override
  _StudentsHomePageState createState() => _StudentsHomePageState();
}

class _StudentsHomePageState extends State<StudentsHomePage> {
  List<dynamic> _classes = [];
  bool _isLoading = true;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      // Handle error, e.g., navigate to login page
      return;
    }

    final response = await http.get(
      Uri.parse('https://46b0-171-235-43-47.ngrok-free.app/get_user_classes'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      setState(() {
        _classes = responseBody['user_classes'];
        _isLoading = false;
      });
    } else {
      print('Error fetching classes: ${response.statusCode}');
      print('Response Body: ${response.body}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToAttendancePage(String classId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendancePage(classId: classId, token: widget.token),
      ),
    );
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
        title: const Text('Your Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? const Center(child: Text('No classes available'))
              : ListView.builder(
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          _classes[index]['class_name'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Class ID: ${_classes[index]['class_id']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Theme.of(context).primaryColor,
                        ),
                        onTap: () => _navigateToAttendancePage(_classes[index]['class_id']),
                      ),
                    );
                  },
                ),
    );
  }
}
