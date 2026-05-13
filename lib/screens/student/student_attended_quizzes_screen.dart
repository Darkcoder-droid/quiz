import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/royal_colors.dart';
import '../../widgets/royal_card.dart';
import 'quiz_result_review_screen.dart';

class StudentAttendedQuizzesScreen extends StatelessWidget {
  const StudentAttendedQuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Not logged in")));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attended Quizzes'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attempts')
            .where('studentUid', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final attempts = snapshot.data?.docs ?? [];
          
          // Clean up buggy attempts by grouping by quizId and taking only valid ones
          final Map<String, Map<String, dynamic>> validAttempts = {};
          for (var doc in attempts) {
            final d = doc.data() as Map<String, dynamic>;
            final quizId = d['quizId'];
            if (quizId == null || d['score'] == null || d['totalQuestions'] == null) continue;
            
            if (!validAttempts.containsKey(quizId)) {
              validAttempts[quizId] = d;
            } else {
              final currentAt = validAttempts[quizId]!['attemptedAt'] as Timestamp?;
              final newAt = d['attemptedAt'] as Timestamp?;
              if (newAt != null && (currentAt == null || newAt.toDate().isAfter(currentAt.toDate()))) {
                validAttempts[quizId] = d;
              }
            }
          }

          if (validAttempts.isEmpty) {
            return Center(
              child: Text(
                'No attended quizzes yet.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                    ),
              ),
            );
          }

          final validList = validAttempts.values.toList()
            ..sort((a, b) {
              final atA = (a['attemptedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              final atB = (b['attemptedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              return atB.compareTo(atA);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: validList.length,
            itemBuilder: (context, index) {
              final attempt = validList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RoyalCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizResultReviewScreen(
                          attemptData: attempt,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? RoyalColors.darkAccent.withOpacity(0.2) : RoyalColors.lightAccentLighter.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: isDark ? RoyalColors.darkAccent : RoyalColors.lightAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attempt['quizTitle'] ?? 'Unnamed Quiz',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Score: ${attempt['score']} / ${attempt['totalQuestions']}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                                  ),
                            ),
                            if (attempt['attemptedAt'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy - h:mm a').format((attempt['attemptedAt'] as Timestamp).toDate()),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                                      fontSize: 10,
                                    ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
