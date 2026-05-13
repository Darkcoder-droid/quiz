import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import '../utils/royal_colors.dart';
import '../widgets/astra_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Welcome to Astra",
      "subtitle": "Your premier education platform tailored for modern learning and comprehensive assessment.",
      "image": "assets/images/astra_logo.png"
    },
    {
      "title": "Seamless Learning",
      "subtitle": "Access quizzes, track your progress, and elevate your academic journey anytime, anywhere.",
      "image": "assets/images/astra_logo.png"
    },
    {
      "title": "Get Started",
      "subtitle": "Join our community today and experience the future of education.",
      "image": "assets/images/astra_logo.png"
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? RoyalColors.darkBackground : RoyalColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  "Skip",
                  style: TextStyle(
                    color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) => _OnboardingContent(
                  title: onboardingData[index]["title"]!,
                  subtitle: onboardingData[index]["subtitle"]!,
                  image: onboardingData[index]["image"]!,
                  isDark: isDark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => _buildDot(index: index, isDark: isDark),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == onboardingData.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RoyalColors.lightAccent, // Gold
                      foregroundColor: RoyalColors.lightPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                      _currentPage == onboardingData.length - 1 ? "Get Started" : "Next",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required int index, required bool isDark}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? RoyalColors.lightAccent
            : (isDark ? RoyalColors.darkBorder : RoyalColors.lightBorder),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  final String title, subtitle, image;
  final bool isDark;

  const _OnboardingContent({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AstraLogo(size: 160),
          const SizedBox(height: 48),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : RoyalColors.lightPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? RoyalColors.darkTextSecondary : RoyalColors.lightTextSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
