import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/audio/audio_player_handler.dart';
import '../../core/models/lyrics_model.dart';
import '../../core/theme/app_colors.dart';
import '../../state/player_provider.dart';
import '../../state/settings_provider.dart';

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
  final ScrollController _lyricsScrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void dispose() {
    _lyricsScrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(int activeIndex, int totalLines) {
    if (activeIndex != _lastActiveIndex && _lyricsScrollController.hasClients) {
      _lastActiveIndex = activeIndex;
      const itemHeight = 56.0;
      final targetOffset = (activeIndex * itemHeight) - 120.0;
      _lyricsScrollController.animateTo(
        targetOffset.clamp(0.0, _lyricsScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
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

    // Synced Lyrics Model for current song
    final lyrics = LyricsModel.getCuratedLyrics(song.id, song.title);
    final activeLyricIndex = lyrics.getActiveLineIndex(player.position);
    if (_showLyrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveLine(activeLyricIndex, lyrics.lines.length);
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dynamic ambient color glow extracted via palette_generator
          Positioned.fill(
            child: Container(
              color: settings.currentTheme == AppThemeMode.pitchBlackOled
                  ? AppColors.backgroundOled
                  : AppColors.background,
            ),
          ),
          Positioned(
            top: -100,
            left: -80,
            right: -80,
            height: 480,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    dominantColor.withValues(alpha: 0.55),
                    secondaryColor.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -50,
            right: -50,
            height: 380,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    secondaryColor.withValues(alpha: 0.40),
                    dominantColor.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: settings.glassBlurSigma,
                sigmaY: settings.glassBlurSigma,
              ),
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
          ),

          // Main Interactive Player Interface
          SafeArea(
            child: Column(
              children: [
                // Top Dismiss Chevron & Header Badges
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
                            _showLyrics ? 'SYNCED LYRICS' : 'PLAYING FROM QUEUE',
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
                      // Lyrics / Artwork Toggle Button
                      IconButton(
                        icon: Icon(
                          _showLyrics
                              ? CupertinoIcons.music_albums_fill
                              : CupertinoIcons.quote_bubble_fill,
                          color: _showLyrics ? accent : Colors.white70,
                          size: 22,
                        ),
                        onPressed: () => setState(() => _showLyrics = !_showLyrics),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Center View: Either Bouncing Artwork OR Real-time Synced Lyrics
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
                                  alpha: isPlaying ? 0.45 : 0.20),
                              blurRadius: isPlaying ? 40 : 20,
                              offset: const Offset(0, 16),
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
                                  placeholder: (context, _) => Container(
                                    color: const Color(0xFF222230),
                                    child: const Center(
                                      child: Icon(CupertinoIcons.music_note_2,
                                          color: Colors.white38, size: 48),
                                    ),
                                  ),
                                  errorWidget: (context, _, __) => Container(
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
                                  ),
                                )
                              : Container(
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
                                ),
                        ),
                      ),
                    ),
                  )
                else
                  // Real-time Synced Lyrics (Follow Along)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.38,
                    child: ListView.builder(
                      controller: _lyricsScrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      itemCount: lyrics.lines.length,
                      itemBuilder: (context, idx) {
                        final line = lyrics.lines[idx];
                        final isActive = idx == activeLyricIndex;

                        return GestureDetector(
                          onTap: () {
                            player.seek(line.timestamp);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: AnimatedScale(
                              scale: isActive ? 1.05 : 1.0,
                              alignment: Alignment.centerLeft,
                              duration: const Duration(milliseconds: 200),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isActive ? 1.0 : 0.35,
                                child: Text(
                                  line.text,
                                  textAlign: settings.lyricsAlignment,
                                  style: TextStyle(
                                    fontSize: settings.lyricsFontSize,
                                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                                    letterSpacing: -0.3,
                                    color: Colors.white,
                                    shadows: isActive && settings.reflectionGlowEnabled
                                        ? [
                                            BoxShadow(
                                              color: accent.withValues(alpha: 0.8),
                                              blurRadius: 18,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const Spacer(flex: 1),

                // Track Title, Artist & Like/Favorite
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

                // Scrub Progress Slider & Timestamps
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Colors.white.withValues(alpha: 0.85),
                          inactiveTrackColor:
                              Colors.white.withValues(alpha: 0.20),
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayColor: Colors.white.withValues(alpha: 0.15),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 14),
                          trackHeight: 3.5,
                        ),
                        child: Slider(
                          value: _isDraggingSlider
                              ? _dragValue
                              : sliderProgress.clamp(0.0, 1.0),
                          onChangeStart: (val) {
                            setState(() {
                              _isDraggingSlider = true;
                              _dragValue = val;
                            });
                          },
                          onChanged: (val) {
                            setState(() {
                              _dragValue = val;
                            });
                          },
                          onChangeEnd: (val) {
                            setState(() {
                              _isDraggingSlider = false;
                            });
                            final targetMs = (val * durationMs).round();
                            player.seek(Duration(milliseconds: targetMs));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentFormatted,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                            Text(
                              '-$remainingFormatted',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // iOS Playback Controls (Shuffle, Previous, Play/Pause, Next, Repeat)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.shuffle,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 22,
                        ),
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
                                color: Colors.white.withValues(alpha: 0.25),
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
                        icon: Icon(
                          CupertinoIcons.repeat,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 22,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Volume Slider with Apple Icons
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

                // Output Badges & DSP Signature Switch
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // AirPlay / Speaker Output Badge
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

                      // Hardware DSP Tuning Toggle Pill
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
                                    ? 'Apple DSP: Active (+3.5dB)'
                                    : 'Apple DSP: Off',
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

  String _formatDuration(int milliseconds) {
    final totalSeconds = (milliseconds / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
