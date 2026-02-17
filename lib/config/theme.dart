import 'package:flutter/material.dart';

class AppColors {
  // Primary emerald/teal
  static const Color primary = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color cyan500 = Color(0xFF06B6D4);

  // Dark theme
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color blue950 = Color(0xFF172554);

  // Purple (employee login)
  static const Color purple900 = Color(0xFF581C87);
  static const Color purple700 = Color(0xFF7C3AED);

  // Blue
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue400 = Color(0xFF60A5FA);

  // Text
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGray = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Background
  static const Color bgLight = Color(0xFFF1F5F9);
  static const Color bgCard = Colors.white;

  // Error
  static const Color error = Color(0xFFEF4444);

  // Success
  static const Color success = Color(0xFF22C55E);
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.teal500],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryButton = LinearGradient(
    colors: [AppColors.primary, AppColors.teal500, AppColors.cyan500],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient dark = LinearGradient(
    colors: [AppColors.slate900, AppColors.blue950],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purple = LinearGradient(
    colors: [AppColors.slate900, AppColors.purple900],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splash = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF0D9488), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
