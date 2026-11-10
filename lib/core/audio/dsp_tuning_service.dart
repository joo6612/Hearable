import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pure natural-sound bit-perfect DSP service.
/// DSP effects are opt-in only via the 5-band graphic EQ in Settings.
/// Default state: clean, unprocessed 320kbps M4A passthrough.
class DspTuningService {
  static const MethodChannel _channel =
      MethodChannel('com.hearable.music/audio_effects');

  static bool _isTuningEnabled = false; // DEFAULT: clean/flat (bit-perfect)
  static int _bassStrength = 0;
  static int _virtualizerStrength = 0;
  static int? _activeSessionId;

  static bool get isTuningEnabled => _isTuningEnabled;
  static int get bassStrength => _bassStrength;
  static int get virtualizerStrength => _virtualizerStrength;
  static int? get activeSessionId => _activeSessionId;

  /// Initialize native effects (but do NOT auto-apply any boost – flat pass)
  static Future<void> initEffects(int? sessionId) async {
    try {
      _activeSessionId = sessionId;
      await _channel.invokeMethod('initEffects', {
        'sessionId': sessionId ?? 0,
      });
      // Apply current state without forcing pre-amp on
      if (_isTuningEnabled) {
        await applyEqPreset(enabled: true);
      }
    } on PlatformException catch (e) {
      debugPrint('DspTuningService initEffects error: ${e.message}');
    } catch (e) {
      debugPrint('Error initializing DSP audio effects: $e');
    }
  }

  /// Apply EQ preset. When disabled, all bands set to 0dB (flat / bit-perfect).
  static Future<bool> applyEqPreset({
    bool enabled = false,
    int bassBoostStrength = 0,
    int virtualizerStrengthVal = 0,
    Map<String, double> bandGains = const {},
  }) async {
    _isTuningEnabled = enabled;
    _bassStrength = enabled ? bassBoostStrength : 0;
    _virtualizerStrength = enabled ? virtualizerStrengthVal : 0;

    try {
      final res = await _channel.invokeMethod<bool>('setAppleSignatureTuning', {
        'enabled': enabled,
        'bassStrength': _bassStrength,
        'virtualizerStrength': _virtualizerStrength,
        'bandGains': bandGains,
      });
      return res ?? false;
    } on PlatformException catch (e) {
      debugPrint('DspTuningService applyEqPreset error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error applying EQ preset: $e');
      return false;
    }
  }

  // Keep backward-compat signature for PlayerProvider toggle
  static Future<bool> applyAppleSignatureTuning(bool enabled,
      {int? bassStrength, int? virtualizerStrength}) async {
    return applyEqPreset(
      enabled: enabled,
      bassBoostStrength: bassStrength ?? 0,
      virtualizerStrengthVal: virtualizerStrength ?? 0,
    );
  }

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

  static Future<Map<String, dynamic>> getEffectsState() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getAudioEffectsState');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      debugPrint('Error getting audio effects state: $e');
    }
    return {};
  }

  static Future<void> releaseEffects() async {
    try {
      await _channel.invokeMethod('releaseEffects');
    } catch (e) {
      debugPrint('Error releasing audio effects: $e');
    }
  }
}
