import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../state/player_provider.dart';
import '../../state/settings_provider.dart';
import 'audio_quality_badge.dart';
import 'full_player_sheet.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final settings = context.watch<SettingsProvider>();
    final accent = settings.activeAccentColor;
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    final isPlaying = player.isPlaying;
    final durationMs = player.duration.inMilliseconds > 0
        ? player.duration.inMilliseconds
        : song.durationMs;
    final positionMs = player.position.inMilliseconds;
    final progress =
        durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: settings.glassBlurSigma,
            sigmaY: settings.glassBlurSigma,
          ),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF14191E).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: settings.borderOpacity),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Bottom progress line
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      height: 2.2,
                      decoration: BoxDecoration(
                        color: accent,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Interactive Content
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _openFullPlayerModal(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        children: [
                          // Small Album Art
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: song.artworkUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: song.artworkUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, _) => Container(
                                        color: const Color(0xFF222230),
                                        child: const Icon(
                                            CupertinoIcons.music_note,
                                            color: Colors.white30,
                                            size: 20),
                                      ),
                                      errorWidget: (context, _, __) =>
                                          Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [AppColors.appleRed, AppColors.glowPurple],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Icon(
                                            CupertinoIcons.music_note_2,
                                            color: Colors.white,
                                            size: 20),
                                      ),
                                    )
                                  : Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [AppColors.appleRed, AppColors.glowPurple],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Icon(
                                          CupertinoIcons.music_note_2,
                                          color: Colors.white,
                                          size: 20),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Title, Artist & 320k badge
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const AudioQualityBadge(
                                        label: '320K', isHiRes: true),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        song.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Controls: Play/Pause & Next
                          IconButton(
                            icon: Icon(
                              isPlaying
                                  ? CupertinoIcons.pause_fill
                                  : CupertinoIcons.play_fill,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () => player.togglePlayPause(),
                          ),
                          IconButton(
                            icon: const Icon(
                              CupertinoIcons.forward_fill,
                              color: Colors.white70,
                              size: 24,
                            ),
                            onPressed: () => player.next(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openFullPlayerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: false,
      builder: (context) {
        return const FullPlayerSheet();
      },
    );
  }
}
