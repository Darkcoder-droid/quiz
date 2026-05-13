import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/royal_colors.dart';
import 'login_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshStatus() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1)); // Small UX delay
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final isApproved = doc.data()?['isApproved'] ?? false;
          if (isApproved && mounted) {
            // Approval granted! 
            Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
            return;
          }
        }
      }
    } catch (e) {
      // Ignore
    }
    
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still pending approval. Please try again later.'), backgroundColor: RoyalColors.lightTextSecondary),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen(shouldSignOut: true)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? RoyalColors.darkBackground : RoyalColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? RoyalColors.darkSurface : RoyalColors.lightSurface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 40,
                        color: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Account Pending',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your access request has been submitted and is currently under review by an administrator.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? RoyalColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(RoyalColors.lightAccent),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Awaiting Verification',
                            style: TextStyle(
                              color: isDark ? RoyalColors.darkTextPrimary : RoyalColors.lightTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _isRefreshing ? null : _refreshStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Check Status',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _logout,
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: const Text(
                      'Sign out',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
