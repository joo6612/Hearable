import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CustomEqPreset {
  final String name;
  final Map<String, double> bandGains;

  const CustomEqPreset({
    required this.name,
    required this.bandGains,
  });
}

class SettingsProvider extends ChangeNotifier {
  // --- Section A: Audio & Equalizer (Core) ---
  bool _eqEnabled = true;
  double _preamp = 0.0; // -12dB to +12dB
  double _bass = 3.5;   // -10dB to +10dB
  double _treble = 3.0; // -10dB to +10dB
  double _balance = 0.0; // -1.0 (Left) to +1.0 (Right)

  int _eqBandCount = 5; // 5, 10, 15, 31 bands
  String _selectedPreset = 'Bass Boost'; // Flat, Bass Boost, Vocal, Rock, Pop, Electronic, Custom
  final List<CustomEqPreset> _savedCustomPresets = [];

  // Band frequencies and their gains in dB (-12.0 to +12.0)
  final Map<int, List<String>> _bandFrequencies = {
    5: ['60Hz', '250Hz', '1kHz', '4kHz', '12kHz'],
    10: ['31Hz', '62Hz', '125Hz', '250Hz', '500Hz', '1kHz', '2kHz', '4kHz', '8kHz', '16kHz'],
    15: ['25Hz', '40Hz', '63Hz', '100Hz', '160Hz', '250Hz', '400Hz', '630Hz', '1kHz', '1.6kHz', '2.5kHz', '4kHz', '6.3kHz', '10kHz', '16kHz'],
    31: [
      '20Hz', '25Hz', '31Hz', '40Hz', '50Hz', '63Hz', '80Hz', '100Hz', '125Hz', '160Hz',
      '200Hz', '250Hz', '315Hz', '400Hz', '500Hz', '630Hz', '800Hz', '1kHz', '1.25kHz', '1.6kHz',
      '2kHz', '2.5kHz', '3.15kHz', '4kHz', '5kHz', '6.3kHz', '8kHz', '10kHz', '12.5kHz', '16kHz', '20kHz'
    ],
  };

  final Map<String, double> _currentBandGains = {
    '60Hz': 3.5,
    '250Hz': 1.5,
    '1kHz': -1.0,
    '4kHz': 2.0,
    '12kHz': 3.0,
  };

  // Streaming & Quality
  String _streamingQuality = '320kbps'; // 96kbps, 160kbps, 320kbps
  bool _replayGainEnabled = true; // Audio normalization
  double _crossfadeDuration = 3.0; // 0s - 12s

  // --- Section B: Appearance & Glossy UI ---
  AppThemeMode _currentTheme = AppThemeMode.glassmorphismDark;
  AccentColorOption _accentColor = AccentColorOption.appleRed;
  LogoStyle _logoStyle = LogoStyle.acousticWave;
  double _glassBlurSigma = 24.0; // 10px - 30px
  double _borderOpacity = 0.14; // 0.05 - 0.30
  bool _reflectionGlowEnabled = true;

  // --- Section C: Library & Storage ---
  String _downloadStoragePath = '/storage/emulated/0/Music/Hearable';
  bool _autoScanLocalAudio = true;
  double _downloadCacheSizeMb = 184.2;

  // --- Section D: Lyrics & Display ---
  String _lyricsProvider = 'LRCLIB'; // LRCLIB, Musixmatch, Genius
  bool _syncedLyricsEnabled = true;
  bool _karaokeFollowMode = true;
  double _lyricsFontSize = 22.0; // 18, 22, 28
  TextAlign _lyricsAlignment = TextAlign.center;
  bool _screenWakeLock = true;

  // Getters
  bool get eqEnabled => _eqEnabled;
  double get preamp => _preamp;
  double get bass => _bass;
  double get treble => _treble;
  double get balance => _balance;
  int get eqBandCount => _eqBandCount;
  String get selectedPreset => _selectedPreset;
  List<CustomEqPreset> get savedCustomPresets => _savedCustomPresets;
  List<String> get currentFrequencies => _bandFrequencies[_eqBandCount] ?? _bandFrequencies[5]!;
  Map<String, double> get currentBandGains => _currentBandGains;

  String get streamingQuality => _streamingQuality;
  bool get replayGainEnabled => _replayGainEnabled;
  double get crossfadeDuration => _crossfadeDuration;

  AppThemeMode get currentTheme => _currentTheme;
  AccentColorOption get accentColor => _accentColor;
  Color get activeAccentColor => _accentColor.color;
  LogoStyle get logoStyle => _logoStyle;
  double get glassBlurSigma => _glassBlurSigma;
  double get borderOpacity => _borderOpacity;
  bool get reflectionGlowEnabled => _reflectionGlowEnabled;

  String get downloadStoragePath => _downloadStoragePath;
  bool get autoScanLocalAudio => _autoScanLocalAudio;
  double get downloadCacheSizeMb => _downloadCacheSizeMb;

  String get lyricsProvider => _lyricsProvider;
  bool get syncedLyricsEnabled => _syncedLyricsEnabled;
  bool get karaokeFollowMode => _karaokeFollowMode;
  double get lyricsFontSize => _lyricsFontSize;
  TextAlign get lyricsAlignment => _lyricsAlignment;
  bool get screenWakeLock => _screenWakeLock;

  // --- Mutators ---
  void setEqEnabled(bool val) {
    _eqEnabled = val;
    notifyListeners();
  }

