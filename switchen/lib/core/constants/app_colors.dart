import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Primary: Hijau Switchen ──────────────────────────────
  static const Color primary      = Color(0xFF00615F); // Teal utama
  static const Color primaryLight = Color(0xFF007E7B);
  static const Color primaryDark  = Color(0xFF004745);
  static const Color primaryBg    = Color(0xFFE6F2F2); // bg ringan primary

  // ── Brand Accent: Pink / Coral ─────────────────────────────────
  static const Color accent       = Color(0xFFFF7973); // Pink aksen (CTA button)
  static const Color accentLight  = Color(0xFFFFABA7);
  static const Color accentDark   = Color(0xFFE55D57);

  // ── Background ─────────────────────────────────────────────────
  static const Color background      = Color(0xFFF5F5F0); // Krem sangat ringan
  static const Color surface         = Color(0xFFFFFFFF);
  static const Color surfaceVariant  = Color(0xFFF2F2EE);
  static const Color headerBg        = Color(0xFF00615F); // Header teal gelap

  // ── Text ───────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFFADB5BD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent  = Color(0xFFFFFFFF);

  // ── Status ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info    = Color(0xFF3B82F6);

  // ── Price ──────────────────────────────────────────────────────
  static const Color priceColor         = Color(0xFF00615F);
  static const Color originalPriceColor = Color(0xFF9CA3AF);
  static const Color discountBg         = Color(0xFFFFEDEC);
  static const Color discountText       = Color(0xFFFF7973);

  // ── Card & Shadow ──────────────────────────────────────────────
  static const Color cardBg      = Color(0xFFFFFFFF);
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium= Color(0x14000000);
  static const Color divider     = Color(0xFFEEEEEA);

  // ── Category Chip ──────────────────────────────────────────────
  static const Color chipSelected   = Color(0xFF00615F);
  static const Color chipUnselected = Color(0xFFFFFFFF);

  // ── Partner Category ───────────────────────────────────────────
  static const Color restaurant = Color(0xFFFF7973);
  static const Color cafe       = Color(0xFF00615F);
  static const Color bakery     = Color(0xFFF59E0B);

  // ── Bottom Nav ─────────────────────────────────────────────────
  static const Color navActive   = Color(0xFF00615F);
  static const Color navInactive = Color(0xFF9CA3AF);
}
