import 'package:flutter/material.dart';

/// Cores do aplicativo Self Dojo
abstract final class AppColors {
  // Brand Colors
  static const primary = Color(0xFF6366F1);       // Indigo
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark = Color(0xFF4F46E5);

  static const secondary = Color(0xFF10B981);     // Emerald
  static const secondaryLight = Color(0xFF34D399);
  static const secondaryDark = Color(0xFF059669);

  // Accent
  static const accent = Color(0xFFF59E0B);        // Amber
  static const accentLight = Color(0xFFFBBF24);

  // Neutrals - Dark Theme
  static const backgroundDark = Color(0xFF0F0F23);
  static const surfaceDark = Color(0xFF1A1A2E);
  static const surfaceVariantDark = Color(0xFF252542);
  static const cardDark = Color(0xFF16213E);

  // Neutrals - Light Theme
  static const backgroundLight = Color(0xFFF8FAFC);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceVariantLight = Color(0xFFF1F5F9);
  static const cardLight = Color(0xFFFFFFFF);

  // Text Colors - Dark Theme
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const textTertiaryDark = Color(0xFF64748B);

  // Text Colors - Light Theme
  static const textPrimaryLight = Color(0xFF0F172A);
  static const textSecondaryLight = Color(0xFF475569);
  static const textTertiaryLight = Color(0xFF94A3B8);

  // Semantic Colors
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Gradient
  static const gradientStart = Color(0xFF6366F1);
  static const gradientEnd = Color(0xFF8B5CF6);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  // Shadows
  static const shadowColor = Color(0x1A000000);
  static const shadowColorDark = Color(0x40000000);
}

