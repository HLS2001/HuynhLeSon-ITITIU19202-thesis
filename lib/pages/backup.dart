// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'ClassOperations.dart';
// import 'package:http/http.dart' as http;

// class TeacherHomePage extends StatefulWidget {
//   final String token;

//   const TeacherHomePage({Key? key, required this.token}) : super(key: key);

//   @override
//   _TeacherHomePageState createState() => _TeacherHomePageState();
// }

// class _TeacherHomePageState extends State<TeacherHomePage> {
//   final TextEditingController _classIdController = TextEditingController();
//   final TextEditingController _classNameController = TextEditingController();
//   final TextEditingController _studentIdController = TextEditingController();
//   final TextEditingController _classIdForStudentController =
//       TextEditingController();
//   bool _showCreateClassForm = false;
//   bool _showAddStudentForm = false;
//   List<dynamic> classList = [];
//   List<dynamic> studentList = [];

//   @override
//   void initState() {
//     super.initState();
//     // Fetch initial class data when the page loads
//     _fetchClassData();
//   }

//   void _fetchClassData() async {
//     final apiUrl = Uri.parse(
//         'https://301a-14-169-61-247.ngrok-free.app/get_created_classes');

//     try {
//       var response = await http.get(
//         apiUrl,
//         headers: {
//           'Authorization': 'Bearer ${widget.token}',
//         },
//       );
//       var responseBody = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         setState(() {
//           classList = responseBody['created_classes'];
//         });
//       } else {
//         print('Error fetching class list: ${responseBody['error']}');
//       }
//     } catch (e) {
//       print('Exception fetching class list: $e');
//     }
//   }

//   void _fetchStudentData(String classId) async {
//     final apiUrl = Uri.parse(
//         'https://301a-14-169-61-247.ngrok-free.app/get_class_details/$classId');

//     try {
//       var response = await http.get(
//         apiUrl,
//         headers: {
//           'Authorization': 'Bearer ${widget.token}',
//         },
//       );
//       var responseBody = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         setState(() {
//           studentList =
//               List<dynamic>.from(responseBody['class_details']['users']);
//         });
//       } else {
//         print('Error fetching student list: ${responseBody['error']}');
//       }
//     } catch (e) {
//       print('Exception fetching student list: $e');
//     }
//   }

//   void _showCreateClass() {
//     setState(() {
//       _showCreateClassForm = true;
//       _showAddStudentForm = false;
//     });
//   }

//   void _showAddStudent() {
//     setState(() {
//       _showAddStudentForm = true;
//       _showCreateClassForm = false;
//     });
//   }

//   Future<void> _createClass() async {
//     await createClass(
//       _classIdController.text,
//       _classNameController.text,
//       widget.token,
//     );
//     _fetchClassData();
//   }

//   Future<void> _addStudentToClass() async {
//     await addStudentToClass(
//       _classIdForStudentController.text,
//       _studentIdController.text,
//       widget.token,
//     );
//     _fetchStudentData(_classIdForStudentController.text);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Teacher Home Page'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               ElevatedButton(
//                 onPressed: _showCreateClass,
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   backgroundColor: Colors.blue,
//                   padding: EdgeInsets.all(12),
//                 ),
//                 child: Text(
//                   'Create Class',
//                   style: TextStyle(fontSize: 16),
//                 ),
//               ),
//               SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: _showAddStudent,
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   backgroundColor: Colors.blue,
//                   padding: EdgeInsets.all(12),
//                 ),
//                 child: Text(
//                   'Add Student',
//                   style: TextStyle(fontSize: 16),
//                 ),
//               ),
//               SizedBox(height: 20),
//               if (_showCreateClassForm) ...[
//                 Text(
//                   'Create a Class',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 10),
//                 TextField(
//                   controller: _classIdController,
//                   decoration: InputDecoration(
//                     labelText: 'Class ID',
//                     border: OutlineInputBorder(),
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 TextField(
//                   controller: _classNameController,
//                   decoration: InputDecoration(
//                     labelText: 'Class Name',
//                     border: OutlineInputBorder(),
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 ElevatedButton(
//                   onPressed: _createClass,
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.white,
//                     backgroundColor: Colors.green,
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                   ),
//                   child: Text('Create Class'),
//                 ),
//               ],
//               if (_showAddStudentForm) ...[
//                 Text(
//                   'Add Student to Class',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 10),
//                 TextField(
//                   controller: _classIdForStudentController,
//                   decoration: InputDecoration(
//                     labelText: 'Class ID',
//                     border: OutlineInputBorder(),
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 TextField(
//                   controller: _studentIdController,
//                   decoration: InputDecoration(
//                     labelText: 'Student ID',
//                     border: OutlineInputBorder(),
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 ElevatedButton(
//                   onPressed: _addStudentToClass,
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.white,
//                     backgroundColor: Colors.green,
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                   ),
//                   child: Text('Add Student to Class'),
//                 ),
//               ],
//               SizedBox(height: 20),
//               Text(
//                 'Created Classes',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 10),
//               Container(
//                 height: 200,
//                 child: ListView.builder(
//                   itemCount: classList.length,
//                   itemBuilder: (context, index) {
//                     var item = classList[index];
//                     // print('classList[$index]: $item');
//                     if (item is Map<String, dynamic> &&
//                         item.containsKey('class_name') &&
//                         item.containsKey('class_id')) {
//                       return Card(
//                         child: ListTile(
//                           title: Text(item['class_name']),
//                           subtitle: Text(item['class_id']),
//                           onTap: () {
//                             _fetchStudentData(item['class_id']);
                            
//                           },
//                         ),
//                       );
//                     } else {
//                       return SizedBox.shrink();
//                     }
//                   },
//                 ),
//               ),
//               SizedBox(height: 20),
//               if (studentList.isNotEmpty) ...[
//                 Text(
//                   'Students in Selected Class',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 10),
//                 Container(
//                   height: 200,
//                   child: ListView.builder(
//                     itemCount: studentList.length,
//                     itemBuilder: (context, index) {
//                       var student = studentList[index];
//                       print('studentList[$index]: $student');
//                       if (student is Map<String, dynamic> &&
//                           student.containsKey('name') &&
//                           student.containsKey('id')) {
//                         return Card(
//                           child: ListTile(
//                             title: Text(student['name']),
//                             subtitle: Text(student['id']),
//                           ),
//                         );
//                       } else {
//                         return SizedBox.shrink();
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
