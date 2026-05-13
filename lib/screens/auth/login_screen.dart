import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../student/student_home_screen.dart';
import '../faculty/faculty_home_screen.dart';
import '../admin/admin_home_screen.dart';
import 'signup_screen.dart';
import 'pending_approval_screen.dart';
import '../../utils/royal_colors.dart';
import '../../widgets/astra_logo.dart';

class LoginScreen extends StatefulWidget {
  final String? errorMessage;
  final bool shouldSignOut;
  const LoginScreen({super.key, this.errorMessage, this.shouldSignOut = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.errorMessage != null) {
      _errorMessage = widget.errorMessage!;
    }
    if (widget.shouldSignOut) {
      FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final doc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      if (!doc.exists) throw Exception('User record not found.');

      final data = doc.data() as Map<String, dynamic>;
      final isApproved = data['isApproved'] ?? false;
      final role = data['role'] ?? 'Student';

      if (!mounted) return;

      if (!isApproved && role != 'Student') {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PendingApprovalScreen()));
      } else {
        if (role == 'Admin') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
        } else if (role == 'Faculty') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const FacultyHomeScreen()));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const StudentHomeScreen()));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst(RegExp(r'\[.*?\] '), ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? RoyalColors.darkBackground : RoyalColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const AstraLogo(size: 80),
              ),
              const SizedBox(height: 24),
              // Title
              const Text(
                'Astra',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome back to Astra',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 48),

              // Login Form Card
              Container(
                padding: const EdgeInsets.all(32),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Email Field
                    const Text(
                      'EMAIL ADDRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? RoyalColors.darkSurfaceElevated : RoyalColors.lightBackground,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: isDark ? RoyalColors.darkBorder : RoyalColors.lightSecondary.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: _emailController,
                        style: TextStyle(color: isDark ? RoyalColors.darkTextPrimary : RoyalColors.lightTextPrimary),
                        decoration: InputDecoration(
                          hintText: 'name@company.com',
                          hintStyle: TextStyle(color: isDark ? RoyalColors.darkTextSecondary : const Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          suffixIcon: Icon(Icons.mail_outline, color: isDark ? RoyalColors.darkTextSecondary : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Password Field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? RoyalColors.darkSurfaceElevated : RoyalColors.lightBackground,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: isDark ? RoyalColors.darkBorder : RoyalColors.lightSecondary.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(color: isDark ? RoyalColors.darkTextPrimary : RoyalColors.lightTextPrimary),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(color: isDark ? RoyalColors.darkTextSecondary : const Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          suffixIcon: Icon(Icons.lock_outline, color: isDark ? RoyalColors.darkTextSecondary : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9999),
                        gradient: LinearGradient(
                          colors: [
                            isDark ? RoyalColors.darkAccent : RoyalColors.lightAccent,
                            isDark ? RoyalColors.darkAccent : RoyalColors.lightAccentLighter,
                          ],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: isDark ? RoyalColors.darkPrimary : Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999), // Pill shape
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Login',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Bottom Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge(Icons.verified_user_outlined, 'Secure Encryption'),
                  const SizedBox(width: 24),
                  _buildBadge(Icons.language, 'Global Access'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
