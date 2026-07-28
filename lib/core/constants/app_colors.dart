import 'package:flutter/material.dart';

/// Palette de couleurs exacte de l'application Diaba (identique au Frontend React)
/// Basée sur le Bleu Diaba (#2F80ED), l'Orange Warm (#F2994A) et le Vert (#27AE60)
class AppColors {
  AppColors._();

  // ─── Primary (Bleu Diaba #2F80ED) ─────────────────────────────────────────
  static const Color primary = Color(0xFF2F80ED);
  static const Color primaryLight = Color(0xFF5699F2);
  static const Color primaryDark = Color(0xFF1B59B0);
  static const Color primaryContainer = Color(0xFFE8F1FD);
  static const Color onPrimaryContainer = Color(0xFF0B2852);

  // ─── Secondary (Orange Warm #F2994A) ───────────────────────────────────────
  static const Color secondary = Color(0xFFF2994A);
  static const Color secondaryLight = Color(0xFFF5B073);
  static const Color secondaryDark = Color(0xFFC97327);
  static const Color secondaryContainer = Color(0xFFFDF1E6);

  // ─── Accent (Vert Sénégal #27AE60) ────────────────────────────────────────
  static const Color accent = Color(0xFF27AE60);
  static const Color accentLight = Color(0xFF4CD984);

  // ─── Neutrals (Light Mode - Slate Cool) ────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // ─── Neutrals (Dark Mode - Deep Navy Slate 900) ───────────────────────────
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF334155);

  // ─── Text (Light & Dark) ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // ─── Status Colors ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF2994A);
  static const Color error = Color(0xFFEB5757);
  static const Color info = Color(0xFF2F80ED);

  // ─── Order Status ─────────────────────────────────────────────────────────
  static const Color statusPending = Color(0xFFF2994A);
  static const Color statusConfirmed = Color(0xFF2F80ED);
  static const Color statusProcessing = Color(0xFF9B51E0);
  static const Color statusShipped = Color(0xFF6366F1);
  static const Color statusAtDepot = Color(0xFFE056FD);
  static const Color statusReady = Color(0xFF10B981);
  static const Color statusDelivered = Color(0xFF27AE60);
  static const Color statusCancelled = Color(0xFFEB5757);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryDark],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2F80ED), Color(0xFF1B59B0)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x0F2F80ED), Color(0x042F80ED)],
  );
}
