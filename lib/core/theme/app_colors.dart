import 'package:flutter/material.dart';

/// Hearable Acoustic & Visual Color Tokens
/// Inspired by Apple Music Deep Obsidian Frosted Glass
class AppColors {
  // Base Obsidian AMOLED Backgrounds
  static const Color background = Color(0xFF050508);
  static const Color backgroundSecondary = Color(0xFF0C0C12);
  static const Color backgroundTealDark = Color(0xFF0A1318);
  static const Color backgroundOled = Color(0xFF000000);
  static const Color surfaceCard = Color(0xFF14141E);

  // iOS Apple Music Signature Accent & User Customizable Palette
  static const Color appleRed = Color(0xFFFA233B);
  static const Color appleRedSubtle = Color(0x33FA233B);
  static const Color burntOrange = Color(0xFFFF6B35);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color electricBlue = Color(0xFF007AFF);
  static const Color emerald = Color(0xFF00E676);

  // Dynamic Ambient Glow Blob Colors
  static const Color glowRed = Color(0xFFFA233B);
  static const Color glowPurple = Color(0xFF7B2CBF);
  static const Color glowBlue = Color(0xFF007AFF);
  static const Color glowNeonCyan = Color(0xFF00F5D4);

  // Frosted Glass Colors
  static final Color glassFill = Colors.white.withValues(alpha: 0.08);
  static final Color glassBorder = Colors.white.withValues(alpha: 0.14);
  static final Color glassHighlight = Colors.white.withValues(alpha: 0.20);
  static final Color glassPillBackground =
      const Color(0xFF14191E).withValues(alpha: 0.55);

  // Typography Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textTertiary = Color(0xFF71717A);
  static const Color textAccent = Color(0xFFFA233B);

  // Badges & Accents
  static const Color badgeGold = Color(0xFFFFD166);
  static const Color badgeGreen = Color(0xFF06D6A0);
  static const Color dspActiveGlow = Color(0xFF38EF7D);
}

enum AppThemeMode {
  glassmorphismDark, // Deep Teal / Charcoal base
  pitchBlackOled,    // Pure OLED #000000
  dynamicAlbumArt,   // Glow adapts from currently playing song artwork
  classicObsidian,   // Deep Obsidian #050508
}

enum AccentColorOption {
  appleRed(AppColors.appleRed, 'Apple Red'),
  burntOrange(AppColors.burntOrange, 'Burnt Orange'),
  cyan(AppColors.cyan, 'Cyan'),
  electricBlue(AppColors.electricBlue, 'Electric Blue'),
  emerald(AppColors.emerald, 'Emerald');

  final Color color;
  final String label;
  const AccentColorOption(this.color, this.label);
}

enum LogoStyle {
  officialLogo('Hearable Official', Icons.music_note_rounded),
  acousticWave('Acoustic Wave', Icons.graphic_eq_rounded),
  soundBeats('Sound Pulse', Icons.waves_rounded),
  neonHeadphones('Headphones', Icons.headphones_rounded),
  vinylDisc('Vinyl Record', Icons.album_rounded);

  final String label;
  final IconData icon;
  const LogoStyle(this.label, this.icon);
}
