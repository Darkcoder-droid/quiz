import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/royal_colors.dart';

class QuizResultsScreen extends StatelessWidget {
  final String quizId;
  final String quizTitle;
  final String? subjectName;
  final int totalQuestions;

  const QuizResultsScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    this.subjectName,
    required this.totalQuestions,
  });

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    final dt = ts.toDate();
    final date = '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  Color _scoreColor(int score) {
    if (totalQuestions == 0) return Colors.grey;
    final pct = score / totalQuestions;
    if (pct >= 0.7) return RoyalColors.lightSuccess;
    if (pct >= 0.4) return const Color(0xFFE2C044); // Gold
    return RoyalColors.lightError;
  }

  @override
  Widget build(BuildContext context) {
    final attemptsRef = FirebaseFirestore.instance.collection('attempts');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? RoyalColors.darkBackground : RoyalColors.lightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quizTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (subjectName != null && subjectName!.isNotEmpty)
              Text(
                subjectName!,
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: attemptsRef.where('quizId', isEqualTo: quizId).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No attempts yet',
                style: TextStyle(color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary),
              ),
            );
          }

          int total = docs.length;
          double avgScore = 0;
          int highest = 0;
          final items = docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final score = (data['score'] ?? 0) as int;
            avgScore += score;
            if (score > highest) highest = score;
            return {
              'name': data['studentName'] ?? 'Unknown Student',
              'score': score,
              'at': data['attemptedAt'] as Timestamp?,
              'userAnswers': data['userAnswers'] as List<dynamic>?,
              'questions': data['questions'] as List<dynamic>?,
            };
          }).toList();
          
          avgScore = total > 0 ? avgScore / total : 0;
          items.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

          return Column(
            children: [
              // Statistics Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? RoyalColors.darkSurface : RoyalColors.lightSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Total Attempts', '$total', isDark),
                    _buildStatColumn('Average Score', avgScore.toStringAsFixed(1), isDark),
                    _buildStatColumn('Highest Score', '$highest', isDark),
                  ],
                ),
              ),
              
              // Results List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final rec = items[index];
                    final name = rec['name'] as String;
                    final score = rec['score'] as int;
                    final at = rec['at'] as Timestamp?;
                    final userAnswers = rec['userAnswers'] as List<dynamic>?;
                    final questions = rec['questions'] as List<dynamic>?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: isDark ? RoyalColors.darkSurfaceElevated : Colors.white,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            _formatDate(at),
                            style: TextStyle(fontSize: 12, color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _scoreColor(score).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$score / $totalQuestions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _scoreColor(score),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          children: [
                            if (questions == null || userAnswers == null)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text("Detailed answers unavailable for this attempt."),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black12 : const Color(0xFFF8F9FA),
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(questions.length, (qIndex) {
                                    final qData = questions[qIndex] as Map<String, dynamic>;
                                    final questionText = qData['question'] ?? 'Unknown Question';
                                    final options = qData['options'] as List<dynamic>;
                                    final correctIndex = qData['correctAnswer'] as int;
                                    
                                    final userAnsIndex = qIndex < userAnswers.length ? userAnswers[qIndex] : null;
                                    final bool isCorrect = userAnsIndex == correctIndex;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                isCorrect ? Icons.check_circle : Icons.cancel,
                                                color: isCorrect ? RoyalColors.lightSuccess : RoyalColors.lightError,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Q${qIndex + 1}. $questionText',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 28.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Student Answer: ${userAnsIndex != null ? options[userAnsIndex] : 'Skipped'}',
                                                  style: TextStyle(
                                                    color: isCorrect ? RoyalColors.lightSuccess : RoyalColors.lightError,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (!isCorrect)
                                                  Text(
                                                    'Correct Answer: ${options[correctIndex]}',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (qIndex < questions.length - 1)
                                            const Divider(height: 24),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, bool isDark) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
