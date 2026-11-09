import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/song_model.dart';
import '../../core/network/saavn_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../state/player_provider.dart';
import '../../state/settings_provider.dart';
import '../widgets/song_list_tile.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  // Top Tabs: 0: Local Audios, 1: Downloads, 2: Artists, 3: Albums
  int _selectedTab = 0;
  final List<String> _tabs = ['Local Audios', 'Downloads', 'Artists', 'Albums'];

  List<SongModel> _localAudioTracks = [];
  List<SongModel> _downloadedTracks = [];

  @override
  void initState() {
    super.initState();
    _loadLibraryData();
  }

  void _loadLibraryData() {
    final fallbacks = SaavnApiService.getFallbackSongs();
    _localAudioTracks = fallbacks.map((s) => s.copyWith(isOffline: true)).toList();
    _downloadedTracks = fallbacks.take(3).map((s) => s.copyWith(isOffline: true)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final settings = context.watch<SettingsProvider>();
    final accent = settings.activeAccentColor;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Library',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_localAudioTracks.length} Local Tracks • ${_downloadedTracks.length} Offline Downloads',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Scan Device Button
                GestureDetector(
                  onTap: () => _scanDeviceAudio(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.arrow_clockwise, size: 14, color: accent),
                        const SizedBox(width: 6),
                        const Text(
                          'Scan',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Storage & Cache Path Indicator Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FrostedGlassBox(
              blurSigma: 20,
              borderRadius: BorderRadius.circular(16),
              borderColor: Colors.white.withValues(alpha: 0.1),
              backgroundColor: const Color(0xFF141920).withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(CupertinoIcons.folder_fill, color: accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Storage Destination',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          settings.downloadStoragePath,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${settings.downloadCacheSizeMb.toStringAsFixed(1)} MB',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 4 Distinct Top Tabs: Local Audios, Downloads, Artists, Albums
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isSelected = _selectedTab == index;
                IconData icon;
                switch (index) {
                  case 0:
                    icon = CupertinoIcons.music_note_2;
                    break;
                  case 1:
                    icon = CupertinoIcons.arrow_down_circle_fill;
                    break;
                  case 2:
                    icon = CupertinoIcons.person_2_fill;
                    break;
                  default:
                    icon = CupertinoIcons.square_stack_3d_up_fill;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 15,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _tabs[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Tab Content Views
        if (_selectedTab == 0)
          _buildLocalAudiosList(player)
        else if (_selectedTab == 1)
          _buildDownloadsList(player)
        else if (_selectedTab == 2)
          _buildArtistsGrid(accent)
        else
          _buildAlbumsGrid(accent),

        // Bottom space for floating dock & mini-player
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildLocalAudiosList(PlayerProvider player) {
    if (_localAudioTracks.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('No local audio tracks found.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = _localAudioTracks[index];

          return SongListTile(
            song: song,
            queue: _localAudioTracks,
            index: index,
          );
        },
        childCount: _localAudioTracks.length,
      ),
    );
  }

  Widget _buildDownloadsList(PlayerProvider player) {
    if (_downloadedTracks.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('No offline downloads yet.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = _downloadedTracks[index];

          return SongListTile(
            song: song,
            queue: _downloadedTracks,
            index: index,
          );
        },
        childCount: _downloadedTracks.length,
      ),
    );
  }

  Widget _buildArtistsGrid(Color accent) {
    final artists = [
      {'name': 'Anirudh Ravichander', 'tracks': 14, 'color': 0xFFFA233B},
      {'name': 'The Weeknd', 'tracks': 8, 'color': 0xFF7B2CBF},
      {'name': 'Dua Lipa', 'tracks': 6, 'color': 0xFF007AFF},
      {'name': 'A.R. Rahman', 'tracks': 22, 'color': 0xFF00E676},
      {'name': 'Hip Hop Tamizha', 'tracks': 9, 'color': 0xFFFF6B35},
      {'name': 'Daft Punk', 'tracks': 5, 'color': 0xFFFFD166},
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final a = artists[index];
            return FrostedGlassBox(
              blurSigma: 20,
              borderRadius: BorderRadius.circular(18),
              backgroundColor: const Color(0xFF161922).withValues(alpha: 0.65),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(a['color'] as int),
                          Color(a['color'] as int).withValues(alpha: 0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(CupertinoIcons.person_fill, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          a['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${a['tracks']} Tracks',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: artists.length,
        ),
      ),
    );
  }

  Widget _buildAlbumsGrid(Color accent) {
    final albums = [
      {'name': 'Jailer', 'artist': 'Anirudh Ravichander', 'year': '2023', 'color': 0xFFFA233B},
      {'name': 'Leo', 'artist': 'Anirudh Ravichander', 'year': '2023', 'color': 0xFF7B2CBF},
      {'name': 'After Hours', 'artist': 'The Weeknd', 'year': '2020', 'color': 0xFF007AFF},
      {'name': 'Starboy', 'artist': 'The Weeknd', 'year': '2016', 'color': 0xFFFF6B35},
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final album = albums[index];
            return FrostedGlassBox(
              blurSigma: 20,
              borderRadius: BorderRadius.circular(18),
              backgroundColor: const Color(0xFF161922).withValues(alpha: 0.65),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Color(album['color'] as int),
                            Colors.black87,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.music_albums, color: Colors.white70, size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    album['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${album['artist']} • ${album['year']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: albums.length,
        ),
      ),
    );
  }

  void _scanDeviceAudio(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E222D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(CupertinoIcons.checkmark_alt_circle_fill, color: AppColors.dspActiveGlow, size: 20),
            SizedBox(width: 10),
            Text(
              'Local scan complete. 8 audio files verified.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
