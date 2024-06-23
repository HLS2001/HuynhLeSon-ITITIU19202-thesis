import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class location extends StatefulWidget {
  const location({super.key});

  @override
  _locationState createState() => _locationState();
}

class _locationState extends State<location> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Tracker'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Mark Attendance'),
          onPressed: () async {
            await _markAttendance();
          },
        ),
      ),
    );
  }

  Future<void> _markAttendance() async {
    // Check location permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      print('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition();

    // Post location to Firebase (example path, adjust as needed)
    await _firebaseFirestore.collection('attendance').add({
      'userId': 'exampleUserId', // Use actual user ID
      'timestamp': FieldValue.serverTimestamp(),
      'location': {'lat': position.latitude, 'lon': position.longitude}
    });

    print('Attendance marked with location: ${position.latitude}, ${position.longitude}');
  }
}
