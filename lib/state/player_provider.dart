import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import '../core/audio/audio_player_handler.dart';
import '../core/audio/dsp_tuning_service.dart';
import '../core/models/song_model.dart';
import '../core/network/party_sync_service.dart';
import '../core/network/saavn_api_service.dart';
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

  bool _isDspTuningEnabled = false; // DEFAULT: clean flat output
  Color _dominantColor = AppColors.appleRed;
  Color _secondaryColor = AppColors.glowPurple;

  bool _isLoadingRecommendations = false;

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
      _currentSong != null &&
      _likedSongs.any((s) => s.id == _currentSong!.id);
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

  Future<void> playSong(SongModel song,
      {List<SongModel>? queue, int? index}) async {
    _currentSong = song;
    if (queue != null && queue.isNotEmpty) {
      _queue = List.from(queue);
      _currentIndex = index ?? _queue.indexWhere((s) => s.id == song.id);
      if (_currentIndex < 0) _currentIndex = 0;
    } else if (!_queue.any((s) => s.id == song.id)) {
      _queue.insert(0, song);
      _currentIndex = 0;
    }

    if (!_historySongs.any((s) => s.id == song.id)) {
      _historySongs.insert(0, song);
    }

    _extractPalette(song.artworkUrl);
    notifyListeners();

    try {
      await _audioHandler.playSong(song);

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
      if (_queue.isNotEmpty) await playSong(_queue.first);
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

  /// Advance to next track; auto-fetch recommendations when queue is nearly exhausted
  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await playSong(_queue[_currentIndex]);
    } else {
      // End of queue – trigger infinite radio queue auto-extension
      await _extendQueueWithRecommendations();
      if (_currentIndex < _queue.length - 1) {
        _currentIndex++;
        await playSong(_queue[_currentIndex]);
      } else {
        // Last resort loop
        _currentIndex = 0;
        await playSong(_queue[0]);
      }
    }
  }

  /// Append 15-20 recommended tracks to queue without interrupting playback
  Future<void> _extendQueueWithRecommendations() async {
    if (_isLoadingRecommendations) return;
    _isLoadingRecommendations = true;
    try {
      final song = _currentSong;
      if (song == null) return;

      final recommendations = await SaavnApiService.getSongRecommendations(
        song.id,
        artistName: song.artist,
        limit: 20,
      );

      // Deduplicate – do not add songs already in queue
      final existingIds = _queue.map((s) => s.id).toSet();
      final newSongs = recommendations
          .where((s) => !existingIds.contains(s.id))
          .toList();

      if (newSongs.isNotEmpty) {
        _queue.addAll(newSongs);
        notifyListeners();
        debugPrint('Auto-queue extended with ${newSongs.length} recommendations');
      }
    } catch (e) {
      debugPrint('Error extending queue: $e');
    } finally {
      _isLoadingRecommendations = false;
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
    if (_currentSong != null) toggleLike(_currentSong!);
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

  /// Toggle the 5-band graphic EQ (default: flat / off)
  Future<void> toggleDspTuning() async {
    _isDspTuningEnabled = !_isDspTuningEnabled;
    await DspTuningService.applyAppleSignatureTuning(_isDspTuningEnabled);
    notifyListeners();
  }

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
      _dominantColor =
          palette.dominantColor?.color ?? palette.vibrantColor?.color ?? AppColors.appleRed;
      _secondaryColor =
          palette.mutedColor?.color ?? palette.darkVibrantColor?.color ?? AppColors.glowPurple;
      notifyListeners();
    } catch (e) {
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
