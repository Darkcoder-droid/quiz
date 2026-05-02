import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  Color _scoreColor(int score) {
    if (totalQuestions == 0) return Colors.grey;
    final pct = score / totalQuestions;
    if (pct >= 0.7) return Colors.green;
    if (pct >= 0.4) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final attemptsRef = FirebaseFirestore.instance.collection('attempts');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quizTitle, style: const TextStyle(fontSize: 18)),
            if (subjectName != null && subjectName!.isNotEmpty)
              Text(
                subjectName!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
            return const Center(child: Text('No attempts yet'));
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
              'name': data['studentName'] ?? '',
              'score': score,
              'at': data['attemptedAt'] as Timestamp?,
            };
          }).toList();
          avgScore = total > 0 ? avgScore / total : 0;
          items.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Attempts', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('$total'),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Average', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(avgScore.toStringAsFixed(1)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Highest', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('$highest'),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final rec = items[index];
                    final name = rec['name'] as String;
                    final score = rec['score'] as int;
                    final at = rec['at'] as Timestamp?;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text(_formatDate(at)),
                        trailing: Text(
                          '$score / $totalQuestions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _scoreColor(score),
                          ),
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
}
