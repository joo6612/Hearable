import 'song_model.dart';

class PlaylistModel {
  final String id;
  final String title;
  final String subtitle;
  final String coverGradientStart;
  final String coverGradientEnd;
  final String iconName;
  final int songCount;
  final List<SongModel> songs;
  final String artworkUrl;

  const PlaylistModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverGradientStart,
    required this.coverGradientEnd,
    required this.iconName,
    required this.songCount,
    this.songs = const [],
    this.artworkUrl = '',
  });

  static List<PlaylistModel> getCuratedPlaylists() {
    return [
      const PlaylistModel(
        id: 'curated_heavy_bass',
        title: 'Heavy Bass',
        subtitle: 'Sub-bass tuned for 60Hz punch',
        coverGradientStart: '0xFF8A2387',
        coverGradientEnd: '0xFFE94057',
        iconName: 'speaker_phone',
        songCount: 28,
        artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      ),
      const PlaylistModel(
        id: 'curated_late_night_chill',
        title: 'Late Night Chill',
        subtitle: 'Atmospheric R&B & Lo-Fi spatial',
        coverGradientStart: '0xFF200122',
        coverGradientEnd: '0xFF6f0000',
        iconName: 'moon_stars',
        songCount: 34,
        artworkUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=600&auto=format&fit=crop&q=80',
      ),
      const PlaylistModel(
        id: 'curated_tamil_trap',
        title: 'Tamil Trap',
        subtitle: 'Anirudh & Hip Hop Tamizha hits',
        coverGradientStart: '0xFFF77737',
        coverGradientEnd: '0xFFFA233B',
        iconName: 'flame',
        songCount: 42,
        artworkUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80',
      ),
      const PlaylistModel(
        id: 'curated_gym_focus',
        title: 'Gym Focus',
        subtitle: 'High energy 140+ BPM spatial pump',
        coverGradientStart: '0xFF0F2027',
        coverGradientEnd: '0xFF2C5364',
        iconName: 'bolt',
        songCount: 50,
        artworkUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&auto=format&fit=crop&q=80',
      ),
    ];
  }
}

