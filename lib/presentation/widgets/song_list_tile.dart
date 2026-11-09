import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/song_model.dart';
import '../../core/theme/app_colors.dart';
import '../../state/player_provider.dart';
import 'audio_quality_badge.dart';

class SongListTile extends StatelessWidget {
  final SongModel song;
  final List<SongModel>? queue;
  final int? index;
  final VoidCallback? onPlay;

  const SongListTile({
    super.key,
    required this.song,
    this.queue,
    this.index,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isCurrent = player.currentSong?.id == song.id;
    final isPlaying = isCurrent && player.isPlaying;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.appleRed.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isCurrent
            ? Border.all(
                color: AppColors.appleRed.withValues(alpha: 0.28), width: 1.0)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (onPlay != null) {
              onPlay!();
            } else {
              player.playSong(song, queue: queue, index: index);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Album Artwork with active play animation overlay
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 52,
                        height: 52,
                        color: const Color(0xFF1B1B26),
                        child: song.artworkUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: song.artworkUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, _) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF20202F), Color(0xFF14141E)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(CupertinoIcons.music_note, color: Colors.white24, size: 22),
                                  ),
                                ),
                                errorWidget: (context, _, __) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.glowPurple.withValues(alpha: 0.6),
                                        AppColors.appleRed.withValues(alpha: 0.4),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(CupertinoIcons.music_note_2, color: Colors.white70, size: 22),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.glowPurple.withValues(alpha: 0.6),
                                      AppColors.appleRed.withValues(alpha: 0.4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(CupertinoIcons.music_note_2, color: Colors.white70, size: 22),
                                ),
                              ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPlaying
                              ? CupertinoIcons.pause_fill
                              : CupertinoIcons.play_fill,
                          color: AppColors.appleRed,
                          size: 24,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Title & Artist Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: isCurrent
                              ? AppColors.appleRed
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const AudioQualityBadge(label: '320K', isHiRes: true),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Duration & Ellipsis Menu
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.durationFormatted,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(CupertinoIcons.ellipsis,
                          size: 18, color: AppColors.textSecondary),
                      splashRadius: 20,
                      onPressed: () => _showSongOptionsMenu(context, song),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSongOptionsMenu(BuildContext context, SongModel song) {
    final player = context.read<PlayerProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF161622),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: song.artworkUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: song.artworkUrl, fit: BoxFit.cover)
                          : Container(color: Colors.white10),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              ListTile(
                leading: Icon(
                  song.isLiked
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  color: song.isLiked ? AppColors.appleRed : Colors.white,
                ),
                title: Text(
                    song.isLiked ? 'Remove from Liked' : 'Add to Liked Tracks'),
                onTap: () {
                  player.toggleLike(song);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading:
                    const Icon(CupertinoIcons.play_circle, color: Colors.white),
                title: const Text('Play Immediately (320kbps Stream)'),
                onTap: () {
                  Navigator.pop(context);
                  player.playSong(song);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.slider_horizontal_3,
                    color: AppColors.dspActiveGlow),
                title: const Text('Hardware DSP Signature Tuning'),
                subtitle: const Text('60Hz +3.5dB Bass & 50% Spatial Stereo',
                    style: TextStyle(fontSize: 11, color: Colors.white54)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