  void setPreamp(double val) {
    _preamp = val;
    notifyListeners();
  }

  void setBass(double val) {
    _bass = val;
    notifyListeners();
  }

  void setTreble(double val) {
    _treble = val;
    notifyListeners();
  }

  void setBalance(double val) {
    _balance = val;
    notifyListeners();
  }

  void setEqBandCount(int count) {
    if (_bandFrequencies.containsKey(count)) {
      _eqBandCount = count;
      // Initialize any missing band gains to 0.0
      for (final freq in _bandFrequencies[count]!) {
        _currentBandGains.putIfAbsent(freq, () => 0.0);
      }
      notifyListeners();
    }
  }

  void setBandGain(String frequency, double gain) {
    _currentBandGains[frequency] = gain.clamp(-12.0, 12.0);
    _selectedPreset = 'Custom';
    notifyListeners();
  }

  double getBandGain(String frequency) {
    return _currentBandGains[frequency] ?? 0.0;
  }

  void applyPreset(String presetName) {
    _selectedPreset = presetName;
    switch (presetName) {
      case 'Flat':
        _currentBandGains.updateAll((key, val) => 0.0);
        break;
      case 'Bass Boost':
        _currentBandGains.updateAll((key, val) {
          if (key.contains('Hz') && !key.contains('k')) {
            return 4.0;
          }
          return 0.0;
        });
        _currentBandGains['60Hz'] = 5.0;
        _currentBandGains['31Hz'] = 4.5;
        break;
      case 'Vocal':
        _currentBandGains.updateAll((key, val) => -1.0);
        _currentBandGains['1kHz'] = 2.5;
        _currentBandGains['2kHz'] = 3.0;
        _currentBandGains['4kHz'] = 2.0;
        break;
      case 'Rock':
        _currentBandGains.updateAll((key, val) => 0.0);
        _currentBandGains['60Hz'] = 4.0;
        _currentBandGains['250Hz'] = 2.0;
        _currentBandGains['1kHz'] = -1.5;
        _currentBandGains['4kHz'] = 2.5;
        _currentBandGains['12kHz'] = 3.5;
        break;
      case 'Pop':
        _currentBandGains.updateAll((key, val) => 0.0);
        _currentBandGains['60Hz'] = 2.5;
        _currentBandGains['250Hz'] = 1.0;
        _currentBandGains['1kHz'] = 1.0;
        _currentBandGains['4kHz'] = 2.0;
        _currentBandGains['12kHz'] = 2.5;
        break;
      case 'Electronic':
        _currentBandGains.updateAll((key, val) => 0.0);
        _currentBandGains['60Hz'] = 4.5;
        _currentBandGains['250Hz'] = 2.0;
        _currentBandGains['1kHz'] = 0.0;
        _currentBandGains['4kHz'] = 1.5;
        _currentBandGains['12kHz'] = 4.0;
        break;
      default:
        // Check saved custom presets
        final found = _savedCustomPresets.where((p) => p.name == presetName).firstOrNull;
        if (found != null) {
          _currentBandGains.addAll(found.bandGains);
        }
        break;
    }
    notifyListeners();
  }

  void saveCustomPreset(String name) {
    if (name.trim().isEmpty) return;
    _savedCustomPresets.removeWhere((p) => p.name == name);
    _savedCustomPresets.add(CustomEqPreset(
      name: name.trim(),
      bandGains: Map.from(_currentBandGains),
    ));
    _selectedPreset = name.trim();
    notifyListeners();
  }

  void setStreamingQuality(String quality) {
    _streamingQuality = quality;
    notifyListeners();
  }

  void setReplayGainEnabled(bool val) {
    _replayGainEnabled = val;
    notifyListeners();
  }

  void setCrossfadeDuration(double val) {
    _crossfadeDuration = val;
    notifyListeners();
  }

  void setAppTheme(AppThemeMode theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  void setAccentColor(AccentColorOption accent) {
    _accentColor = accent;
    notifyListeners();
  }

  void setLogoStyle(LogoStyle style) {
    _logoStyle = style;
    notifyListeners();
  }

  void setGlassBlurSigma(double val) {
    _glassBlurSigma = val;
    notifyListeners();
  }

  void setBorderOpacity(double val) {
    _borderOpacity = val;
    notifyListeners();
  }

  void setReflectionGlowEnabled(bool val) {
    _reflectionGlowEnabled = val;
    notifyListeners();
  }

  void setDownloadStoragePath(String path) {
    _downloadStoragePath = path;
    notifyListeners();
  }

  void setAutoScanLocalAudio(bool val) {
    _autoScanLocalAudio = val;
    notifyListeners();
  }

  void clearDownloadCache() {
    _downloadCacheSizeMb = 0.0;
    notifyListeners();
  }

  void setLyricsProvider(String provider) {
    _lyricsProvider = provider;
    notifyListeners();
  }

  void setSyncedLyricsEnabled(bool val) {
    _syncedLyricsEnabled = val;
    notifyListeners();
  }

  void setKaraokeFollowMode(bool val) {
    _karaokeFollowMode = val;
    notifyListeners();
  }

  void setLyricsFontSize(double size) {
    _lyricsFontSize = size;
    notifyListeners();
  }

  void setLyricsAlignment(TextAlign alignment) {
    _lyricsAlignment = alignment;
    notifyListeners();
  }

  void setScreenWakeLock(bool val) {
    _screenWakeLock = val;
    notifyListeners();
  }
}

