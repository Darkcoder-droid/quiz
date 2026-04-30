import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import '../../utils/app_theme.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            tooltip: 'Logout',
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return const PendingApprovalsTab(key: ValueKey(0));
      case 1:
        return const ManageClassesTab(key: ValueKey(1));
      case 2:
        return const ManageUsersTab(key: ValueKey(2));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('isApproved', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return Badge(
                  label: Text(count.toString()),
                  isLabelVisible: count > 0,
                  child: const Icon(Icons.pending_actions_rounded),
                );
              },
            ),
            label: 'Approvals',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.class_rounded),
            label: 'Classes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}

class PendingApprovalsTab extends StatelessWidget {
  const PendingApprovalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isApproved', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'All caught up!',
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade600),
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
            final uid = docs[index].id;
            return _buildApprovalCard(context, uid, data);
          },
        );
      },
    );
  }

  Widget _buildApprovalCard(BuildContext context, String uid, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(data['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${data['role']} â€¢ ${data['email']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: AppTheme.successColor),
              onPressed: () => _showConfirmDialog(context, 'Approve', 'Approve this user?', () async {
                try {
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({'isApproved': true});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User approved!'), backgroundColor: AppTheme.successColor));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.errorColor));
                  }
                }
              }),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: AppTheme.errorColor),
              onPressed: () => _showConfirmDialog(context, 'Reject', 'Reject and delete this user?', () async {
                try {
                  await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.errorColor));
                  }
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: Text(title, style: const TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }
}

