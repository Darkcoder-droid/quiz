import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';

class CreateQuizScreen extends StatefulWidget {
  final String classId;
  final String className;
  final List<String> subjects;

  const CreateQuizScreen({super.key, required this.classId, required this.className, required this.subjects});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class Question {
  String question = '';
  List<String> options = ['', '', '', ''];
  int correctAnswer = 0;

  Question({String? q, List<String>? opts, int? ans}) {
    if (q != null) question = q;
    if (opts != null) options = List.from(opts);
    if (ans != null) correctAnswer = ans;
  }

  Map<String, dynamic> toMap() => {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
  };
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '15');
  DateTime? _scheduledAt;
  final List<Question> _questions = [];
  bool _isPublishing = false;
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    if (widget.subjects.isNotEmpty) {
      _selectedSubject = widget.subjects.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 5)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _addOrEditQuestion({int? index}) {
    final isEditing = index != null;
    final initialQuestion = isEditing ? _questions[index] : Question();
    
    final qController = TextEditingController(text: initialQuestion.question);
    final optControllers = List.generate(4, (i) => TextEditingController(text: initialQuestion.options[i]));
    int selectedCorrect = initialQuestion.correctAnswer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: RadioGroup<int>(
              groupValue: selectedCorrect,
              onChanged: (v) => setModalState(() => selectedCorrect = v!),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEditing ? 'Edit Question' : 'Add Question',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: qController,
                    decoration: const InputDecoration(hintText: 'Enter question text'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: i,
                        ),
                      Expanded(
                        child: TextField(
                          controller: optControllers[i],
                          decoration: InputDecoration(hintText: 'Option ${String.fromCharCode(65 + i)}'),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (qController.text.isEmpty || optControllers.any((c) => c.text.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                      return;
                    }
                    setState(() {
                      final newQ = Question(
                        q: qController.text.trim(),
                        opts: optControllers.map((c) => c.text.trim()).toList(),
                        ans: selectedCorrect,
                      );
                      if (isEditing) {
                        _questions[index] = newQ;
                      } else {
                        _questions.add(newQ);
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _publishQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select schedule time')));
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one question')));
      return;
    }

    setState(() => _isPublishing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('quizzes').add({
        'title': _titleController.text.trim(),
        'classId': widget.classId,
        'className': widget.className,
        'subjectName': _selectedSubject,
        'scheduledAt': Timestamp.fromDate(_scheduledAt!),
        'duration': int.parse(_durationController.text),
        'createdByUid': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'questions': _questions.map((q) => q.toMap()).toList(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz published successfully!'), backgroundColor: AppTheme.successColor));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Quiz')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Class: ${widget.className}',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(hintText: 'Select Subject', prefixIcon: Icon(Icons.menu_book)),
                items: widget.subjects.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
                onChanged: (v) => setState(() => _selectedSubject = v),
                validator: (v) => v == null ? 'Select a subject' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Quiz Title', prefixIcon: Icon(Icons.title)),
                validator: (v) => v!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: _pickDateTime,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(_scheduledAt == null ? 'Schedule' : DateFormat('MMM dd, hh:mm a').format(_scheduledAt!)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Min', prefixIcon: Icon(Icons.timer_outlined)),
                      validator: (v) => v!.isEmpty ? 'Err' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Questions (${_questions.length})', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => _addOrEditQuestion(),
                    icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor, size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_questions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No questions added yet', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(_questions[index].question, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${_questions[index].options.length} options'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _addOrEditQuestion(index: index)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                            onPressed: () => setState(() => _questions.removeAt(index)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              _isPublishing
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _publishQuiz,
                      child: const Text('Publish Quiz'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
