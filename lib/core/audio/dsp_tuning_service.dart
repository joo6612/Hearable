import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DspTuningService {
  static const MethodChannel _channel = MethodChannel('com.hearable.music/audio_effects');

  static bool _isTuningEnabled = true;
  static int _bassStrength = 700;
  static int _virtualizerStrength = 500;
  static int? _activeSessionId;

  static bool get isTuningEnabled => _isTuningEnabled;
  static int get bassStrength => _bassStrength;
  static int get virtualizerStrength => _virtualizerStrength;
  static int? get activeSessionId => _activeSessionId;

  /// Initialize native Equalizer, BassBoost, and Virtualizer effects on the player's audioSessionId
  static Future<void> initEffects(int? sessionId) async {
    try {
      _activeSessionId = sessionId;
      await _channel.invokeMethod('initEffects', {
        'sessionId': sessionId ?? 0,
      });

      // Apply initial Apple Signature Tuning preset automatically if enabled
      if (_isTuningEnabled) {
        await applyAppleSignatureTuning(true);
      }
    } on PlatformException catch (e) {
      debugPrint('PlatformException in DspTuningService.initEffects: ${e.message}');
    } catch (e) {
      debugPrint('Error initializing DSP audio effects: $e');
    }
  }

  /// Apply Apple Signature Hardware Tuning Preset:
  /// - 60Hz Sub-Bass: +3.5dB
  /// - 250Hz Warmth: +1.5dB
  /// - 1kHz Mids: -1.0dB
  /// - 4kHz Presence: +2.0dB
  /// - 12kHz Treble: +3.0dB
  /// - Hardware Virtualizer: 50% strength (500)
  /// - BassBoost: 700 strength
  static Future<bool> applyAppleSignatureTuning(
    bool enabled, {
    int? bassStrength,
    int? virtualizerStrength,
  }) async {
    _isTuningEnabled = enabled;
    if (bassStrength != null) _bassStrength = bassStrength;
    if (virtualizerStrength != null) _virtualizerStrength = virtualizerStrength;

    try {
      final res = await _channel.invokeMethod<bool>('setAppleSignatureTuning', {
        'enabled': enabled,
        'bassStrength': _bassStrength,
        'virtualizerStrength': _virtualizerStrength,
      });
      return res ?? false;
    } on PlatformException catch (e) {
      debugPrint('PlatformException in applyAppleSignatureTuning: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error applying Apple Signature Tuning: $e');
      return false;
    }
  }

  /// Set Bass Boost level (0 to 1000)
  static Future<void> setBassBoost(bool enabled, int strength) async {
    _bassStrength = strength;
    try {
      await _channel.invokeMethod('setBassBoost', {
        'enabled': enabled,
        'strength': strength,
      });
    } catch (e) {
      debugPrint('Error setting BassBoost: $e');
    }
  }

  /// Set Hardware Virtualizer Stereo Expansion level (0 to 1000)
  static Future<void> setVirtualizer(bool enabled, int strength) async {
    _virtualizerStrength = strength;
    try {
      await _channel.invokeMethod('setVirtualizer', {
        'enabled': enabled,
        'strength': strength,
      });
    } catch (e) {
      debugPrint('Error setting Virtualizer: $e');
    }
  }

  /// Query native equalizer bands & levels
  static Future<Map<String, dynamic>> getEffectsState() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getAudioEffectsState');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      debugPrint('Error getting audio effects state: $e');
    }
    return {};
  }

  /// Release native effects
  static Future<void> releaseEffects() async {
    try {
      await _channel.invokeMethod('releaseEffects');
    } catch (e) {
      debugPrint('Error releasing audio effects: $e');
    }
  }
}

