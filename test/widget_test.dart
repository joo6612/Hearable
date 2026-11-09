import 'package:flutter_test/flutter_test.dart';
import 'package:hearable/core/models/lyrics_model.dart';
import 'package:hearable/core/models/song_model.dart';
import 'package:hearable/core/network/saavn_api_service.dart';
import 'package:hearable/core/theme/app_colors.dart';
import 'package:hearable/state/music_provider.dart';
import 'package:hearable/state/playlist_provider.dart';
import 'package:hearable/state/settings_provider.dart';

void main() {
  test('SongModel fromJson and 320kbps extraction test', () {
    final mockJson = {
      'id': 'test_song_123',
      'name': 'Hukum',
      'primaryArtists': 'Anirudh Ravichander',
      'album': {'name': 'Jailer'},
      'duration': '207',
      'downloadUrl': [
        {'quality': '160kbps', 'url': 'https://example.com/160.mp4'},
        {'quality': '320kbps', 'url': 'https://example.com/320.mp4'},
      ],
      'image': [
        {'quality': '150x150', 'url': 'https://example.com/150.jpg'},
        {'quality': '500x500', 'url': 'https://example.com/500.jpg'},
      ],
    };

    final song = SongModel.fromJson(mockJson);
    expect(song.id, 'test_song_123');
    expect(song.title, 'Hukum');
    expect(song.artist, 'Anirudh Ravichander');
    expect(song.album, 'Jailer');
    expect(song.quality, '320kbps');
    expect(song.audioUrl, 'https://example.com/320.mp4');
    expect(song.artworkUrl, 'https://example.com/500.jpg');
    expect(song.durationMs, 207000);
  });

  test('Fallback catalog verification', () {
    final fallbacks = SaavnApiService.getFallbackSongs();
    expect(fallbacks.isNotEmpty, true);
    for (final song in fallbacks) {
      expect(song.audioUrl.isNotEmpty, true);
      expect(song.artworkUrl.isNotEmpty, true);
      expect(song.quality, '320kbps');
    }
  });

  test('Lyrics parsing and active line timestamp lookup', () {
    const lrc = '''
[00:05.50]Alappara Kelapparom
[00:15.20]Thalaivaru Kalathula
[00:25.80]Hukum Tiger Ka Hukum
''';
    final lyrics = LyricsModel.fromLrc('song_1', lrc);
    expect(lyrics.lines.length, 3);
    expect(lyrics.lines[0].text, 'Alappara Kelapparom');
    expect(lyrics.lines[0].timestampMs, 5500);

    // Test timestamp indexing (before first line defaults to index 0 for smooth intro follow-along)
    expect(lyrics.getActiveLineIndex(const Duration(seconds: 4)), 0);
    expect(lyrics.getActiveLineIndex(const Duration(seconds: 6)), 0);
    expect(lyrics.getActiveLineIndex(const Duration(seconds: 16)), 1);
    expect(lyrics.getActiveLineIndex(const Duration(seconds: 30)), 2);
  });

  test('SettingsProvider audio and theme controls test', () {
    final settings = SettingsProvider();

    // Default tone controls
    expect(settings.bass, 3.5);
    expect(settings.treble, 3.0);
    expect(settings.eqBandCount, 5);

    // Apply preset
    settings.applyPreset('Bass Boost');
    expect(settings.selectedPreset, 'Bass Boost');

    // Theme & accent colors
    settings.setAppTheme(AppThemeMode.pitchBlackOled);
    expect(settings.currentTheme, AppThemeMode.pitchBlackOled);

    settings.setAccentColor(AccentColorOption.burntOrange);
    expect(settings.accentColor, AccentColorOption.burntOrange);
    expect(settings.activeAccentColor, AppColors.burntOrange);

    // Logo style customization
    expect(settings.logoStyle, LogoStyle.acousticWave);
    settings.setLogoStyle(LogoStyle.neonHeadphones);
    expect(settings.logoStyle, LogoStyle.neonHeadphones);

    // EQ Custom sliders
    settings.setBandGain('60Hz', 4.5);
    expect(settings.getBandGain('60Hz'), 4.5);
  });

  test('MusicProvider debounced live suggestions test', () async {
    final music = MusicProvider();

    expect(music.searchResults.isEmpty, true);
    expect(music.liveSuggestions.isEmpty, true);
    expect(music.isSearching, false);

    // Trigger debounced search suggestions
    await music.searchLiveSuggestions('Anirudh');
    expect(music.currentQuery, 'Anirudh');
    expect(music.searchResults.isNotEmpty, true);
    expect(music.liveSuggestions.isNotEmpty, true);

    // Clear search
    music.clearSearch();
    expect(music.currentQuery.isEmpty, true);
    expect(music.searchResults.isEmpty, true);
    expect(music.liveSuggestions.isEmpty, true);
  });

  test('PlaylistProvider zero state and CRUD test', () {
    final playlistProvider = PlaylistProvider();

    // Initial state is empty zero-state
    expect(playlistProvider.isEmpty, true);
    expect(playlistProvider.playlists.length, 0);

    // Create a playlist
    playlistProvider.createPlaylist('Heavy Bass Hits', subtitle: 'Deep bassline tracks');
    expect(playlistProvider.isEmpty, false);
    expect(playlistProvider.playlists.length, 1);
    final created = playlistProvider.playlists.first;
    expect(created.title, 'Heavy Bass Hits');

    // Export to JSON
    final jsonExport = playlistProvider.exportPlaylistToJson(created);
    expect(jsonExport.isNotEmpty, true);
    expect(jsonExport.contains('Heavy Bass Hits'), true);

    // Delete playlist
    playlistProvider.deletePlaylist(created.id);
    expect(playlistProvider.isEmpty, true);
  });
}
