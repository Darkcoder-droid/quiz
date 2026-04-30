import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class AttemptQuizScreen extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> quizData;

  const AttemptQuizScreen({super.key, required this.quizId, required this.quizData});

  @override
  State<AttemptQuizScreen> createState() => _AttemptQuizScreenState();
}

class _AttemptQuizScreenState extends State<AttemptQuizScreen> {
  late PageController _pageController;
  late List<dynamic> _questions;
  late List<int?> _userAnswers;
  late int _secondsRemaining;
  Timer? _timer;
  int _currentPage = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _questions = widget.quizData['questions'] ?? [];
    _userAnswers = List<int?>.filled(_questions.length, null);
    
    // Calculate remaining time based on scheduledAt + duration
    final scheduledAt = (widget.quizData['scheduledAt'] as Timestamp).toDate();
    final duration = Duration(minutes: widget.quizData['duration'] ?? 0);
    final endTime = scheduledAt.add(duration);
    final now = DateTime.now();
    _secondsRemaining = endTime.difference(now).inSeconds;

    if (_secondsRemaining > 0) {
      _startTimer();
    } else {
      // If time already up, auto submit (though shouldn't happen if UI logic is correct)
      WidgetsBinding.instance.addPostFrameCallback((_) => _submitQuiz());
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _submitQuiz();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i]['correctAnswer']) {
        score++;
      }
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      final userData = userDoc.data();

      await FirebaseFirestore.instance.collection('attempts').add({
        'quizId': widget.quizId,
        'quizTitle': widget.quizData['title'],
        'subjectName': widget.quizData['subjectName'],
        'studentUid': user?.uid,
        'studentName': userData?['name'] ?? 'Unknown',
        'score': score,
        'totalQuestions': _questions.length,
        'attemptedAt': FieldValue.serverTimestamp(),
        'questions': _questions, // Store questions snapshot for review
        'userAnswers': _userAnswers,
      });

      if (mounted) {
        _showScoreDialog(score, _questions.length);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showScoreDialog(int score, int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 60, color: Colors.orange),
            const SizedBox(height: 16),
            Text('You scored $score out of $total', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit quiz screen
            },
            child: const Text('View Results'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prevent going back
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.quizData['title'] ?? 'Quiz', style: const TextStyle(fontSize: 18)),
              if (widget.quizData['subjectName'] != null && widget.quizData['subjectName'].toString().isNotEmpty)
                Text(
                  widget.quizData['subjectName'],
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _secondsRemaining < 60 ? AppTheme.errorColor.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: _secondsRemaining < 60 ? AppTheme.errorColor : AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: _secondsRemaining < 60 ? AppTheme.errorColor : AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / _questions.length,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (v) => setState(() => _currentPage = v),
                      itemCount: _questions.length,
                      itemBuilder: (context, qIndex) {
                        final question = _questions[qIndex];
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Question ${qIndex + 1} of ${_questions.length}',
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                question['question'],
                                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 32),
                              ...List.generate((question['options'] as List).length, (oIndex) {
                                final optionText = question['options'][oIndex];
                                final isSelected = _userAnswers[qIndex] == oIndex;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: InkWell(
                                    onTap: () => setState(() => _userAnswers[qIndex] = oIndex),
                                    borderRadius: BorderRadius.circular(16),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.05) : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                                            ),
                                            child: Center(
                                              child: Text(
                                                String.fromCharCode(65 + oIndex),
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              optionText,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                color: isSelected ? AppTheme.primaryColor : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter() {
    bool isLast = _currentPage == _questions.length - 1;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            OutlinedButton(
              onPressed: () {
                _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              },
              child: const Text('Previous'),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: () {
              if (isLast) {
                _showSubmitConfirmation();
              } else {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 56)),
            child: Text(isLast ? 'Finish' : 'Next'),
          ),
        ],
      ),
    );
  }

  void _showSubmitConfirmation() {
    int answered = _userAnswers.where((a) => a != null).length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Quiz?'),
        content: Text('You have answered $answered out of ${_questions.length} questions. Are you sure you want to submit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            Navigator.pop(context);
            _submitQuiz();
          }, child: const Text('Submit')),
        ],
      ),
    );
  }
}

