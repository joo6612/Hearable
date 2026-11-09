import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AudioQualityBadge extends StatelessWidget {
  final String label;
  final bool isHiRes;
  final bool showDspIndicator;

  const AudioQualityBadge({
    super.key,
    this.label = '320 KBPS',
    this.isHiRes = true,
    this.showDspIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHiRes
              ? AppColors.badgeGold.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDspIndicator) ...[
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 4),
              decoration: const BoxDecoration(
                color: AppColors.dspActiveGlow,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isHiRes ? AppColors.badgeGold : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
