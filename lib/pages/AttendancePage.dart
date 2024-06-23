import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../students/StudentHomePage.dart';

class AttendancePage extends StatefulWidget {
  final String classId;
  final String token;  // Accepting token from the previous page

  const AttendancePage({Key? key, required this.classId, required this.token}) : super(key: key);

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _navigateToHomePage() async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => StudentsHomePage(token: widget.token)),
    );
  }

  Future<void> _submitAttendance(File imageFile) async {
    final apiUrl =
        Uri.parse('https://46b0-171-235-43-47.ngrok-free.app/attendance');

    try {
      setState(() {
        _isLoading = true;
      });

      var request = http.MultipartRequest('POST', apiUrl);
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.fields['class_id'] = widget.classId;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        print('Attendance recorded successfully');
        await _navigateToHomePage();
      } else {
        var responseBody = await http.Response.fromStream(response);
        print('Error during attendance check. Status code: ${response.statusCode}');
        print('Response body: ${responseBody.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${jsonDecode(responseBody.body)['error']}')),
        );
      }
    } catch (e) {
      print('Exception during attendance check: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Page'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _image != null 
                  ? Container(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                        maxWidth: double.infinity,
                      ),
                      child: Image.file(_image!),
                    ) 
                  : Container(),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: const Text('Take Picture'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: const Text('Pick Image from Gallery'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _image == null
                      ? null
                      : () async {
                          await _submitAttendance(_image!);
                        },
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : const Text('Submit Attendance'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
