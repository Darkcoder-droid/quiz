import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class QuizResultReviewScreen extends StatelessWidget {
  final Map<String, dynamic> attemptData;

  const QuizResultReviewScreen({super.key, required this.attemptData});

  @override
  Widget build(BuildContext context) {
    final questions = attemptData['questions'] as List<dynamic>? ?? [];
    final userAnswers = attemptData['userAnswers'] as List<dynamic>? ?? [];
    final score = attemptData['score'] ?? 0;
    final total = attemptData['totalQuestions'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Results')),
      body: Column(
        children: [
          _buildHeader(score, total),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                final userAnswer = userAnswers[index];
                final correctAnswer = question['correctAnswer'];
                final isCorrect = userAnswer == correctAnswer;

                return _buildQuestionReviewCard(
                  index,
                  question,
                  userAnswer,
                  correctAnswer,
                  isCorrect,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int score, int total) {
    final percentage = total > 0 ? (score / total * 100) : 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Text(
            attemptData['quizTitle'] ?? 'Quiz Results',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          if (attemptData['subjectName'] != null && attemptData['subjectName'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                attemptData['subjectName'],
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBadge(label: 'Score', value: '$score/$total'),
              const SizedBox(width: 24),
              _StatBadge(
                label: 'Grade',
                value: '${percentage.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewCard(
    int index,
    dynamic question,
    dynamic userAnswer,
    dynamic correctAnswer,
    bool isCorrect,
  ) {
    final options = question['options'] as List<dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isCorrect
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  child: Icon(
                    isCorrect ? Icons.check : Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Question ${index + 1}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question['question'],
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(options.length, (i) {
              bool isUserSelection = userAnswer == i;
              bool isCorrectOption = correctAnswer == i;

              Color bgColor = Colors.transparent;
              Color borderColor = Colors.grey.shade300;
              Widget? icon;

              if (isCorrectOption) {
                bgColor = AppTheme.successColor.withValues(alpha: 0.08);
                borderColor = AppTheme.successColor;
                icon = const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 20,
                );
              } else if (isUserSelection && !isCorrect) {
                bgColor = AppTheme.errorColor.withValues(alpha: 0.08);
                borderColor = AppTheme.errorColor;
                icon = const Icon(
                  Icons.cancel,
                  color: AppTheme.errorColor,
                  size: 20,
                );
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Text(
                      '${String.fromCharCode(65 + i)}.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCorrectOption
                            ? AppTheme.successColor
                            : isUserSelection
                            ? AppTheme.errorColor
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[i],
                        style: TextStyle(
                          color: isCorrectOption
                              ? AppTheme.successColor.withValues(alpha: 0.8)
                              : isUserSelection
                              ? AppTheme.errorColor.withValues(alpha: 0.8)
                              : Colors.black87,
                          fontWeight: (isCorrectOption || isUserSelection)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    ?icon,
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
