import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class SaavnApiService {
  static final List<String> _baseUrls = [
    'https://jiosaavn-api-privatetesting.vercel.app',
    'https://saavn.dev',
    'https://jiosaavn-api-sigma.vercel.app',
  ];

  static final http.Client _client = http.Client();
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json',
  };

  // ---------------------------------------------------------------------------
  //  Search
  // ---------------------------------------------------------------------------
  static Future<List<SongModel>> searchSongs(String query,
      {int page = 1, int limit = 20}) async {
    final cleanQuery =
        query.trim().isEmpty ? 'Top Trending Hits' : query.trim();
    final encodedQuery = Uri.encodeComponent(cleanQuery);

    for (final baseUrl in _baseUrls) {
      try {
        final uri = Uri.parse(
            '$baseUrl/api/search/songs?query=$encodedQuery&page=$page&limit=$limit');
        final response = await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          List<dynamic> results = [];

          if (data is Map<String, dynamic>) {
            if (data['data'] != null && data['data']['results'] != null) {
              results = data['data']['results'];
            } else if (data['results'] != null) {
              results = data['results'];
            } else if (data['data'] is List) {
              results = data['data'];
            }
          }

          if (results.isNotEmpty) {
            final songs = results
                .map((item) =>
                    SongModel.fromJson(item as Map<String, dynamic>))
                .where((s) => s.audioUrl.isNotEmpty)
                .toList();
            if (songs.isNotEmpty) return songs;
          }
        }
      } catch (e) {
        debugPrint('Mirror $baseUrl failed for "$cleanQuery": $e');
        continue;
      }
    }

    // Official JioSaavn direct API fallback
    try {
      final officialUri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=search.getResults&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=$limit&p=$page&q=$encodedQuery',
      );
      final response = await _client
          .get(officialUri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['results'] is List) {
          final results = data['results'] as List;
          final songs = results
              .whereType<Map<String, dynamic>>()
              .map((item) => SongModel.fromJson(item))
              .where((s) => s.audioUrl.isNotEmpty)
              .toList();
          if (songs.isNotEmpty) return songs;
        }
      }
    } catch (e) {
      debugPrint('Official Saavn fallback error: $e');
    }

    return getFallbackSongs(cleanQuery);
  }

  // ---------------------------------------------------------------------------
  //  Trending
  // ---------------------------------------------------------------------------
  static Future<List<SongModel>> getTrendingSongs() async {
    for (final baseUrl in _baseUrls) {
      try {
        final uri =
            Uri.parse('$baseUrl/api/modules?language=tamil,english,hindi');
        final response = await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['data'] != null &&
              data['data']['trending'] != null &&
              data['data']['trending']['songs'] != null) {
            final results = data['data']['trending']['songs'] as List;
            final songs = results
                .map((item) =>
                    SongModel.fromJson(item as Map<String, dynamic>))
                .where((s) => s.audioUrl.isNotEmpty)
                .toList();
            if (songs.isNotEmpty) return songs;
          }
        }
      } catch (_) {
        continue;
      }
    }
    return searchSongs('Top Trending Anirudh A.R. Rahman Hits', limit: 20);
  }

  // ---------------------------------------------------------------------------
  //  Song Details
  // ---------------------------------------------------------------------------
  static Future<SongModel?> getSongDetails(String songId) async {
    for (final baseUrl in _baseUrls) {
      try {
        final uri = Uri.parse('$baseUrl/api/songs?id=$songId');
        final response = await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          List<dynamic> list = [];
          if (data['data'] is List) {
            list = data['data'];
          } else if (data['data'] is Map) {
            list = [data['data']];
          }
          if (list.isNotEmpty) {
            return SongModel.fromJson(list.first as Map<String, dynamic>);
          }
        }
      } catch (_) {
        continue;
      }
    }
    return getFallbackSongs()
        .where((s) => s.id == songId)
        .firstOrNull;
  }

  // ---------------------------------------------------------------------------
  //  Recommendations / Radio Queue (infinite auto-queue)
  // ---------------------------------------------------------------------------
  static Future<List<SongModel>> getSongRecommendations(
      String songId, {
      String? artistName,
      int limit = 20,
    }) async {
    // 1. Try station/radio endpoint
    for (final baseUrl in _baseUrls) {
      try {
        final uri = Uri.parse(
            '$baseUrl/api/songs/$songId/suggestions?limit=$limit');
        final response = await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          List<dynamic> results = [];
          if (data['data'] is List) results = data['data'];
          if (results.isNotEmpty) {
            final songs = results
                .map((item) =>
                    SongModel.fromJson(item as Map<String, dynamic>))
                .where((s) => s.audioUrl.isNotEmpty)
                .toList();
            if (songs.isNotEmpty) return songs;
          }
        }
      } catch (_) {
        continue;
      }
    }

    // 2. Fallback: search by artist name
    if (artistName != null && artistName.isNotEmpty) {
      final artistQuery = artistName.split(',').first.trim();
      return searchSongs(artistQuery, limit: limit);
    }

    // 3. Last resort: trending
    return getTrendingSongs();
  }

  // ---------------------------------------------------------------------------
  //  Lyrics
  // ---------------------------------------------------------------------------
  /// Fetch synced LRC lyrics for a song. Tries JioSaavn, then LRCLIB.
  static Future<String?> getSyncedLyrics(SongModel song) async {
    // 1. JioSaavn lyrics endpoint
    for (final baseUrl in _baseUrls) {
      try {
        final uri = Uri.parse('$baseUrl/api/songs/${song.id}/lyrics');
        final response = await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final lyrics = data['data']?['lyrics']?.toString() ??
              data['lyrics']?.toString();
          if (lyrics != null && lyrics.isNotEmpty) return lyrics;
        }
      } catch (_) {
        continue;
      }
    }

    // 2. LRCLIB API fallback
    try {
      final artist = Uri.encodeComponent(
          song.artist.split(',').first.trim());
      final title = Uri.encodeComponent(song.title);
      final uri = Uri.parse(
          'https://lrclib.net/api/get?artist_name=$artist&track_name=$title');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final synced = data['syncedLyrics']?.toString();
        if (synced != null && synced.isNotEmpty) return synced;
        final plain = data['plainLyrics']?.toString();
        if (plain != null && plain.isNotEmpty) return plain;
      }
    } catch (e) {
      debugPrint('LRCLIB lyrics error: $e');
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  //  Spotify Import helper (track metadata only via oEmbed / scraping fallback)
  // ---------------------------------------------------------------------------
  /// Extract track + artist titles from a Spotify public playlist URL.
  /// Uses the unofficial Spotify oEmbed endpoint for each listed track.
  static Future<List<Map<String, String>>> extractSpotifyPlaylistTracks(
      String spotifyUrl) async {
    // Scrape the JSON LD metadata exposed by Spotify's open graph
    try {
      final response = await _client
          .get(Uri.parse(spotifyUrl), headers: {
            'User-Agent':
                'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
            'Accept': 'text/html',
          })
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = response.body;
        // Extract JSON-LD script tag
        final ldStart = body.indexOf('"@type":"MusicAlbum"');
        if (ldStart > 0) {
          // Find surrounding script content
          final scriptStart = body.lastIndexOf('<script', ldStart);
          final scriptEnd = body.indexOf('</script>', ldStart);
          if (scriptStart > 0 && scriptEnd > scriptStart) {
            final scriptContent =
                body.substring(scriptStart, scriptEnd);
            final jsonStart = scriptContent.indexOf('{');
            final jsonEnd = scriptContent.lastIndexOf('}');
            if (jsonStart >= 0 && jsonEnd > jsonStart) {
              final jsonStr =
                  scriptContent.substring(jsonStart, jsonEnd + 1);
              final data = json.decode(jsonStr);
              final tracks = data['track'] as List? ?? [];
              return tracks
                  .whereType<Map<String, dynamic>>()
                  .map((t) => {
                        'title': (t['name'] ?? '').toString(),
                        'artist':
                            ((t['byArtist'] as Map?)?['name'] ?? '')
                                .toString(),
                      })
                  .where((t) =>
                      t['title']!.isNotEmpty)
                  .toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Spotify extraction error: $e');
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  //  Curated fallback catalog
  // ---------------------------------------------------------------------------
  static List<SongModel> getFallbackSongs([String? category]) {
    return [
      SongModel(
        id: 'hukum_anirudh_jailer',
        title: 'Hukum - Thalaivar Alappara',
        artist: 'Anirudh Ravichander, Super Subu',
        album: 'Jailer',
        durationMs: 207000,
        audioUrl:
            'https://aac.saavncdn.com/175/fbbba8f62f3f721dffad8c7247a3e742_320.mp4',
        artworkUrl:
            'https://c.saavncdn.com/175/Jailer-Tamil-2023-20230728084405-500x500.jpg',
        quality: '320kbps',
        year: '2023',
      ),
      SongModel(
        id: 'badass_leo_anirudh',
        title: 'Badass (From "Leo")',
        artist: 'Anirudh Ravichander',
        album: 'Leo',
        durationMs: 229000,
        audioUrl:
            'https://aac.saavncdn.com/712/91ee643328ce786a3b2bfe6030985c49_320.mp4',
        artworkUrl:
            'https://c.saavncdn.com/712/Leo-Tamil-2023-20231020083236-500x500.jpg',
        quality: '320kbps',
        year: '2023',
      ),
      SongModel(
        id: 'blinding_lights_the_weeknd',
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        album: 'After Hours',
        durationMs: 200000,
        audioUrl:
            'https://aac.saavncdn.com/391/a6064f7b6bfa17c093a890472e399580_320.mp4',
        artworkUrl:
            'https://c.saavncdn.com/391/After-Hours-English-2020-20200320013531-500x500.jpg',
        quality: '320kbps',
        year: '2020',
      ),
      SongModel(
        id: 'starboy_the_weeknd_daft_punk',
        title: 'Starboy',
        artist: 'The Weeknd, Daft Punk',
        album: 'Starboy',
        durationMs: 230000,
        audioUrl:
            'https://aac.saavncdn.com/048/a2d39893d50fcbe8387032ec3937aa15_320.mp4',
        artworkUrl:
            'https://c.saavncdn.com/048/Starboy-English-2016-500x500.jpg',
        quality: '320kbps',
        year: '2016',
      ),
      SongModel(
        id: 'levitating_dua_lipa',
        title: 'Levitating',
        artist: 'Dua Lipa',
        album: 'Future Nostalgia',
        durationMs: 203000,
        audioUrl:
            'https://aac.saavncdn.com/736/c234a5d3f23a4b92b67e7cfa557a5dc0_320.mp4',
        artworkUrl:
            'https://c.saavncdn.com/736/Future-Nostalgia-English-2020-20200327004351-500x500.jpg',
        quality: '320kbps',
        year: '2020',
      ),
      SongModel(
        id: 'fear_song_devara',
        title: 'Fear Song',
        artist: 'Anirudh Ravichander',
        album: 'Devara Part 1',
        durationMs: 195000,
        audioUrl:
            'https://aac.saavncdn.com/348/115a31b4ce3685e92be76595bfef4388_320.mp4',
        artworkUrl:
            'https://c.saavncdn.com/348/Devara-Part-1-Tamil-2024-20240905183827-500x500.jpg',
        quality: '320kbps',
        year: '2024',
      ),
      SongModel(
        id: 'arajan_kannazhaga',
        title: 'Kannazhaga (The Kiss of Love)',
        artist: 'Anirudh Ravichander, Shruti Haasan',
        album: '3',
        durationMs: 205000,
        audioUrl:
            'https://aac.saavncdn.com/023/1e7aaebffc89b7fae4465e6484e5ec60_320.mp4',
        artworkUrl:
            'https://c.saavncdn.com/023/3-Tamil-2011-500x500.jpg',
        quality: '320kbps',
        year: '2011',
      ),
    ];
  }
}
