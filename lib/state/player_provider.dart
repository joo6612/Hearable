import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import '../core/audio/audio_player_handler.dart';
import '../core/audio/dsp_tuning_service.dart';
import '../core/models/song_model.dart';
import '../core/network/party_sync_service.dart';
import '../core/theme/app_colors.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayerHandler _audioHandler = AudioPlayerHandler.instance;
  final PartySyncService _partyService = PartySyncService.instance;

  SongModel? _currentSong;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  List<SongModel> _queue = [];
  int _currentIndex = 0;

  final List<SongModel> _likedSongs = [];
  final List<SongModel> _historySongs = [];

  bool _isDspTuningEnabled = true;
  Color _dominantColor = AppColors.appleRed;
  Color _secondaryColor = AppColors.glowPurple;

  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _syncSub;

  SongModel? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  List<SongModel> get queue => _queue;
  int get currentIndex => _currentIndex;
  List<SongModel> get likedSongs => _likedSongs;
  List<SongModel> get historySongs => _historySongs;
  bool get isCurrentSongLiked =>
      _currentSong != null && _likedSongs.any((s) => s.id == _currentSong!.id);
  bool get isDspTuningEnabled => _isDspTuningEnabled;
  Color get dominantColor => _dominantColor;
  Color get secondaryColor => _secondaryColor;

  PlayerProvider() {
    _initListeners();
  }

  void _initListeners() {
    _playerStateSub = _audioHandler.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isBuffering = state.processingState == ProcessingState.buffering;

      if (state.processingState == ProcessingState.completed) {
        next();
      }
      notifyListeners();
    });

    _positionSub = _audioHandler.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durationSub = _audioHandler.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    // Listen to Party sync events if this device is connected as Client
    _syncSub = _partyService.onSyncEvent.listen((event) async {
      if (_partyService.isClient) {
        _handleClientSyncEvent(event);
      }
    });
  }

  Future<void> _handleClientSyncEvent(PartySyncEvent event) async {
    try {
      if (_currentSong?.id != event.song.id) {
        _currentSong = event.song;
        _extractPalette(event.song.artworkUrl);
        await _audioHandler.playSong(
          event.song,
          initialSeek: Duration(milliseconds: event.targetSeekMs),
        );
      } else {
        // Same song, update seek or play/pause state
        final currentPosMs = _audioHandler.position.inMilliseconds;
        final diff = (currentPosMs - event.targetSeekMs).abs();
        if (diff > 250) {
          await _audioHandler.seek(Duration(milliseconds: event.targetSeekMs));
        }
      }

      if (event.isPlaying && !_audioHandler.isPlaying) {
        await _audioHandler.resume();
      } else if (!event.isPlaying && _audioHandler.isPlaying) {
        await _audioHandler.pause();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error applying sync event: $e');
    }
  }

  /// Play a song with optional queue & index
  Future<void> playSong(SongModel song, {List<SongModel>? queue, int? index}) async {
    _currentSong = song;
    if (queue != null && queue.isNotEmpty) {
      _queue = List.from(queue);
      _currentIndex = index ?? _queue.indexWhere((s) => s.id == song.id);
      if (_currentIndex < 0) _currentIndex = 0;
    } else if (!_queue.any((s) => s.id == song.id)) {
      _queue.insert(0, song);
      _currentIndex = 0;
    }

    // Add to history
    if (!_historySongs.any((s) => s.id == song.id)) {
      _historySongs.insert(0, song);
    }

    _extractPalette(song.artworkUrl);
    notifyListeners();

    try {
      await _audioHandler.playSong(song);

      // If this device is Party Host, broadcast SYNC_PLAY
      if (_partyService.isHost) {
        _partyService.broadcastPlaybackSync(
          action: 'SYNC_PLAY',
          song: song,
          seekPositionMs: 0,
        );
      }
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentSong == null) {
      if (_queue.isNotEmpty) {
        await playSong(_queue.first);
      }
      return;
    }

    if (_isPlaying) {
      await _audioHandler.pause();
      if (_partyService.isHost && _currentSong != null) {
        _partyService.broadcastPlaybackSync(
          action: 'SYNC_PAUSE',
          song: _currentSong!,
          seekPositionMs: _position.inMilliseconds,
        );
      }
    } else {
      await _audioHandler.resume();
      if (_partyService.isHost && _currentSong != null) {
        _partyService.broadcastPlaybackSync(
          action: 'SYNC_PLAY',
          song: _currentSong!,
          seekPositionMs: _position.inMilliseconds,
        );
      }
    }
    notifyListeners();
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await playSong(_queue[_currentIndex]);
    } else {
      // Loop back to start
      _currentIndex = 0;
      await playSong(_queue[0]);
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
      await playSong(_queue[_currentIndex]);
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> seek(Duration targetPosition) async {
    await _audioHandler.seek(targetPosition);
    if (_partyService.isHost && _currentSong != null) {
      _partyService.broadcastPlaybackSync(
        action: 'SYNC_SEEK',
        song: _currentSong!,
        seekPositionMs: targetPosition.inMilliseconds,
      );
    }
  }

  void toggleLikeCurrentSong() {
    if (_currentSong != null) {
      toggleLike(_currentSong!);
    }
  }

  void toggleLike(SongModel song) {
    song.isLiked = !song.isLiked;
    if (song.isLiked) {
      if (!_likedSongs.any((s) => s.id == song.id)) {
        _likedSongs.insert(0, song);
      }
    } else {
      _likedSongs.removeWhere((s) => s.id == song.id);
    }
    notifyListeners();
  }

  /// Toggle Hardware DSP Tuning (Apple Signature Equalizer + BassBoost + Virtualizer)
  Future<void> toggleDspTuning() async {
    _isDspTuningEnabled = !_isDspTuningEnabled;
    await DspTuningService.applyAppleSignatureTuning(_isDspTuningEnabled);
    notifyListeners();
  }

  /// Extract dynamic ambient color glow from album artwork using PaletteGenerator
  Future<void> _extractPalette(String artworkUrl) async {
    if (artworkUrl.isEmpty) {
      _dominantColor = AppColors.appleRed;
      _secondaryColor = AppColors.glowPurple;
      notifyListeners();
      return;
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(artworkUrl),
        maximumColorCount: 16,
      ).timeout(const Duration(seconds: 4));

      _dominantColor = palette.dominantColor?.color ?? palette.vibrantColor?.color ?? AppColors.appleRed;
      _secondaryColor = palette.mutedColor?.color ?? palette.darkVibrantColor?.color ?? AppColors.glowPurple;
      notifyListeners();
    } catch (e) {
      // Graceful fallback to signature Apple Obsidian glow
      _dominantColor = AppColors.appleRed;
      _secondaryColor = AppColors.glowPurple;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _syncSub?.cancel();
    super.dispose();
  }
}

