import 'dart:convert';
import 'package:dart_des/dart_des.dart';

class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final String audioUrl;
  final String artworkUrl;
  final String quality;
  final String year;
  bool isLiked;
  bool isOffline;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.audioUrl,
    required this.artworkUrl,
    this.quality = '320kbps',
    this.year = '',
    this.isLiked = false,
    this.isOffline = false,
  });

  /// Alias for strictly 320kbps audio streaming URL
  String get audioUrl320 => audioUrl;

  String get durationFormatted {
    final totalSeconds = (durationMs / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Helper to sanitize HTML entities in song titles, artists, and album names
  static String sanitizeHtml(dynamic raw) {
    if (raw == null) return '';
    return raw
        .toString()
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  /// Decrypt official JioSaavn DES-ECB encrypted media URL into direct 320kbps CDN URL
  static String decryptMediaUrl(String encryptedBase64) {
    try {
      final key = utf8.encode('38346591');
      final des = DES(key: key, mode: DESMode.ECB, paddingType: DESPaddingType.PKCS7);
      final decryptedBytes = des.decrypt(base64.decode(encryptedBase64.trim()));
      final decryptedUrl = utf8.decode(decryptedBytes).trim();
      return decryptedUrl
          .replaceAll('_96.mp4', '_320.mp4')
          .replaceAll('_160.mp4', '_320.mp4');
    } catch (_) {
      return '';
    }
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? UniqueKeyId.generate();
    final name = sanitizeHtml(json['name'] ?? json['title'] ?? json['song'] ?? 'Unknown Track');

    // Parse artists (supports object arrays, primaryArtists string, or artist string)
    String artists = '';
    if (json['artists'] != null && json['artists']['primary'] is List) {
      final list = (json['artists']['primary'] as List)
          .map((a) => sanitizeHtml(a is Map ? a['name'] : a))
          .where((s) => s.isNotEmpty)
          .toList();
      artists = list.join(', ');
    } else if (json['primaryArtists'] != null) {
      artists = sanitizeHtml(json['primaryArtists']);
    } else if (json['artist'] != null) {
      artists = sanitizeHtml(json['artist']);
    } else if (json['subtitle'] != null) {
      artists = sanitizeHtml(json['subtitle']);
    }
    if (artists.isEmpty) artists = 'Unknown Artist';

    // Parse album
    String album = '';
    if (json['album'] is Map) {
      album = sanitizeHtml(json['album']['name']);
    } else if (json['album'] != null) {
      album = sanitizeHtml(json['album']);
    } else if (json['more_info'] != null && json['more_info']['album'] != null) {
      album = sanitizeHtml(json['more_info']['album']);
    }
    if (album.isEmpty) album = 'Single';

    // Parse duration
    int duration = 0;
    final rawDuration = json['duration'] ?? (json['more_info'] is Map ? json['more_info']['duration'] : null);
    if (rawDuration != null) {
      final d = int.tryParse(rawDuration.toString()) ?? 0;
      duration = d > 1000 ? d : d * 1000;
    }

    // Parse audio URL (supports downloadUrl array, direct audioUrl, media_url, or encrypted_media_url)
    String audioUrl = '';
    String quality = '320kbps';

    if (json['downloadUrl'] is List && (json['downloadUrl'] as List).isNotEmpty) {
      final downloads = json['downloadUrl'] as List;
      dynamic item320;
      for (final item in downloads) {
        if (item is Map) {
          final q = item['quality']?.toString().toLowerCase() ?? '';
          if (q.contains('320')) {
            item320 = item;
            break;
          }
        }
      }
      final chosen = item320 ?? downloads.last;
      if (chosen is Map) {
        audioUrl = chosen['url']?.toString() ?? '';
        quality = chosen['quality']?.toString() ?? '320kbps';
      }
    } else if (json['audioUrl'] != null && json['audioUrl'].toString().isNotEmpty) {
      audioUrl = json['audioUrl'].toString();
    } else if (json['media_url'] != null && json['media_url'].toString().isNotEmpty) {
      audioUrl = json['media_url'].toString();
    } else if (json['more_info'] is Map && json['more_info']['encrypted_media_url'] != null) {
      final enc = json['more_info']['encrypted_media_url'].toString();
      if (enc.isNotEmpty) {
        audioUrl = decryptMediaUrl(enc);
      }
    }

    // Parse Artwork URL (handles list of [{quality: '500x500', url: '...'}], single string, or replaces low-res)
    String artworkUrl = '';
    if (json['image'] is List && (json['image'] as List).isNotEmpty) {
      final images = json['image'] as List;
      dynamic item500;
      for (final item in images) {
        if (item is Map) {
          final q = item['quality']?.toString().toLowerCase() ?? '';
          if (q.contains('500')) {
            item500 = item;
            break;
          }
        }
      }
      final chosen = item500 ?? images.last;
      if (chosen is Map) {
        artworkUrl = chosen['url']?.toString() ?? '';
      }
    } else if (json['image'] is String && json['image'].toString().isNotEmpty) {
      artworkUrl = json['image'].toString();
    } else if (json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty) {
      artworkUrl = json['imageUrl'].toString();
    }

    // Upgrade resolution to 500x500 for crisp Apple Music display
    if (artworkUrl.isNotEmpty) {
      artworkUrl = artworkUrl
          .replaceAll('150x150', '500x500')
          .replaceAll('50x50', '500x500');
    }

    return SongModel(
      id: id,
      title: name,
      artist: artists,
      album: album,
      durationMs: duration > 0 ? duration : 214000,
      audioUrl: audioUrl,
      artworkUrl: artworkUrl,
      quality: quality,
      year: json['year']?.toString() ?? '',
      isLiked: json['isLiked'] == true,
      isOffline: json['isOffline'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': durationMs,
      'audioUrl': audioUrl,
      'artworkUrl': artworkUrl,
      'quality': quality,
      'year': year,
      'isLiked': isLiked,
      'isOffline': isOffline,
    };
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? durationMs,
    String? audioUrl,
    String? artworkUrl,
    String? quality,
    String? year,
    bool? isLiked,
    bool? isOffline,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationMs: durationMs ?? this.durationMs,
      audioUrl: audioUrl ?? this.audioUrl,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      quality: quality ?? this.quality,
      year: year ?? this.year,
      isLiked: isLiked ?? this.isLiked,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class UniqueKeyId {
  static int _counter = 0;
  static String generate() {
    _counter++;
    return 'song_${DateTime.now().millisecondsSinceEpoch}_$_counter';
  }
}
