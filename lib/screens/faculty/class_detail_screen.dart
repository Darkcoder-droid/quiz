import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/royal_colors.dart';
import '../../widgets/royal_card.dart';

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
            .where('role', isEqualTo: 'Student')
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
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index];
              final student = d.data() as Map<String, dynamic>;
              final fullName = student['fullName'] ?? student['name'] ?? '';
              final roll = student['rollNumber'] ?? 'No Roll #';
              final email = student['email'] ?? '';
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RoyalCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? RoyalColors.darkAccent.withOpacity(0.2) : RoyalColors.lightAccentLighter.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: isDark ? RoyalColors.darkAccent : RoyalColors.lightAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Roll: $roll',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
