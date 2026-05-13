import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import 'class_detail_screen.dart';
import 'quiz_results_screen.dart';
import '../profile_tab.dart';
import '../../utils/royal_colors.dart';
import '../../widgets/royal_card.dart';
import '../../widgets/royal_button.dart';
import '../../main.dart' as import_main;
import 'create_quiz_screen.dart';

class FacultyHomeScreen extends StatefulWidget {
  const FacultyHomeScreen({super.key});

  @override
  State<FacultyHomeScreen> createState() => _FacultyHomeScreenState();
}

class _FacultyHomeScreenState extends State<FacultyHomeScreen> {
  int _currentIndex = 0;

  Future<void> _logout() async {
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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen(shouldSignOut: true)),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [MyClassesTab(), QuizzesTab(), const ScheduleTab(), const ProfileTab(role: 'Faculty')];

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? RoyalColors.darkBackground : RoyalColors.lightBackground,
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Faculty Dashboard' 
          : _currentIndex == 1 ? 'My Quizzes' 
          : _currentIndex == 2 ? 'Schedule' 
          : 'My Profile'
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
        child: tabs[_currentIndex],
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
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.class_outlined, Icons.class_rounded, 'Classes', isDark),
              _buildNavItem(1, Icons.quiz_outlined, Icons.quiz_rounded, 'Quizzes', isDark),
              _buildNavItem(2, Icons.calendar_today_outlined, Icons.calendar_today, 'Schedule', isDark),
              _buildNavItem(3, Icons.person_outline, Icons.person_rounded, 'Me', isDark),
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
}

class MyClassesTab extends StatelessWidget {
  MyClassesTab({super.key});

