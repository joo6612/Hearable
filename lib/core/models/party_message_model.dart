import 'dart:convert';

class PartyMessageModel {
  final String action; // SYNC_PLAY, SYNC_PAUSE, SYNC_SEEK, SYNC_HEARTBEAT, PARTY_INFO
  final String audioUrl;
  final String title;
  final String artist;
  final String imageUrl;
  final int seekPositionMs;
  final int hostTimestamp; // millisecondsSinceEpoch on Host clock
  final String? songId;
  final int? peerCount;

  PartyMessageModel({
    required this.action,
    required this.audioUrl,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.seekPositionMs,
    required this.hostTimestamp,
    this.songId,
    this.peerCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'audioUrl': audioUrl,
      'title': title,
      'artist': artist,
      'imageUrl': imageUrl,
      'seekPositionMs': seekPositionMs,
      'hostTimestamp': hostTimestamp,
      if (songId != null) 'songId': songId,
      if (peerCount != null) 'peerCount': peerCount,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory PartyMessageModel.fromMap(Map<String, dynamic> map) {
    return PartyMessageModel(
      action: map['action']?.toString() ?? 'SYNC_PLAY',
      audioUrl: map['audioUrl']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      artist: map['artist']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      seekPositionMs: (map['seekPositionMs'] as num?)?.toInt() ?? 0,
      hostTimestamp: (map['hostTimestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      songId: map['songId']?.toString(),
      peerCount: (map['peerCount'] as num?)?.toInt(),
    );
  }

  factory PartyMessageModel.fromJson(String source) =>
      PartyMessageModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

