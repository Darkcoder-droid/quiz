import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animations/animations.dart';
import '../../utils/royal_colors.dart';
import '../../widgets/royal_card.dart';
import '../../widgets/royal_button.dart';
import '../../widgets/astra_id_card.dart';
import '../auth/login_screen.dart';
import '../profile_tab.dart';
import '../../main.dart' as import_main;
import 'admin_assignment_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // Allows background to flow under the floating pill
      backgroundColor: isDark ? RoyalColors.darkBackground : RoyalColors.lightBackground,
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
          child: _buildCurrentTab(),
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
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, 'ADMIN', isDark),
              _buildNavItem(1, Icons.assignment_outlined, Icons.assignment, 'ASSIGN', isDark),
              _buildNavItem(2, Icons.manage_accounts_outlined, Icons.manage_accounts, 'MANAGE', isDark),
              _buildNavItem(3, Icons.person_outline, Icons.person_rounded, 'ME', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return const AdminDashboardTab(key: ValueKey(0));
      case 1:
        return const AdminAssignmentTab(key: ValueKey(1));
      case 2:
        return const ManageUsersTab(key: ValueKey(2));
      case 3:
        return const ProfileTab(key: ValueKey(3), role: 'Admin');
      default:
        return const Center(child: Text("Coming Soon"));
    }
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    // Use gold (darkAccent) in dark mode for the active tab pill color instead of darkPrimary (which is blue)
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

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    // Use Gold (darkAccent) instead of Deep Blue (darkPrimary) for dark mode text
    final primaryTextColor = isDark ? RoyalColors.darkAccent : RoyalColors.lightPrimary;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
        
        final adminData = userSnap.data?.data() as Map<String, dynamic>?;
        final adminName = adminData?['name'] ?? 'Admin';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final allDocs = snapshot.data!.docs;
            final pendingDocs = allDocs.where((d) => (d.data() as Map<String, dynamic>)['isApproved'] == false).toList();
            final totalUsers = allDocs.length;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.share, color: primaryTextColor),
                        const SizedBox(width: 8),
                        Text(
                          'Astra',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: AssetImage('assets/images/avatar_default.png'),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(
                            color: isDark ? RoyalColors.darkBorder : RoyalColors.lightBorder,
                          ),
                        ),
                      ),
                      onSelected: (value) async {
                        if (value == 'theme') {
                          import_main.themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                        } else if (value == 'logout') {
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

                          if (confirm == true && context.mounted) {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen(shouldSignOut: true)), (route) => false);
                            }
                          }
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
                const SizedBox(height: 32),
                Text(
                  'Hi, $adminName!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s a quick overview of today\'s activities.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                      ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? RoyalColors.darkSurface : RoyalColors.lightSurface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.5) : const Color(0xFF00236F).withOpacity(0.02),
                        blurRadius: 40,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people_outline, color: isDark ? RoyalColors.darkTextPrimary : RoyalColors.lightTextPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Total Users',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$totalUsers',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 64,
                              letterSpacing: -2,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
                  builder: (context, quizSnap) {
                    if (!quizSnap.hasData) return const Center(child: CircularProgressIndicator());
                    
                    final now = DateTime.now();
                    final todayQuizzes = quizSnap.data!.docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final scheduledAt = data['scheduledAt'] as Timestamp?;
                      if (scheduledAt == null) return false;
                      final dt = scheduledAt.toDate();
                      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
                    }).toList();

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? RoyalColors.darkSurface : RoyalColors.lightSurface,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.5) : const Color(0xFF00236F).withOpacity(0.02),
                            blurRadius: 40,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: RoyalColors.lightAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.quiz, color: RoyalColors.lightAccent),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today\'s Quizzes',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '${todayQuizzes.length} Quizzes Scheduled',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        children: [
                          if (todayQuizzes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text('No quizzes scheduled for today.'),
                            )
                          else
                            ...todayQuizzes.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final title = data['title'] ?? 'Untitled Quiz';
                              final className = data['className'] ?? 'Unknown Class';
                              final subject = data['subject'] ?? 'General';
                              return ListTile(
                                leading: const Icon(Icons.timer_outlined, color: RoyalColors.lightSecondary),
                                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('$className • $subject'),
                                trailing: const Icon(Icons.chevron_right, size: 16),
                              );
                            }).toList(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100), // padding for floating nav bar
              ],
            );
          },
        );
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                    prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    filled: true,
                    fillColor: isDark ? RoyalColors.darkSurface : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? RoyalColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? RoyalColors.darkBorder : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRoleFilter,
                    dropdownColor: isDark ? RoyalColors.darkSurface : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    items: ['All', 'Student', 'Faculty', 'Admin']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedRoleFilter = v!),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final allDocs = snapshot.data!.docs;
              final pendingDocs = allDocs.where((d) => (d.data() as Map)['isApproved'] == false).toList();
              final approvedDocs = allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                if (data['isApproved'] == false) return false;
                final nameMatch = (data['name'] ?? '').toString().toLowerCase().contains(_searchQuery);
                final emailMatch = (data['email'] ?? '').toString().toLowerCase().contains(_searchQuery);
                final roleMatch = _selectedRoleFilter == 'All' || data['role'] == _selectedRoleFilter;
                return (nameMatch || emailMatch) && roleMatch;
              }).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (pendingDocs.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: RoyalColors.lightAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: RoyalColors.lightAccent.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.pending_actions, color: RoyalColors.lightAccent),
                              const SizedBox(width: 8),
                              Text(
                                '${pendingDocs.length} Pending Request(s)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...pendingDocs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getRoleColor(data['role']).withOpacity(0.1),
                                  child: Icon(_getRoleIcon(data['role']), color: _getRoleColor(data['role']), size: 20),
                                ),
                                title: Text(data['name'] ?? ''),
                                subtitle: Text('Role: ${data['role']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      onPressed: () => doc.reference.update({'isApproved': true}),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () => doc.reference.delete(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                  if (approvedDocs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No users found',
                          style: TextStyle(color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary),
                        ),
                      ),
                    )
                  else
                    ...approvedDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? RoyalColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withOpacity(0.5) : const Color(0xFF00236F).withOpacity(0.02),
                              blurRadius: 40,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(data['role']).withOpacity(0.1),
                            child: Icon(_getRoleIcon(data['role']), color: _getRoleColor(data['role']), size: 20),
                          ),
                          title: Text(
                            data['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            data['email'] ?? '',
                            style: TextStyle(color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary),
                          ),
                          trailing: PopupMenuButton(
                            icon: Icon(Icons.more_vert, color: isDark ? Colors.white : Colors.black),
                            itemBuilder: (context) => [
                              if (data['role'] != 'Admin')
                                const PopupMenuItem(value: 'make_admin', child: Text('Promote to Admin')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete User', style: TextStyle(color: RoyalColors.lightError))),
                            ],
                            onSelected: (v) => _handleUserAction(context, doc.id, v),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 100), // padding
                ],
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
              child: const Text('Delete', style: TextStyle(color: RoyalColors.lightError)),
            ),
          ],
        ),
      );
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'Admin': return const Color(0xFF9C27B0); // Purple
      case 'Faculty': return const Color(0xFFF57C00); // Orange
      case 'Student': return const Color(0xFF1976D2); // Blue
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
