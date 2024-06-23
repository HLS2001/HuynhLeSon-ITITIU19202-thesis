import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../students/StudentHomePage.dart';
import '../teacher/TeacherHomePage.dart';
import 'RegisterPage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
  }

  Future<bool> authenticate() async {
    try {
      final isBiometricsAvailable = await auth.isDeviceSupported();
      if (!isBiometricsAvailable) {
        print('Biometrics not available');
        return false;
      }

      return await auth.authenticate(
        localizedReason: 'Quét vân tay để vào hòm bảo mật',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Input validation
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please fill in both email and password.');
      return;
    }

    if (!email.contains('@')) {
      _showErrorDialog('Invalid email format. Please include "@" in the email.');
      return;
    }

    bool authenticated = await authenticate();
    if (authenticated) {
      // Proceed with login logic
      final String apiUrl = 'https://46b0-171-235-43-47.ngrok-free.app/login';

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          body: {
            'email': email,
            'password': password,
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          String role = data['role'];
          String token = data['token'];

          await _storage.write(key: 'token', value: token);

          if (role == 'user') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentsHomePage(token: token),
              ),
            );
          } else if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TeacherHomePage(token: token),
              ),
            );
          }
        } else if (response.statusCode == 400 || response.statusCode == 401) {
          // Check the specific error message from the response
          final data = json.decode(response.body);
          String errorMessage = data['error'] ?? 'Incorrect email or password.';
          _showErrorDialog(errorMessage);
        } else {
          _showErrorDialog('An unknown error occurred. Please try again.');
        }
      } catch (e) {
        _showErrorDialog('An error occurred: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Logo or avatar image
                
                SizedBox(height: 30), // Space between image and input fields
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color.fromARGB(255, 253, 251, 251), // Input field background color
                  ),
                ),
                SizedBox(height: 10), // Space between input fields
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color.fromARGB(255, 253, 251, 251), // Input field background color
                  ),
                ),
                SizedBox(height: 20), // Space between input fields and login button
                ConstrainedBox(
                  constraints: BoxConstraints.tightFor(width: 200, height: 50),
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF8000FF), // White text color
                    ),
                    child: Text('Login'),
                  ),
                ),
                SizedBox(height: 10), // Space between login button and register button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    TextButton(
                      onPressed: _navigateToRegisterPage,
                      child: Text(
                        'SignUp!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