  final _classesRef = FirebaseFirestore.instance.collection('classes');
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not logged in'));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
        final userData = userSnap.data?.data() as Map<String, dynamic>?;
        final name = userData?['name'] ?? 'Faculty';
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Hi, $name!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isDark ? RoyalColors.darkAccent : RoyalColors.lightPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Classes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            
            // Notifications Section
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('quizzes').where('createdByUid', isEqualTo: uid).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                
                final now = DateTime.now();
                final soonQuizzes = snap.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final startTs = data['scheduledAt'] as Timestamp?;
                  if (startTs == null) return false;
                  final dt = startTs.toDate();
                  return dt.isAfter(now) && dt.difference(now).inHours <= 24;
                }).toList();

                if (soonQuizzes.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RoyalColors.lightAccent.withOpacity(isDark ? 0.2 : 0.1),
                      border: Border.all(color: RoyalColors.lightAccent),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active, color: RoyalColors.lightAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You have ${soonQuizzes.length} quiz(zes) starting within 24 hours!',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _classesRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Firebase Stream Error:\n${snapshot.error}', 
                          style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final allDocs = snapshot.data?.docs ?? [];
                  final docs = allDocs.where((d) {
                    try {
                      final data = d.data() as Map<String, dynamic>;
                      
                      // Check if faculty is assigned to any subject in this class
                      if (data['subjects'] != null && data['subjects'] is List) {
                        final subjects = data['subjects'] as List<dynamic>;
                        for (var sub in subjects) {
                          if (sub is Map && sub['faculties'] is List) {
                            final faculties = sub['faculties'] as List<dynamic>;
                            if (faculties.any((f) => f is Map && f['uid'] == uid)) {
                              return true;
                            }
                          }
                        }
                      }
                      
                      // Fallback to older schemas just in case
                      if (data['assignedFacultyUids'] != null && data['assignedFacultyUids'] is List) {
                        final uids = data['assignedFacultyUids'] as List<dynamic>;
                        if (uids.contains(uid)) return true;
                      }
                      if (data['assignedFacultyUid'] == uid) return true;
                      return false;
                    } catch (e) {
                      debugPrint('Error parsing class doc ${d.id}: $e');
                      return false;
                    }
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Debug: Fetched ${allDocs.length} total classes.\nNone matched your Faculty UID:\n$uid\n\nNo classes assigned yet.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final d = docs[index];
                      final data = d.data() as Map<String, dynamic>;
                      final className = data['className'] ?? '';
                      final section = data['section'] ?? '';

                      final cardWidget = Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDark ? RoyalColors.darkSurfaceElevated : RoyalColors.lightSurface,
                          borderRadius: BorderRadius.circular(32), // Pill shape
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withOpacity(0.5) : const Color(0xFF00236F).withOpacity(0.02),
                              blurRadius: 40,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ClassDetailScreen(classDoc: d)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        List<String> assignedSubs = [];
                                        bool isLegacy = false;
                                        if (data['subjects'] != null && data['subjects'] is List) {
                                          for (var sub in data['subjects']) {
                                            if (sub is Map && sub['faculties'] is List) {
                                              if (sub['faculties'].any((f) => f is Map && f['uid'] == uid)) {
                                                assignedSubs.add(sub['name'] ?? 'Unnamed');
                                              }
                                            }
                                          }
                                        }
                                        if (assignedSubs.isEmpty) isLegacy = true;

                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: RoyalColors.lightAccent.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isLegacy ? 'Legacy Assignment' : assignedSubs.join(', '),
                                            style: const TextStyle(
                                              color: RoyalColors.lightAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      }
                                    ),
                                    Icon(
                                      Icons.group_outlined,
                                      color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextPrimary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  className,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: isDark ? RoyalColors.darkTextPrimary : RoyalColors.lightPrimary, // Navy blue header
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  section.isNotEmpty ? 'Section $section' : 'No Section',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      return cardWidget;
                    },
                  );
                },
              ),
            ),
          ],
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
    final monthStr = _monthNames[dt.month];
    final hour12 = dt.hour == 0 || dt.hour == 12 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final minutePadded = dt.minute.toString().padLeft(2, '0');
    return '$monthStr ${dt.day}, ${dt.year} - $hour12:$minutePadded $ampm';
  }

  static const _monthNames = {1: 'Jan', 2: 'Feb', 3: 'Mar', 4: 'Apr', 5: 'May', 6: 'Jun', 7: 'Jul', 8: 'Aug', 9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dec'};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not logged in'));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), // push above nav bar
        child: FloatingActionButton.extended(
          onPressed: () {
            // Find classes they teach and allow them to pick one to create a quiz
            // For simplicity, just use a generic 'select class' flow or show a dialog.
            // The best way is to show a dialog of their classes.
            _showSelectClassDialog(context, uid);
          },
          icon: const Icon(Icons.add),
          label: const Text('Create Quiz'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _quizzesRef.where('createdByUid', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading quizzes'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No quizzes created yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                  ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final d = docs[index];
            final data = d.data() as Map<String, dynamic>;
            final title = data['title'] ?? '';
            final className = data['className'] ?? '';
            final subjectName = data['subjectName'];
            final section = data['section'] ?? '';
            final startTs = data['startDateTime'] as Timestamp?;

            final cardWidget = Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? RoyalColors.darkSurfaceElevated : RoyalColors.lightSurface,
                borderRadius: BorderRadius.circular(32), // Pill shape
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.5) : const Color(0xFF00236F).withOpacity(0.02),
                    blurRadius: 40,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: RoyalColors.lightAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            className.isNotEmpty ? className : 'No Class',
                            style: const TextStyle(
                              color: RoyalColors.lightAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.timer_outlined,
                          color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextPrimary,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: isDark ? RoyalColors.darkTextPrimary : RoyalColors.lightPrimary, // Navy blue header
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subjectName != null && subjectName.isNotEmpty ? subjectName : 'General Subject',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(startTs),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                                  ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
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
                          child: const Text(
                            'View Results →',
                            style: TextStyle(
                              color: RoyalColors.lightSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

            if (index == docs.length - 1) {
              return Column(
                children: [
                  cardWidget,
                  const SizedBox(height: 100), // padding for floating nav
                ],
              );
            }
            return cardWidget;
          },
        );
      },
    ),
    );
  }

  void _showSelectClassDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Class to Create Quiz'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final allDocs = snapshot.data!.docs;
                final myClasses = allDocs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  if (data['subjects'] != null && data['subjects'] is List) {
                    for (var sub in data['subjects']) {
                      if (sub is Map && sub['faculties'] is List) {
                        if ((sub['faculties'] as List).any((f) => f is Map && f['uid'] == uid)) {
                          return true;
                        }
                      }
                    }
                  }
                  return false;
                }).toList();

                if (myClasses.isEmpty) return const Text('No classes assigned to you yet.');

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: myClasses.length,
                  itemBuilder: (context, idx) {
                    final d = myClasses[idx];
                    final data = d.data() as Map<String, dynamic>;
                    
                    // Extract subjects for this faculty
                    List<String> facultySubjects = [];
                    for (var sub in data['subjects']) {
                      if ((sub['faculties'] as List).any((f) => f['uid'] == uid)) {
                        facultySubjects.add(sub['name'] ?? 'Unnamed');
                      }
                    }

                    return ListTile(
                      title: Text(data['className'] ?? 'Unknown Class'),
                      subtitle: Text('${facultySubjects.length} Subjects'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CreateQuizScreen(
                            classId: d.id,
                            className: data['className'] ?? 'Unknown Class',
                            subjects: facultySubjects,
                          ),
                        ));
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class ScheduleTab extends StatelessWidget {
  const ScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not logged in'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quizzes').where('createdByUid', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final now = DateTime.now();
        final upcomingQuizzes = snapshot.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final startTs = data['scheduledAt'] as Timestamp?;
          if (startTs == null) return false;
          return startTs.toDate().isAfter(now);
        }).toList();

        // Sort by soonest
        upcomingQuizzes.sort((a, b) {
          final aTs = (a.data() as Map<String, dynamic>)['scheduledAt'] as Timestamp;
          final bTs = (b.data() as Map<String, dynamic>)['scheduledAt'] as Timestamp;
          return aTs.toDate().compareTo(bTs.toDate());
        });

        if (upcomingQuizzes.isEmpty) {
          return Center(
            child: Text(
              'No upcoming quizzes scheduled.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                  ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: upcomingQuizzes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final data = upcomingQuizzes[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Quiz';
            final className = data['className'] ?? 'Class';
            final startTs = data['scheduledAt'] as Timestamp;
            final dt = startTs.toDate();
            
            final diff = dt.difference(now);
            String countdown;
            if (diff.inDays > 0) {
              countdown = 'In ${diff.inDays} days, ${diff.inHours % 24} hrs';
            } else if (diff.inHours > 0) {
              countdown = 'In ${diff.inHours} hrs, ${diff.inMinutes % 60} mins';
            } else {
              countdown = 'In ${diff.inMinutes} mins';
            }

            return RoyalCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$className\nStarts: ${dt.month}/${dt.day} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: RoyalColors.lightPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    countdown,
                    style: const TextStyle(color: RoyalColors.lightPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
