import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'create_quiz_screen.dart';

class ClassDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot classDoc;

  const ClassDetailScreen({super.key, required this.classDoc});

  @override
  Widget build(BuildContext context) {
    final data = classDoc.data() as Map<String, dynamic>;
    final className = data['className'] ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    List<String> facultySubjects = [];
    if (uid != null && data['subjects'] != null) {
      for (var sub in data['subjects']) {
        final faculties = sub['faculties'] as List<dynamic>? ?? [];
        if (faculties.any((f) => f['uid'] == uid)) {
          facultySubjects.add(sub['name'] ?? 'Unnamed');
        }
      }
    }

    final usersRef = FirebaseFirestore.instance.collection('users');

    return Scaffold(
      appBar: AppBar(title: Text(className)),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef
            .where('role', isEqualTo: 'student')
            .where('classId', isEqualTo: classDoc.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No students enrolled yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final d = docs[index];
              final student = d.data() as Map<String, dynamic>;
              final fullName = student['fullName'] ?? student['name'] ?? '';
              final roll = student['rollNumber'] ?? '';
              final email = student['email'] ?? '';
              return Card(
                child: ListTile(
                  title: Text(fullName),
                  subtitle: Text('Roll: $roll\n$email'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (facultySubjects.isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are not assigned to any subjects in this class.')));
             return;
          }
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CreateQuizScreen(
              classId: classDoc.id,
              className: className,
              subjects: facultySubjects,
            ),
          ));
        },
        icon: const Icon(Icons.add),
        label: const Text('Schedule Quiz'),
      ),
    );
  }
}
