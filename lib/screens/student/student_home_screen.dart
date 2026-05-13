import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animations/animations.dart';
import '../../utils/royal_colors.dart';
import '../../widgets/royal_card.dart';
import '../../widgets/royal_button.dart';
import '../profile_tab.dart';
import 'attempt_quiz_screen.dart';
import 'quiz_result_review_screen.dart';
import '../auth/login_screen.dart';
import '../../main.dart' as import_main;
import 'student_attended_quizzes_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      const StudentQuizzesTab(key: ValueKey(0)),
      const ProfileTab(key: ValueKey(1), role: 'Student'),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? RoyalColors.darkBackground : RoyalColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Icon(Icons.share, color: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary),
            const SizedBox(width: 8),
            Text(
              'Astra',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) async {
              if (value == 'theme') {
                import_main.themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'theme',
                child: ListTile(
                  leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  title: Text(isDark ? 'Light Mode' : 'Dark Mode'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: RoyalColors.lightError),
                  title: Text('Sign Out', style: TextStyle(color: RoyalColors.lightError)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: tabs[_currentIndex],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? RoyalColors.darkSurface : RoyalColors.lightSurface,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.5) : const Color(0xFF00236F).withOpacity(0.02),
              blurRadius: 40,
              offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.quiz_outlined, Icons.quiz_rounded, 'Quizzes', isDark),
              _buildNavItem(1, Icons.person_outline, Icons.person_rounded, 'Me', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final primaryColor = isDark ? RoyalColors.darkAccent : RoyalColors.lightPrimary;
    final defaultColor = isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? (isDark ? RoyalColors.darkBackground : Colors.white) : defaultColor,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected ? (isDark ? RoyalColors.darkBackground : Colors.white) : defaultColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 1.0,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: RoyalColors.lightError),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen(shouldSignOut: true)), (route) => false);
      }
    }
  }
}

class StudentQuizzesTab extends StatelessWidget {
  const StudentQuizzesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Not logged in"));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
        
        final studentData = userSnap.data?.data() as Map<String, dynamic>?;
        final studentName = studentData?['name'] ?? 'Student';
        final studentClassId = studentData?['classId'];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('attempts').where('studentUid', isEqualTo: user.uid).snapshots(),
          builder: (context, attemptSnap) {
            if (!attemptSnap.hasData) return const Center(child: CircularProgressIndicator());
            
            final attempts = attemptSnap.data!.docs;
            // Clean up buggy attempts by grouping by quizId and taking only valid ones
            final Map<String, Map<String, dynamic>> validAttempts = {};
            for (var doc in attempts) {
              final d = doc.data() as Map<String, dynamic>;
              final quizId = d['quizId'];
              // If it's missing essential fields, skip it
              if (quizId == null || d['score'] == null || d['totalQuestions'] == null) continue;
              
              if (!validAttempts.containsKey(quizId)) {
                validAttempts[quizId] = d;
              } else {
                // If multiple, keep the one with the latest attemptedAt
                final currentAt = validAttempts[quizId]!['attemptedAt'] as Timestamp?;
                final newAt = d['attemptedAt'] as Timestamp?;
                if (newAt != null && (currentAt == null || newAt.toDate().isAfter(currentAt.toDate()))) {
                  validAttempts[quizId] = d;
                }
              }
            }
            final attemptedQuizIds = validAttempts.keys.toSet();

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
              builder: (context, quizSnap) {
                if (!quizSnap.hasData) return const Center(child: CircularProgressIndicator());
                
                final allQuizzes = quizSnap.data!.docs;
                final liveQuizzes = allQuizzes.where((d) {
                  final quizData = d.data() as Map<String, dynamic>;
                  // Filter out quizzes already attempted
                  if (attemptedQuizIds.contains(d.id)) return false;
                  // If student belongs to a class, only show quizzes for that class
                  if (studentClassId != null && studentClassId.toString().isNotEmpty) {
                    if (quizData['classId'] != studentClassId) return false;
                  }
                  
                  // Filter out quizzes with 0 questions (or missing questions)
                  final totalQuestions = (quizData['questions'] as List?)?.length ?? quizData['totalQuestions'] ?? 0;
                  if (totalQuestions == 0) return false;

                  return true;
                }).toList();
                
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Hi, $studentName!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: isDark ? RoyalColors.darkAccent : RoyalColors.lightPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to explore new ranks and master your modules today?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                          ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Live Quizzes Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Quizzes',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentAttendedQuizzesScreen()));
                          },
                          child: const Row(
                            children: [
                              Text('View All', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (liveQuizzes.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'No live quizzes available.',
                            style: TextStyle(color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary),
                          ),
                        ),
                      )
                    else
                      ...liveQuizzes.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? 'Quiz';
                        final subject = data['subjectName'] ?? 'General';
                        final totalQuestions = data['totalQuestions'] ?? 0;
                        final duration = data['durationMinutes'] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: RoyalCard(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => AttemptQuizScreen(quizId: doc.id, quizData: data),
                              ));
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isDark ? RoyalColors.darkSecondary : RoyalColors.lightSecondary).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        subject,
                                        style: TextStyle(
                                          color: isDark ? RoyalColors.darkSecondary : RoyalColors.lightSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(Icons.format_list_numbered, size: 16, color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary),
                                    const SizedBox(width: 4),
                                    Text('$totalQuestions Questions', style: Theme.of(context).textTheme.bodySmall),
                                    const SizedBox(width: 16),
                                    Icon(Icons.timer_outlined, size: 16, color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary),
                                    const SizedBox(width: 4),
                                    Text('$duration mins', style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: RoyalButton(
                                    text: 'Start Quiz',
                                    onPressed: () {
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => AttemptQuizScreen(quizId: doc.id, quizData: data),
                                      ));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    
                    const SizedBox(height: 32),

                    // Attempted Results Section
                    Text(
                      'Attempted Results',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (validAttempts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'You haven\'t attempted any quizzes yet.',
                            style: TextStyle(color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary),
                          ),
                        ),
                      )
                    else
                      ...validAttempts.entries.map((entry) {
                        final attemptData = entry.value;
                        final score = attemptData['score'] ?? 0;
                        final total = attemptData['totalQuestions'] ?? 1;
                        
                        // Check if the original quiz actually exists in the allQuizzes list
                        final originalQuiz = allQuizzes.where((q) => q.id == entry.key).firstOrNull;
                        if (originalQuiz == null) return const SizedBox.shrink(); // Hide if quiz was deleted

                        final quizData = originalQuiz.data() as Map<String, dynamic>;
                        final title = quizData['title'] ?? 'Quiz';
                        final subject = quizData['subjectName'] ?? 'General';
                        
                        final pct = score / total;
                        final scoreColor = pct >= 0.7 
                          ? RoyalColors.lightSuccess 
                          : pct >= 0.4 ? const Color(0xFFE2C044) : RoyalColors.lightError;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: RoyalCard(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => QuizResultReviewScreen(
                                  attemptData: attemptData,
                                ),
                              ));
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subject,
                                        style: TextStyle(
                                          color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: scoreColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '$score / $total',
                                    style: TextStyle(
                                      color: scoreColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 100), // padding for floating nav
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
