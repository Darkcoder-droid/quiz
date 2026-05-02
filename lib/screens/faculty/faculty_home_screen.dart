import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import 'class_detail_screen.dart';
import 'quiz_results_screen.dart';

class FacultyHomeScreen extends StatefulWidget {
  const FacultyHomeScreen({super.key});

  @override
  State<FacultyHomeScreen> createState() => _FacultyHomeScreenState();
}

class _FacultyHomeScreenState extends State<FacultyHomeScreen> {
  int _currentIndex = 0;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [MyClassesTab(), QuizzesTab()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: 'My Classes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quizzes'),
        ],
      ),
    );
  }
}

class MyClassesTab extends StatelessWidget {
  MyClassesTab({super.key});

  final _classesRef = FirebaseFirestore.instance.collection('classes');
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not logged in'));

    return StreamBuilder<QuerySnapshot>(
      stream: _classesRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          
          // Check the new assignedFacultyUids array
          if (data['assignedFacultyUids'] != null) {
            final List<dynamic> uids = data['assignedFacultyUids'];
            if (uids.contains(uid)) return true;
          }
          
          // Legacy support
          if (data['assignedFacultyUid'] == uid) return true;
          if (data['assignedFaculty'] is Map) {
            return data['assignedFaculty']['id'] == uid;
          }
          return false;
        }).toList();
        if (docs.isEmpty)
          return const Center(child: Text('No classes assigned yet'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index];
            final data = d.data() as Map<String, dynamic>;
            final className = data['className'] ?? '';
            final section = data['section'] ?? '';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(className),
                subtitle: Text(section),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClassDetailScreen(classDoc: d),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class QuizzesTab extends StatelessWidget {
  QuizzesTab({super.key});

  final _quizzesRef = FirebaseFirestore.instance.collection('quizzes');
  final _auth = FirebaseAuth.instance;

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    final dt = ts.toDate();
    // e.g. Mar 11, 2026 at 3:00 PM
    final monthStr = _monthNames[dt.month];
    final hour12 = dt.hour == 0 || dt.hour == 12 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final minutePadded = dt.minute.toString().padLeft(2, '0');
    return '$monthStr ${dt.day}, ${dt.year} at $hour12:$minutePadded $ampm';
  }

  static const _monthNames = {
    1: 'Jan',
    2: 'Feb',
    3: 'Mar',
    4: 'Apr',
    5: 'May',
    6: 'Jun',
    7: 'Jul',
    8: 'Aug',
    9: 'Sep',
    10: 'Oct',
    11: 'Nov',
    12: 'Dec',
  };

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not logged in'));

    return StreamBuilder<QuerySnapshot>(
      stream: _quizzesRef.where('createdByUid', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return const Center(child: Text('No quizzes created yet'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index];
            final data = d.data() as Map<String, dynamic>;
            final title = data['title'] ?? '';
            final className = data['className'] ?? '';
            final subjectName = data['subjectName'];
            final section = data['section'] ?? '';
            final startTs = data['startDateTime'] as Timestamp?;
            final endTs = data['endDateTime'] as Timestamp?;
            
            String subtitle = 'Class: $className';
            if (section.isNotEmpty) subtitle += ' - Section $section';
            if (subjectName != null && subjectName.isNotEmpty) {
              subtitle += '\nSubject: $subjectName';
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                    const SizedBox(height: 2),
                    Text('Start: ${_formatDate(startTs)}'),
                    Text('End: ${_formatDate(endTs)}'),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          final questions = data['questions'] as List?;
                          final totalQuestions = questions?.length ?? 0;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuizResultsScreen(
                                quizId: d.id,
                                quizTitle: title,
                                subjectName: subjectName,
                                totalQuestions: totalQuestions,
                              ),
                            ),
                          );
                        },
                        child: const Text('View Results'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
