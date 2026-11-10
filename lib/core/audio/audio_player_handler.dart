import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song_model.dart';

class AudioPlayerHandler {
  static final AudioPlayerHandler instance = AudioPlayerHandler._();
  AudioPlayerHandler._();

  final AudioPlayer _player = AudioPlayer();
  AudioSession? _session;
  SongModel? _currentSong;
  bool _isInitialized = false;

  AudioPlayer get player => _player;
  SongModel? get currentSong => _currentSong;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<double> get volumeStream => _player.volumeStream;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _session = await AudioSession.instance;
      await _session!.configure(const AudioSessionConfiguration.music());
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing AudioSession: $e');
    }
  }

  /// Play a song from direct 320kbps URL with lock-screen / notification metadata
  Future<void> playSong(SongModel song, {Duration? initialSeek}) async {
    await initialize();
    _currentSong = song;

    try {
      final streamUrl = song.audioUrl320;
      if (streamUrl.isEmpty) {
        throw Exception('Audio URL is empty for track: ${song.title}');
      }

      await _player.stop();

      // Build MediaItem for lock-screen notification with artwork & metadata
      final mediaItem = MediaItem(
        id: streamUrl,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: Duration(milliseconds: song.durationMs),
        artUri: song.artworkUrl.isNotEmpty ? Uri.parse(song.artworkUrl) : null,
        extras: {'quality': song.quality},
      );

      final audioSource = AudioSource.uri(
        Uri.parse(streamUrl),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': '*/*',
        },
        tag: mediaItem,
      );

      await _player.setAudioSource(audioSource);

      if (initialSeek != null) {
        await _player.seek(initialSeek);
      }

      await _player.play();
    } catch (e) {
      debugPrint('Error playing song ${song.title}: $e');
      rethrow;
    }
  }

  Future<void> resume() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint('Error resuming playback: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('Error pausing playback: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error seeking playback: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
