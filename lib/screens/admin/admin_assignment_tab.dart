import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../utils/royal_colors.dart';
import '../../widgets/royal_button.dart';

class AdminAssignmentTab extends StatefulWidget {
  const AdminAssignmentTab({super.key});

  @override
  State<AdminAssignmentTab> createState() => _AdminAssignmentTabState();
}

class _AdminAssignmentTabState extends State<AdminAssignmentTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Account Creation
  final _accountFormKey = GlobalKey<FormState>();
  String _accName = '';
  String _accEmail = '';
  String _accPassword = '';
  String _accRole = 'Faculty';
  String? _selectedClassId;
  String? _selectedClassName;
  bool _isCreatingAccount = false;

  // Class Creation
  final _classFormKey = GlobalKey<FormState>();
  String _className = '';
  bool _isCreatingClass = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TabBar(
          controller: _tabController,
          labelColor: isDark ? RoyalColors.darkAccent : RoyalColors.lightPrimary,
          unselectedLabelColor: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
          indicatorColor: isDark ? RoyalColors.darkAccent : RoyalColors.lightPrimary,
          tabs: const [
            Tab(text: 'Accounts'),
            Tab(text: 'Classes'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAccountsTab(isDark),
          _buildClassesTab(isDark),
          _buildManageUsersTab(isDark),
        ],
      ),
    );
  }

  Widget _buildAccountsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _accountFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create User Account', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              onSaved: (val) => _accName = val?.trim() ?? '',
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              onSaved: (val) => _accEmail = val?.trim() ?? '',
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              obscureText: true,
              onSaved: (val) => _accPassword = val?.trim() ?? '',
              validator: (val) => val == null || val.length < 6 ? 'Min 6 chars' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _accRole,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: ['Faculty', 'Student'].map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (val) => setState(() {
                _accRole = val!;
                if (val == 'Faculty') {
                  _selectedClassId = null;
                  _selectedClassName = null;
                }
              }),
            ),
            if (_accRole == 'Student') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? RoyalColors.darkSurfaceElevated : RoyalColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? RoyalColors.darkAccent : RoyalColors.lightPrimary,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.class_outlined,
                          color: isDark ? RoyalColors.darkAccent : RoyalColors.lightPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Assign Class',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? RoyalColors.darkAccent : RoyalColors.lightPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final classes = snapshot.data!.docs;
                        if (classes.isEmpty) {
                          return Text(
                            'No classes available. Create a class first.',
                            style: TextStyle(
                              color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                            ),
                          );
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedClassId,
                          decoration: const InputDecoration(
                            labelText: 'Select Class',
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Choose a class'),
                          items: classes.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(data['className'] ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final selectedDoc = classes.firstWhere((doc) => doc.id == val);
                              final classData = selectedDoc.data() as Map<String, dynamic>;
                              setState(() {
                                _selectedClassId = val;
                                _selectedClassName = classData['className'];
                              });
                            }
                          },
                        );
                      },
                    ),
                    if (_selectedClassName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Will be assigned to: $_selectedClassName',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            _isCreatingAccount
                ? const Center(child: CircularProgressIndicator())
                : RoyalButton(text: 'Create Account', onPressed: _createAccount),
          ],
        ),
      ),
    );
  }

  Future<void> _createAccount() async {
    if (!_accountFormKey.currentState!.validate()) return;
    _accountFormKey.currentState!.save();

    setState(() => _isCreatingAccount = true);
    FirebaseApp? secondaryApp;
    try {
      String rollNumber = '';
      final String yearPrefix = (DateTime.now().year % 100).toString();
      final String rolePrefix = _accRole == 'Student' ? '${yearPrefix}SUUBEADS' : '${yearPrefix}FACADS';

      // Query to find the latest user with this prefix
      final QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('rollNumber', isGreaterThanOrEqualTo: rolePrefix)
          .where('rollNumber', isLessThan: '$rolePrefix\\uf8ff')
          .orderBy('rollNumber', descending: true)
          .limit(1)
          .get();

      int nextIndex = 1;
      if (query.docs.isNotEmpty) {
        final lastRoll = query.docs.first['rollNumber'] as String?;
        if (lastRoll != null && lastRoll.startsWith(rolePrefix)) {
          final indexStr = lastRoll.substring(rolePrefix.length);
          final lastIndex = int.tryParse(indexStr);
          if (lastIndex != null) {
            nextIndex = lastIndex + 1;
          }
        }
      }
      rollNumber = '$rolePrefix${nextIndex.toString().padLeft(3, '0')}';

      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
      UserCredential userCred = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: _accEmail, password: _accPassword);

      final userData = {
        'email': _accEmail,
        'name': _accName,
        'fullName': _accName,
        'role': _accRole,
        'rollNumber': rollNumber,
        'isApproved': true,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (_accRole == 'Student' && _selectedClassId != null) {
        userData['classId'] = _selectedClassId!;
        userData['className'] = _selectedClassName!;
      }
      await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created successfully')));
      _accountFormKey.currentState!.reset();
      setState(() {
        _selectedClassId = null;
        _selectedClassName = null;
        _accRole = 'Faculty';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
      setState(() => _isCreatingAccount = false);
    }
  }

  Widget _buildClassesTab(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _classFormKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Class Name (e.g. 10A)', border: OutlineInputBorder()),
                    onSaved: (val) => _className = val?.trim() ?? '',
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                _isCreatingClass
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _createClass,
                        child: const Text('Create Class'),
                      ),
              ],
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('classes').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('No classes found.'));
              
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['className'] ?? 'Unknown';
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? RoyalColors.darkSurfaceElevated : RoyalColors.lightSurface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ClassManagementScreen(classDoc: doc),
                        ));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: RoyalColors.lightAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: RoyalColors.lightAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .where('role', isEqualTo: 'Student')
                                    .where('classId', isEqualTo: doc.id)
                                    .snapshots(),
                                builder: (context, studentSnap) {
                                  if (!studentSnap.hasData) return const Text('Loading students...');
                                  return Text(
                                    '${studentSnap.data!.docs.length} Students Enrolled',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                                        ),
                                  );
                                },
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _createClass() async {
    if (!_classFormKey.currentState!.validate()) return;
    _classFormKey.currentState!.save();
    
    setState(() => _isCreatingClass = true);
    try {
      await FirebaseFirestore.instance.collection('classes').add({
        'className': _className,
        'subjects': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class created successfully')));
      _classFormKey.currentState!.reset();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isCreatingClass = false);
    }
  }
  Widget _buildManageUsersTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No users found.'));

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? data['fullName'] ?? 'Unknown';
            final role = data['role'] ?? 'Unknown';
            final rollNumber = data['rollNumber'] ?? 'No Roll #';
            final classId = data['classId'] ?? 'No Class';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? RoyalColors.darkSurfaceElevated : RoyalColors.lightSurface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Role: $role | Roll: $rollNumber\\nClass: $classId'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: RoyalColors.lightPrimary),
                  onPressed: () => _showEditUserDialog(doc.id, data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditUserDialog(String userId, Map<String, dynamic> userData) {
    final rollCtrl = TextEditingController(text: userData['rollNumber'] ?? '');
    final classCtrl = TextEditingController(text: userData['classId'] ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rollCtrl,
                decoration: const InputDecoration(labelText: 'Roll Number'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: classCtrl,
                decoration: const InputDecoration(labelText: 'Class ID'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'rollNumber': rollCtrl.text.trim(),
                  'classId': classCtrl.text.trim(),
                });
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully')));
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}


class ClassManagementScreen extends StatefulWidget {
  final QueryDocumentSnapshot classDoc;
  const ClassManagementScreen({super.key, required this.classDoc});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final _subjectNameCtrl = TextEditingController();

  Future<void> _addSubject() async {
    final name = _subjectNameCtrl.text.trim();
    if (name.isEmpty) return;

    final data = widget.classDoc.data() as Map<String, dynamic>;
    final subjects = List<dynamic>.from(data['subjects'] ?? []);
    
    // Check if exists
    if (subjects.any((s) => s is Map && s['name'] == name)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject already exists')));
      return;
    }

    subjects.add({
      'name': name,
      'faculties': [], // List of { uid, name }
    });

    await widget.classDoc.reference.update({'subjects': subjects});
    _subjectNameCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.classDoc['className']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final ctrl = TextEditingController(text: widget.classDoc['className']);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Edit Class Name'),
                  content: TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(labelText: 'Class Name'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        if (ctrl.text.trim().isNotEmpty) {
                          widget.classDoc.reference.update({'className': ctrl.text.trim()});
                          Navigator.pop(context);
                          setState(() {}); // refresh app bar
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.black, // Depending on theme, adjust this if needed
              tabs: [
                Tab(text: 'Subjects & Faculty'),
                Tab(text: 'Students'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Subjects
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _subjectNameCtrl,
                                decoration: const InputDecoration(labelText: 'New Subject Name', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(onPressed: _addSubject, child: const Text('Add')),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: widget.classDoc.reference.snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            if (data == null) return const Center(child: Text('Data error'));
                            
                            final subjects = data['subjects'] as List<dynamic>? ?? [];
                            if (subjects.isEmpty) return const Center(child: Text('No subjects added yet.'));
                            
                            return ListView.builder(
                              itemCount: subjects.length,
                              itemBuilder: (context, index) {
                                final sub = subjects[index] as Map<String, dynamic>;
                                final name = sub['name'] ?? 'Unnamed';
                                final faculties = sub['faculties'] as List<dynamic>? ?? [];
                                
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ExpansionTile(
                                    title: Text(name),
                                    subtitle: Text('${faculties.length} faculties assigned'),
                                    children: [
                                      ...faculties.map((f) => ListTile(
                                            title: Text(f['name'] ?? 'Unknown Faculty'),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () {
                                                final updatedSubs = List<dynamic>.from(subjects);
                                                final targetSub = updatedSubs[index] as Map<String, dynamic>;
                                                final targetFacs = List<dynamic>.from(targetSub['faculties'] ?? []);
                                                targetFacs.removeWhere((fac) => fac['uid'] == f['uid']);
                                                targetSub['faculties'] = targetFacs;
                                                widget.classDoc.reference.update({'subjects': updatedSubs});
                                              },
                                            ),
                                          )),
                                      TextButton.icon(
                                        icon: const Icon(Icons.add),
                                        label: const Text('Assign Faculty'),
                                        onPressed: () => _showAssignFacultyDialog(index, subjects),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  // Tab 2: Students
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'Student')
                        .where('classId', isEqualTo: widget.classDoc.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;
                      
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton.icon(
                              onPressed: _showAssignStudentDialog,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Assign Student'),
                              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            ),
                          ),
                          if (docs.isEmpty) 
                            const Expanded(child: Center(child: Text('No students assigned to this class.')))
                          else
                            Expanded(
                              child: ListView.builder(
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final data = docs[index].data() as Map<String, dynamic>;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: ListTile(
                                      leading: const CircleAvatar(child: Icon(Icons.person)),
                                      title: Text(data['name'] ?? data['fullName'] ?? 'Unknown Student'),
                                      subtitle: Text(data['email'] ?? ''),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                        onPressed: () {
                                          FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(docs[index].id)
                                              .update({'classId': FieldValue.delete(), 'className': FieldValue.delete()});
                                        },
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignFacultyDialog(int subjectIndex, List<dynamic> currentSubjects) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Faculty'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Faculty').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Text('No faculty accounts found.');
                
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    final d = docs[idx].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(d['name'] ?? d['fullName'] ?? 'Unknown'),
                      subtitle: Text(d['email'] ?? ''),
                      onTap: () {
                        final updatedSubs = List<dynamic>.from(currentSubjects);
                        final targetSub = updatedSubs[subjectIndex] as Map<String, dynamic>;
                        final targetFacs = List<dynamic>.from(targetSub['faculties'] ?? []);
                        
                        if (!targetFacs.any((f) => f['uid'] == docs[idx].id)) {
                          targetFacs.add({
                            'uid': docs[idx].id,
                            'name': d['name'] ?? d['fullName'] ?? 'Unknown'
                          });
                          targetSub['faculties'] = targetFacs;
                          widget.classDoc.reference.update({'subjects': updatedSubs});
                        }
                        Navigator.pop(context);
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

  void _showAssignStudentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Student'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Student').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                // Filter out students already assigned to this class
                final docs = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['classId'] != widget.classDoc.id;
                }).toList();
                
                if (docs.isEmpty) return const Text('No unassigned students found.');
                
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    final d = docs[idx].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(d['name'] ?? d['fullName'] ?? 'Unknown'),
                      subtitle: Text(d['email'] ?? ''),
                      onTap: () {
                        FirebaseFirestore.instance.collection('users').doc(docs[idx].id).update({
                          'classId': widget.classDoc.id,
                          'className': widget.classDoc['className'],
                        });
                        Navigator.pop(context);
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
