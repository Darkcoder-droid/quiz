import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'royal_colors.dart';

class AppTheme {
  // Backward compatibility for screens not yet overhauled
  static const Color primaryColor = RoyalColors.lightPrimary;
  static const Color accentColor = RoyalColors.lightAccent;
  static const Color backgroundColor = RoyalColors.lightBackground;
  static const Color cardColor = RoyalColors.lightSurface;
  static const Color errorColor = RoyalColors.lightError;
  static const Color successColor = RoyalColors.lightSuccess;
  static const Color warningColor = RoyalColors.lightWarning;

  static ThemeData get light {
    final baseTextTheme = GoogleFonts.workSansTextTheme(ThemeData.light().textTheme);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: RoyalColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: RoyalColors.lightPrimary,
        secondary: RoyalColors.lightSecondary,
        surface: RoyalColors.lightSurface,
        error: RoyalColors.lightError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: RoyalColors.lightTextPrimary,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -0.96, color: RoyalColors.lightTextPrimary),
        headlineLarge: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: -0.36, color: RoyalColors.lightTextPrimary),
        headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: RoyalColors.lightTextPrimary),
        headlineSmall: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: RoyalColors.lightTextPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: RoyalColors.lightTextPrimary),
        bodyLarge: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.w400, color: RoyalColors.lightTextPrimary),
        bodyMedium: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w400, color: RoyalColors.lightTextPrimary),
        bodySmall: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w400, color: RoyalColors.lightTextSecondary),
        labelSmall: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: RoyalColors.lightTextSecondary),
        labelLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white), // buttons
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: RoyalColors.lightBackground,
        foregroundColor: RoyalColors.lightPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: RoyalColors.lightPrimary,
        ),
        iconTheme: const IconThemeData(color: RoyalColors.lightPrimary),
      ),
    );
  }

  static ThemeData get dark {
    final baseTextTheme = GoogleFonts.workSansTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: RoyalColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: RoyalColors.darkPrimary,
        secondary: RoyalColors.darkSecondary,
        surface: RoyalColors.darkSurface,
        error: RoyalColors.darkError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: RoyalColors.darkTextPrimary,
        onError: Colors.black,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -0.96, color: RoyalColors.darkTextPrimary),
        headlineLarge: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: -0.36, color: RoyalColors.darkTextPrimary),
        headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: RoyalColors.darkTextPrimary),
        headlineSmall: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: RoyalColors.darkTextPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: RoyalColors.darkTextPrimary),
        bodyLarge: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.w400, color: RoyalColors.darkTextPrimary),
        bodyMedium: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w400, color: RoyalColors.darkTextPrimary),
        bodySmall: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w400, color: RoyalColors.darkTextSecondary),
        labelSmall: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: RoyalColors.darkTextSecondary),
        labelLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black), // buttons
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: RoyalColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}