class ManageClassesTab extends StatelessWidget {
  const ManageClassesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final classId = docs[index].id;
              return _buildClassCard(context, classId, data);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClassDialog(context),
        label: const Text('Add Class'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, String classId, Map<String, dynamic> data) {
    final className = data['className'] ?? data['name'] ?? 'Unnamed Class';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Text(className[0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor)),
        ),
        title: Text(className, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data['section'] ?? 'No Section'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('users').where('classId', isEqualTo: classId).get(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _buildInfoRow(Icons.group, 'Students', '$count Enrolled');
                  },
                ),
                const SizedBox(height: 16),
                const Text('Subjects', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildSubjectsList(context, classId, data),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAddSubjectDialog(context, classId, data),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Subject'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                      onPressed: () => _confirmDeleteClass(context, classId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showAddClassDialog(BuildContext context) {
    final nameController = TextEditingController();
    final sectionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Class Name')),
            const SizedBox(height: 12),
            TextField(controller: sectionController, decoration: const InputDecoration(hintText: 'Section')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('classes').add({
                  'name': nameController.text.trim(),
                  'section': sectionController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'subjects': [],
                  'assignedFacultyUids': [],
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsList(BuildContext context, String classId, Map<String, dynamic> data) {
    List<dynamic> subjects = data['subjects'] ?? [];
    if (subjects.isEmpty) {
      return const Text('No subjects added yet.', style: TextStyle(color: Colors.grey));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index] as Map<String, dynamic>;
        final String subName = subject['name'] ?? 'Unnamed Subject';
        final List<dynamic> faculties = subject['faculties'] ?? [];
        return Card(
          color: Colors.grey.shade50,
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(subName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1, size: 20),
                      onPressed: () => _showAssignFacultyDialog(context, classId, data, index),
                      tooltip: 'Assign Faculty',
                      color: AppTheme.primaryColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (faculties.isEmpty)
                  const Text('No faculties assigned', style: TextStyle(color: Colors.grey, fontSize: 12))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: faculties.map((f) {
                      return Chip(
                        label: Text(f['name'] ?? ''),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeFacultyFromSubject(classId, data, index, f['uid']),
                        padding: EdgeInsets.zero,
                        labelStyle: const TextStyle(fontSize: 12),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddSubjectDialog(BuildContext context, String classId, Map<String, dynamic> data) {
    final subController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subject'),
        content: TextField(controller: subController, decoration: const InputDecoration(hintText: 'Subject Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (subController.text.isNotEmpty) {
                List<dynamic> subjects = List.from(data['subjects'] ?? []);
                subjects.add({'name': subController.text.trim(), 'faculties': []});
                FirebaseFirestore.instance.collection('classes').doc(classId).update({'subjects': subjects});
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showAssignFacultyDialog(BuildContext context, String classId, Map<String, dynamic> data, int subjectIndex) {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Faculty').where('isApproved', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final facultyDocs = snapshot.data!.docs;
          
          return AlertDialog(
            title: const Text('Assign Faculty'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: facultyDocs.length,
                itemBuilder: (context, index) {
                  final fData = facultyDocs[index].data() as Map<String, dynamic>;
                  final fUid = facultyDocs[index].id;
                  
                  // Check if already assigned
                  List<dynamic> subjects = List.from(data['subjects'] ?? []);
                  List<dynamic> assignedFaculties = List.from(subjects[subjectIndex]['faculties'] ?? []);
                  bool isAssigned = assignedFaculties.any((f) => f['uid'] == fUid);
                  
                  return ListTile(
                    title: Text(fData['name'] ?? ''),
                    subtitle: Text(fData['email'] ?? ''),
                    trailing: isAssigned ? const Icon(Icons.check_circle, color: AppTheme.successColor) : null,
                    onTap: () async {
                      if (!isAssigned) {
                        assignedFaculties.add({'uid': fUid, 'name': fData['name']});
                        subjects[subjectIndex]['faculties'] = assignedFaculties;
                        
                        // Update assignedFacultyUids
                        List<dynamic> assignedFacultyUids = List.from(data['assignedFacultyUids'] ?? []);
                        if (!assignedFacultyUids.contains(fUid)) {
                          assignedFacultyUids.add(fUid);
                        }
                        
                        await FirebaseFirestore.instance.collection('classes').doc(classId).update({
                          'subjects': subjects,
                          'assignedFacultyUids': assignedFacultyUids,
                        });
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _removeFacultyFromSubject(String classId, Map<String, dynamic> data, int subjectIndex, String uidToRemove) async {
    List<dynamic> subjects = List.from(data['subjects'] ?? []);
    List<dynamic> assignedFaculties = List.from(subjects[subjectIndex]['faculties'] ?? []);
    
    assignedFaculties.removeWhere((f) => f['uid'] == uidToRemove);
    subjects[subjectIndex]['faculties'] = assignedFaculties;
    
    // Check if faculty is still assigned to ANY other subject in this class
    bool stillAssigned = false;
    for (var sub in subjects) {
      if ((sub['faculties'] as List<dynamic>).any((f) => f['uid'] == uidToRemove)) {
        stillAssigned = true;
        break;
      }
    }
    
    List<dynamic> assignedFacultyUids = List.from(data['assignedFacultyUids'] ?? []);
    if (!stillAssigned) {
      assignedFacultyUids.remove(uidToRemove);
    }
    
    await FirebaseFirestore.instance.collection('classes').doc(classId).update({
      'subjects': subjects,
      'assignedFacultyUids': assignedFacultyUids,
    });
  }

  void _confirmDeleteClass(BuildContext context, String classId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text('This will delete the class and all associated data. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('classes').doc(classId).delete();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}

class ManageUsersTab extends StatefulWidget {
  const ManageUsersTab({super.key});

  @override
  State<ManageUsersTab> createState() => _ManageUsersTabState();
}

class _ManageUsersTabState extends State<ManageUsersTab> {
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedRoleFilter,
                items: ['All', 'Student', 'Faculty', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _selectedRoleFilter = v!),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('isApproved', isEqualTo: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nameMatch = (data['name'] ?? '').toString().toLowerCase().contains(_searchQuery);
                final emailMatch = (data['email'] ?? '').toString().toLowerCase().contains(_searchQuery);
                final roleMatch = _selectedRoleFilter == 'All' || data['role'] == _selectedRoleFilter;
                return (nameMatch || emailMatch) && roleMatch;
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRoleColor(data['role']).withValues(alpha: 0.1),
                        child: Icon(_getRoleIcon(data['role']), color: _getRoleColor(data['role']), size: 20),
                      ),
                      title: Text(data['name'] ?? ''),
                      subtitle: Text(data['email'] ?? ''),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          if (data['role'] != 'Admin')
                            const PopupMenuItem(value: 'make_admin', child: Text('Promote to Admin')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete User', style: TextStyle(color: AppTheme.errorColor))),
                        ],
                        onSelected: (v) => _handleUserAction(context, docs[index].id, v),
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

  void _handleUserAction(BuildContext context, String uid, String action) {
    if (action == 'make_admin') {
      FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'Admin'});
    } else if (action == 'delete') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete User'),
          content: const Text('Are you sure? This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('users').doc(uid).delete();
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
            ),
          ],
        ),
      );
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'Admin': return Colors.purple;
      case 'Faculty': return Colors.orange;
      case 'Student': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'Admin': return Icons.admin_panel_settings;
      case 'Faculty': return Icons.person;
      case 'Student': return Icons.school;
      default: return Icons.person_outline;
    }
  }
}

