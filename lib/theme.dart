import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme so light/dark stay in sync and colors aren't
/// scattered as magic hex values across widgets.
class AppTheme {
  static const _seed = Color(0xFF4F46E5); // same indigo as before — keep the identity

  static ThemeData light() {
    final base = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      // Simpler than interTextTheme(): just point the whole theme's font
      // family at Inter. Avoids the TextTheme-argument overload entirely.
      fontFamily: GoogleFonts.inter().fontFamily,
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE5E7EB),
    );
  }

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      fontFamily: GoogleFonts.inter().fontFamily,
      cardColor: const Color(0xFF1A1D23),
      dividerColor: const Color(0xFF2A2E37),
    );
  }

  /// Score-based color, used by both the gauge and the skill chips —
  /// one place to change the thresholds instead of three.
  static Color scoreColor(int score, ColorScheme scheme) {
    if (score >= 70) return const Color(0xFF16A34A);
    if (score >= 40) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }
}
