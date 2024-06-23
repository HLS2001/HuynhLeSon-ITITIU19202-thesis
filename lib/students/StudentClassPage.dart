import 'package:flutter/material.dart';

class StudentClassPage extends StatefulWidget {
  final List<String> classes;

  const StudentClassPage({Key? key, required this.classes}) : super(key: key);

  @override
  _StudentClassPageState createState() => _StudentClassPageState();
}

class _StudentClassPageState extends State<StudentClassPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Classes'),
      ),
      body: ListView.builder(
        itemCount: widget.classes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(widget.classes[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckAttendancePage(className: widget.classes[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CheckAttendancePage extends StatelessWidget {
  final String className;

  const CheckAttendancePage({Key? key, required this.className}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance for $className'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Add logic to check attendance for this class
          },
          child: const Text('Check Attendance'),
        ),
      ),
    );
  }
}
