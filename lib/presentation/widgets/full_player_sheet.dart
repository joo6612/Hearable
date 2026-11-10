import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/song_model.dart';
import '../../core/network/saavn_api_service.dart';
import '../../state/player_provider.dart';
import '../../state/settings_provider.dart';
import '../widgets/synced_lyrics_view.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/audio_player_handler.dart';

class FullPlayerSheet extends StatefulWidget {
  const FullPlayerSheet({super.key});

  @override
  State<FullPlayerSheet> createState() => _FullPlayerSheetState();
}

class _FullPlayerSheetState extends State<FullPlayerSheet>
    with SingleTickerProviderStateMixin {
  double _volume = 0.85;
  bool _isDraggingSlider = false;
  double _dragValue = 0.0;
  bool _showLyrics = false;
  String? _lyricsLrc;
  bool _lyricsLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final song = context.read<PlayerProvider>().currentSong;
      if (song != null) _fetchLyrics(song);
    });
  }

  Future<void> _fetchLyrics(SongModel song) async {
    if (_lyricsLoading) return;
    setState(() => _lyricsLoading = true);
    final lrc = await SaavnApiService.getSyncedLyrics(song);
    if (mounted) {
      setState(() {
        _lyricsLrc = lrc;
        _lyricsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final settings = context.watch<SettingsProvider>();
    final accent = settings.activeAccentColor;
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    final dominantColor = player.dominantColor;
    final secondaryColor = player.secondaryColor;
    final isPlaying = player.isPlaying;

    final durationMs = player.duration.inMilliseconds > 0
        ? player.duration.inMilliseconds
        : song.durationMs;
    final positionMs = player.position.inMilliseconds;
    final sliderProgress =
        durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

    final remainingMs = (durationMs - positionMs).clamp(0, durationMs);
    final remainingFormatted = _formatDuration(remainingMs);
    final currentFormatted = _formatDuration(positionMs);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Liquid ambient background (dominant + secondary color blobs) ──
          Positioned.fill(
            child: Container(
              color: settings.currentTheme == AppThemeMode.pitchBlackOled
                  ? AppColors.backgroundOled
                  : AppColors.background,
            ),
          ),
          // Top radial blob
          Positioned(
            top: -120,
            left: -80,
            right: -80,
            height: 500,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    dominantColor.withValues(alpha: 0.65),
                    secondaryColor.withValues(alpha: 0.40),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Bottom blob
          Positioned(
            bottom: -80,
            left: -60,
            right: -60,
            height: 420,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    secondaryColor.withValues(alpha: 0.50),
                    dominantColor.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // Glass blur layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: settings.glassBlurSigma,
                sigmaY: settings.glassBlurSigma,
              ),
              child: Container(
                  color: Colors.black.withValues(alpha: 0.28)),
            ),
          ),

          // ── Main Player Interface ──
          SafeArea(
            child: Column(
              children: [
                // Top: dismiss chevron + song header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.chevron_down,
                            color: Colors.white, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Column(
                        children: [
                          Text(
                            _showLyrics
                                ? 'SYNCED LYRICS'
                                : 'PLAYING FROM QUEUE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.album,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          _showLyrics
                              ? CupertinoIcons.music_albums_fill
                              : CupertinoIcons.quote_bubble_fill,
                          color: _showLyrics ? accent : Colors.white70,
                          size: 22,
                        ),
                        onPressed: () =>
                            setState(() => _showLyrics = !_showLyrics),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Centre: artwork OR live synced karaoke lyrics
                if (!_showLyrics)
                  Center(
                    child: AnimatedScale(
                      scale: isPlaying ? 1.0 : 0.88,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.80,
                        height: MediaQuery.of(context).size.width * 0.80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: dominantColor.withValues(
                                  alpha: isPlaying ? 0.50 : 0.20),
                              blurRadius: isPlaying ? 48 : 20,
                              offset: const Offset(0, 18),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.7),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: song.artworkUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: song.artworkUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (ctx, _) => Container(
                                    color: const Color(0xFF222230),
                                    child: const Center(
                                      child: Icon(
                                          CupertinoIcons.music_note_2,
                                          color: Colors.white38,
                                          size: 48),
                                    ),
                                  ),
                                  errorWidget: (ctx, _, __) => _artworkFallback(accent),
                                )
                              : _artworkFallback(accent),
                        ),
                      ),
                    ),
                  )
                else
                  // Synced karaoke lyrics view
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.40,
                    child: _lyricsLoading
                        ? const Center(
                            child: CupertinoActivityIndicator(
                                color: Colors.white54))
                        : SyncedLyricsView(
                            lrcContent: _lyricsLrc,
                            position: player.position,
                            accent: accent,
                            lyricsAlignment: settings.lyricsAlignment,
                            lyricsFontSize: settings.lyricsFontSize,
                            reflectionGlow: settings.reflectionGlowEnabled,
                            onSeek: (pos) => player.seek(pos),
                          ),
                  ),

                const Spacer(flex: 1),

                // Track title + like
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          player.isCurrentSongLiked
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: player.isCurrentSongLiked
                              ? accent
                              : Colors.white.withValues(alpha: 0.8),
                          size: 26,
                        ),
                        onPressed: () => player.toggleLikeCurrentSong(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Scrub slider + timestamps
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor:
                              Colors.white.withValues(alpha: 0.85),
                          inactiveTrackColor:
                              Colors.white.withValues(alpha: 0.20),
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayColor:
                              Colors.white.withValues(alpha: 0.15),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14),
                          trackHeight: 3.5,
                        ),
                        child: Slider(
                          value: _isDraggingSlider
                              ? _dragValue
                              : sliderProgress.clamp(0.0, 1.0),
                          onChangeStart: (val) => setState(() {
                            _isDraggingSlider = true;
                            _dragValue = val;
                          }),
                          onChanged: (val) =>
                              setState(() => _dragValue = val),
                          onChangeEnd: (val) {
                            setState(() => _isDraggingSlider = false);
                            final targetMs = (val * durationMs).round();
                            player.seek(Duration(milliseconds: targetMs));
                          },
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(currentFormatted,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white
                                        .withValues(alpha: 0.65))),
                            Text('-$remainingFormatted',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white
                                        .withValues(alpha: 0.65))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Playback controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(CupertinoIcons.shuffle,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 22),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.backward_fill,
                            color: Colors.white, size: 36),
                        onPressed: () => player.previous(),
                      ),
                      GestureDetector(
                        onTap: () => player.togglePlayPause(),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.white.withValues(alpha: 0.25),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying
                                ? CupertinoIcons.pause_fill
                                : CupertinoIcons.play_fill,
                            color: Colors.black,
                            size: 34,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.forward_fill,
                            color: Colors.white, size: 36),
                        onPressed: () => player.next(),
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.repeat,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 22),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Volume slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.volume_down,
                          color: Colors.white.withValues(alpha: 0.45),
                          size: 18),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor:
                                Colors.white.withValues(alpha: 0.7),
                            inactiveTrackColor:
                                Colors.white.withValues(alpha: 0.18),
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 4),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: _volume,
                            onChanged: (val) {
                              setState(() => _volume = val);
                              AudioPlayerHandler.instance.setVolume(val);
                            },
                          ),
                        ),
                      ),
                      Icon(CupertinoIcons.volume_up,
                          color: Colors.white.withValues(alpha: 0.45),
                          size: 18),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Output badge + EQ toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.airplay,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Hearable Studio Output',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => player.toggleDspTuning(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: player.isDspTuningEnabled
                                ? AppColors.dspActiveGlow
                                    .withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: player.isDspTuningEnabled
                                  ? AppColors.dspActiveGlow
                                      .withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: player.isDspTuningEnabled
                                      ? AppColors.dspActiveGlow
                                      : Colors.white30,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                player.isDspTuningEnabled
                                    ? 'EQ: On'
                                    : 'EQ: Off (Flat)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: player.isDspTuningEnabled
                                      ? AppColors.dspActiveGlow
                                      : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _artworkFallback(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, AppColors.glowPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(CupertinoIcons.music_note_2,
            color: Colors.white, size: 64),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final totalSeconds = (milliseconds / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
