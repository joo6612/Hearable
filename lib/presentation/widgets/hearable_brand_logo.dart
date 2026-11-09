import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../state/settings_provider.dart';

class HearableBrandLogo extends StatefulWidget {
  final double size;

  const HearableBrandLogo({
    super.key,
    this.size = 44,
  });

  @override
  State<HearableBrandLogo> createState() => _HearableBrandLogoState();
}

class _HearableBrandLogoState extends State<HearableBrandLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showCustomizerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return const _BrandThemeStudioSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final accent = settings.activeAccentColor;

    return GestureDetector(
      onTap: () => _showCustomizerSheet(context),
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final pulse = 0.8 + (_animController.value * 0.35);
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35 * pulse),
                  blurRadius: 16 * pulse,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size / 2),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: settings.glassBlurSigma,
                  sigmaY: settings.glassBlurSigma,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.45),
                        const Color(0xFF141920).withValues(alpha: 0.85),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: settings.borderOpacity + 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: settings.logoStyle == LogoStyle.officialLogo
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(widget.size / 2),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              width: widget.size,
                              height: widget.size,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            settings.logoStyle.icon,
                            color: Colors.white,
                            size: widget.size * 0.52,
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BrandThemeStudioSheet extends StatelessWidget {
  const _BrandThemeStudioSheet();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final accent = settings.activeAccentColor;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF141920).withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(settings.logoStyle.icon, color: accent, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Hearable Brand Studio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white38),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Logo Style Selection
              const Text(
                'Logo Glyph Style',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: LogoStyle.values.map((style) {
                  final isSel = settings.logoStyle == style;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => settings.setLogoStyle(style),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? accent.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel ? accent : Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Column(
                            children: [
                              style == LogoStyle.officialLogo
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.asset(
                                        'assets/images/app_logo.png',
                                        width: 20,
                                        height: 20,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(style.icon, color: isSel ? Colors.white : Colors.white60, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                style.label.split(' ').first,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? Colors.white : Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Accent Color Quick Switch
              const Text(
                'Brand Accent Color',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: AccentColorOption.values.map((option) {
                  final isSel = settings.accentColor == option;
                  return GestureDetector(
                    onTap: () => settings.setAccentColor(option),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: option.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: option.color.withValues(alpha: isSel ? 0.6 : 0.2),
                            blurRadius: isSel ? 12 : 4,
                          ),
                        ],
                      ),
                      child: isSel ? const Icon(CupertinoIcons.checkmark, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Glass Blur Sigma Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Glass Blur Intensity',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${settings.glassBlurSigma.toInt()}px',
                    style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: accent,
                  inactiveTrackColor: Colors.white12,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: settings.glassBlurSigma,
                  min: 10.0,
                  max: 30.0,
                  onChanged: (v) => settings.setGlassBlurSigma(v),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

