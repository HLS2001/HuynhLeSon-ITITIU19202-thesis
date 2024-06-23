import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker

import 'LoginPage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isFrontCamera = true;
  File? _image;
  final LocalAuthentication auth = LocalAuthentication();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        CameraDescription defaultCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras![0],
        );

        _cameraController =
            CameraController(defaultCamera, ResolutionPreset.medium);
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {});
        }
      } else {
        print('No available cameras found');
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile file = await _cameraController!.takePicture();
        setState(() {
          _image = File(file.path);
        });
      } catch (e) {
        print('Error taking picture: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras != null && _cameras!.isNotEmpty) {
      final CameraDescription newCamera = _isFrontCamera
          ? _cameras!.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back)
          : _cameras!.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front);

      try {
        await _cameraController!.dispose();
        _cameraController =
            CameraController(newCamera, ResolutionPreset.medium);
        await _cameraController!.initialize();
        setState(() {
          _isFrontCamera = !_isFrontCamera;
        });
      } catch (e) {
        print('Error switching camera: $e');
      }
    }
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

  Future<void> _register() async {
    if (_image == null) {
      _showErrorDialog('No image selected.');
      return;
    }

    if (nameController.text.isEmpty ||
        idController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      _showErrorDialog('Please fill in all the fields.');
      return;
    }

    bool fingerprintAuthenticated = await authenticate();
    if (!fingerprintAuthenticated) {
      _showErrorDialog('Fingerprint verification failed.');
      return;
    }

    var url = Uri.parse('https://46b0-171-235-43-47.ngrok-free.app/register');
    var request = http.MultipartRequest('POST', url);
    request.fields['name'] = nameController.text;
    request.fields['id'] = idController.text;
    request.fields['email'] = emailController.text;
    request.fields['password'] = passwordController.text;
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

    try {
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Registration successful');
        if (mounted) {
          _navigateToHomePage();
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(responseData.body);
        String errorMessage = data['error'] ?? 'Registration failed';
        if (errorMessage.contains('Face already registered')) {
          _showErrorDialog('Face already registered.');
        } else if (errorMessage.contains('Email is already registered')) {
          _showErrorDialog('Email is already registered.');
        } else {
          _showErrorDialog(errorMessage);
        }
      } else {
        _showErrorDialog('Registration error. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Exception during registration: $e');
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

  Future<void> _navigateToHomePage() async {
    if (mounted) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Page'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 450,
                child: _cameraController != null &&
                        _cameraController!.value.isInitialized
                    ? CameraPreview(_cameraController!)
                    : Container(
                        color: Colors.grey[200],
                        child:
                            const Center(child: Text('Camera not available')),
                      ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Picture'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage, // Add this line to handle image picking from gallery
                icon: const Icon(Icons.photo),
                label: const Text('Pick Image from Gallery'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              _image != null
                  ? Image.file(_image!, height: 200, width: 200)
                  : Container(
                      height: 200,
                      width: 200,
                      color: Colors.grey[300],
                      child: const Center(child: Text('No image selected')),
                    ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Register'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF8000FF), // Màu chữ trắng
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _switchCamera,
        child: const Icon(Icons.switch_camera),
      ),
    );
  }
}
