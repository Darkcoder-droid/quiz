import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/royal_colors.dart';
import '../widgets/astra_id_card.dart';
import '../widgets/royal_button.dart';
import 'auth/login_screen.dart';

class ProfileTab extends StatelessWidget {
  final String role;
  
  const ProfileTab({super.key, required this.role});

  Future<void> _logout(BuildContext context) async {
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen(shouldSignOut: true)),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] ?? 'User';
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Profile Header
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/avatar_default.png'),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(
                    color: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary,
                    width: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                role,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 48),

              // Astra ID Card
              AstraIdCard(
                title: 'Astra Pass',
                name: name,
                idText: 'ID: AST-${user.uid.substring(0, 6).toUpperCase()}',
                validThru: '12/28',
                subtitle: '${role.toUpperCase()} LEVEL',
              ),
              
              const SizedBox(height: 64),
              
              // Big Logout Button
              RoyalButton(
                text: 'Sign Out',
                onPressed: () => _logout(context),
                isPrimary: false,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
