import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/royal_colors.dart';
import '../../widgets/royal_input.dart';
import '../../widgets/royal_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _selectedRole = 'Student';
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _termsAccepted = false;
  
  double _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordStrength);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final text = _passwordController.text;
    double strength = 0;
    if (text.length >= 6) strength += 0.33;
    if (text.contains(RegExp(r'[A-Z]'))) strength += 0.33;
    if (text.contains(RegExp(r'[0-9!@#\$%^&*]'))) strength += 0.34;
    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);
    });
  }

  Future<void> _signup() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (!_termsAccepted) {
      _showError('Please accept the terms and conditions');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final userData = {
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
        'isApproved': _selectedRole == 'Admin', // Admin auto-approves
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      if (mounted) {
        if (_selectedRole == 'Admin') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin created. Please log in.')));
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          Navigator.pushReplacementNamed(context, '/pending_approval');
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Registration failed');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: RoyalColors.lightError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? RoyalColors.darkBackground : RoyalColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary,
              ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRoleSelector(isDark),
              const SizedBox(height: 32),
              RoyalInput(
                controller: _nameController,
                hintText: 'Full Name',
              ),
              const SizedBox(height: 16),
              RoyalInput(
                controller: _emailController,
                hintText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              RoyalInput(
                controller: _phoneController,
                hintText: 'Phone Number (Optional)',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              RoyalInput(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordStrengthBar(),
              const SizedBox(height: 16),
              RoyalInput(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                obscureText: true,
                onChanged: (_) => setState(() {}),
                suffixIcon: _confirmPasswordController.text.isNotEmpty && _passwordController.text == _confirmPasswordController.text
                    ? const Icon(Icons.check_circle, color: RoyalColors.lightSuccess)
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _termsAccepted,
                      onChanged: (val) => setState(() => _termsAccepted = val ?? false),
                      activeColor: isDark ? RoyalColors.darkAccent : RoyalColors.lightAccent,
                      checkColor: isDark ? RoyalColors.darkBackground : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'I agree to the Terms and Conditions',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              RoyalButton(
                text: 'Sign Up',
                onPressed: _signup,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Login',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary,
                            decoration: TextDecoration.underline,
                            decorationColor: isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary,
                          ),
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

  Widget _buildRoleSelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? RoyalColors.darkBorder : RoyalColors.lightBorder,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildRoleTab('Student', isDark),
          _buildRoleTab('Faculty', isDark),
        ],
      ),
    );
  }

  Widget _buildRoleTab(String role, bool isDark) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDark ? RoyalColors.darkAccent : RoyalColors.lightAccent) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            role,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected 
                      ? (isDark ? RoyalColors.darkBackground : Colors.white) 
                      : (isDark ? RoyalColors.darkPrimary : RoyalColors.lightPrimary),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthBar() {
    Color barColor = RoyalColors.lightError;
    if (_passwordStrength > 0.6) {
      barColor = RoyalColors.lightSuccess;
    } else if (_passwordStrength > 0.3) {
      barColor = RoyalColors.lightWarning;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 4,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? RoyalColors.darkBorder 
                    : RoyalColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 4,
              width: constraints.maxWidth * _passwordStrength,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        );
      },
    );
  }
}
