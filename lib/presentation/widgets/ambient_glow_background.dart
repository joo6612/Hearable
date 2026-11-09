import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../state/player_provider.dart';
import '../../state/settings_provider.dart';

class AmbientGlowBackground extends StatefulWidget {
  final Widget? child;
  const AmbientGlowBackground({super.key, this.child});

  @override
  State<AmbientGlowBackground> createState() => _AmbientGlowBackgroundState();
}

class _AmbientGlowBackgroundState extends State<AmbientGlowBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final settings = context.watch<SettingsProvider>();

    final isOled = settings.currentTheme == AppThemeMode.pitchBlackOled;
    final isTealDark = settings.currentTheme == AppThemeMode.glassmorphismDark;
    final isDynamic = settings.currentTheme == AppThemeMode.dynamicAlbumArt;

    final primaryAccent = isDynamic ? player.dominantColor : settings.activeAccentColor;
    final secondaryAccent = isDynamic ? player.secondaryColor : AppColors.glowPurple;

    final baseBackground = isOled
        ? AppColors.backgroundOled
        : isTealDark
            ? AppColors.backgroundTealDark
            : AppColors.background;

    return Stack(
      children: [
        // AMOLED Obsidian / Pitch Black / Deep Teal Base
        Container(color: baseBackground),

        // Layered animated blurred blobs with high-efficiency radial falloff
        if (!isOled || settings.reflectionGlowEnabled)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final val = _controller.value;
                return Stack(
                  children: [
                    // Blob 1: Top-Right (Dynamic dominant / Accent)
                    Positioned(
                      top: -100 + (val * 40),
                      right: -70 + (val * 30),
                      child: Container(
                        width: 360,
                        height: 360,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              primaryAccent.withValues(alpha: isOled ? 0.20 : 0.35),
                              primaryAccent.withValues(alpha: isOled ? 0.08 : 0.18),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Blob 2: Mid-Left (Secondary / Purple)
                    Positioned(
                      top: 220 - (val * 45),
                      left: -90 + (val * 35),
                      child: Container(
                        width: 380,
                        height: 380,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              secondaryAccent.withValues(alpha: isOled ? 0.16 : 0.30),
                              AppColors.glowPurple.withValues(alpha: isOled ? 0.08 : 0.16),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Blob 3: Bottom-Right (#007AFF Blue / Neon Cyan)
                    Positioned(
                      bottom: 40 + (val * 35),
                      right: -70 + (val * 30),
                      child: Container(
                        width: 360,
                        height: 360,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.glowBlue.withValues(alpha: isOled ? 0.14 : 0.25),
                              AppColors.glowNeonCyan.withValues(alpha: isOled ? 0.06 : 0.12),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // Child content sitting in front of the ambient glow
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
