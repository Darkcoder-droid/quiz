import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import 'attempt_quiz_screen.dart';
import 'quiz_result_review_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'My Quizzes'
              : _currentIndex == 1
              ? 'Results'
              : 'Profile',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _buildCurrentTab(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz_rounded),
            label: 'Quizzes',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Results',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return const StudentQuizzesTab(key: ValueKey(0));
      case 1:
        return const StudentResultsTab(key: ValueKey(1));
      case 2:
        return const StudentProfileTab(key: ValueKey(2));
      default:
        return const SizedBox.shrink();
    }
  }
}

class StudentQuizzesTab extends StatefulWidget {
  const StudentQuizzesTab({super.key});

  @override
  State<StudentQuizzesTab> createState() => _StudentQuizzesTabState();
}

class _StudentQuizzesTabState extends State<StudentQuizzesTab> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData)
          return const Center(child: CircularProgressIndicator());
        if (!userSnap.data!.exists || userSnap.data!.data() == null) {
          return const Center(child: Text('Loading user data...'));
        }
        final userData = userSnap.data!.data() as Map<String, dynamic>;
        final classId = userData['classId'];

        if (classId == null)
          return const Center(child: Text('No class assigned'));

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('quizzes')
              .where('classId', isEqualTo: classId)
              .orderBy('scheduledAt', descending: false)
              .snapshots(),
          builder: (context, quizSnap) {
            if (!quizSnap.hasData)
              return const Center(child: CircularProgressIndicator());
            final now = DateTime.now();
            final quizzes = quizSnap.data!.docs;

            final active = <QueryDocumentSnapshot>[];
            final upcoming = <QueryDocumentSnapshot>[];

            for (var doc in quizzes) {
              final data = doc.data() as Map<String, dynamic>;
              final scheduledAt = (data['scheduledAt'] as Timestamp).toDate();
              final duration = Duration(minutes: data['duration'] ?? 0);
              final endTime = scheduledAt.add(duration);

              if (now.isAfter(scheduledAt) && now.isBefore(endTime)) {
                active.add(doc);
              } else if (scheduledAt.isAfter(now)) {
                upcoming.add(doc);
              }
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (active.isNotEmpty) ...[
                  _buildSectionHeader('Active Now'),
                  ...active.map((doc) => _buildQuizCard(context, doc, true)),
                  const SizedBox(height: 24),
                ],
                if (upcoming.isNotEmpty) ...[
                  _buildSectionHeader('Upcoming'),
                  ...upcoming.map((doc) => _buildQuizCard(context, doc, false)),
                ],
                if (active.isEmpty && upcoming.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100),
                        Icon(
                          Icons.event_busy_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active or upcoming quizzes',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildQuizCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    bool isActive,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final scheduledAt = (data['scheduledAt'] as Timestamp).toDate();
    final duration = Duration(minutes: data['duration'] ?? 0);
    final endTime = scheduledAt.add(duration);
    final now = DateTime.now();

    String timeInfo = '';
    if (isActive) {
      final diff = endTime.difference(now);
      timeInfo =
          'Ends in ${diff.inMinutes}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      final diff = scheduledAt.difference(now);
      if (diff.inHours > 24) {
        timeInfo =
            'Starts on ${DateFormat('MMM dd, hh:mm a').format(scheduledAt)}';
      } else {
        timeInfo =
            'Starts in ${diff.inHours}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (data['subjectName'] != null && data['subjectName'].toString().isNotEmpty)
                        Text(
                          data['subjectName'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.green : Colors.blue).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'LIVE' : 'WAIT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              timeInfo,
              style: TextStyle(
                color: isActive ? AppTheme.primaryColor : Colors.grey.shade600,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attempts')
                  .where('quizId', isEqualTo: doc.id)
                  .where(
                    'studentUid',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                  )
                  .snapshots(),
              builder: (context, attemptSnap) {
                bool alreadyAttempted =
                    attemptSnap.hasData && attemptSnap.data!.docs.isNotEmpty;

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isActive && !alreadyAttempted)
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttemptQuizScreen(
                                quizId: doc.id,
                                quizData: data,
                              ),
                            ),
                          )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alreadyAttempted
                          ? Colors.grey.shade200
                          : AppTheme.primaryColor,
                      foregroundColor: alreadyAttempted
                          ? Colors.grey.shade600
                          : Colors.white,
                    ),
                    child: Text(
                      alreadyAttempted
                          ? 'Attempted'
                          : isActive
                          ? 'Start Quiz'
                          : 'Soon',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class StudentResultsTab extends StatelessWidget {
  const StudentResultsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attempts')
          .where('studentUid', isEqualTo: user.uid)
          .orderBy('attemptedAt', descending: true)
          .snapshots(),
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
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No quiz attempts yet',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final score = data['score'] ?? 0;
            final total = data['totalQuestions'] ?? 0;
            final percentage = total > 0 ? (score / total * 100) : 0;
            final attemptedAt = (data['attemptedAt'] as Timestamp?)?.toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizResultReviewScreen(attemptData: data),
                    ),
                  );
                },
                title: Text(
                  data['quizTitle'] ?? 'Quiz',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['subjectName'] != null && data['subjectName'].toString().isNotEmpty)
                      Text(
                        data['subjectName'],
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    Text(
                      attemptedAt != null
                          ? DateFormat('MMM dd, yyyy').format(attemptedAt)
                          : '',
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score/$total',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: percentage >= 75
                            ? AppTheme.successColor
                            : percentage >= 40
                            ? AppTheme.warningColor
                            : AppTheme.errorColor,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey,
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

class StudentProfileTab extends StatelessWidget {
  const StudentProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.data!.exists || snapshot.data!.data() == null) {
          return const Center(child: Text('Loading profile...'));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'User';
        final email = data['email'] ?? '';
        final roll = data['rollNumber'] ?? 'N/A';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  name[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(email, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 40),
              _buildProfileItem(Icons.school, 'Roll Number', roll),
              const SizedBox(height: 12),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(data['classId'])
                    .get(),
                builder: (context, classSnap) {
                  String name = 'Loading...';
                  if (classSnap.hasData && classSnap.data!.exists) {
                    final cData =
                        classSnap.data!.data() as Map<String, dynamic>?;
                    name = cData?['className'] ?? cData?['name'] ?? 'N/A';
                  }
                  return _buildProfileItem(Icons.class_rounded, 'Class', name);
                },
              ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
