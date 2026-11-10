import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/playlist_model.dart';
import '../../core/network/saavn_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../state/player_provider.dart';
import '../../state/playlist_provider.dart';
import '../../state/settings_provider.dart';

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final settings = context.watch<SettingsProvider>();
    final accent = settings.activeAccentColor;
    final playlists = playlistProvider.playlists;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header with Create button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Playlists',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      playlists.isEmpty
                          ? 'Zero-State Collection'
                          : '${playlists.length} Custom Collections',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (playlists.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showCreatePlaylistDialog(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Icon(CupertinoIcons.add, color: accent, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // If Empty: Render Zero State
        if (playlists.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _buildZeroState(context, accent),
            ),
          )
        else ...[
          // Grid of Created / Imported Playlists
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final playlist = playlists[index];
                  return _buildPlaylistCard(context, playlist, accent);
                },
                childCount: playlists.length,
              ),
            ),
          ),

          // Import & Export Action Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSecondaryActionButton(
                      context,
                      icon: CupertinoIcons.link,
                      label: 'Import Link',
                      onTap: () => _showImportLinkDialog(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSecondaryActionButton(
                      context,
                      icon: CupertinoIcons.arrow_down_doc_fill,
                      label: 'Import JSON',
                      onTap: () => _showImportJsonDialog(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Central Empty State when local DB playlists count is 0
  Widget _buildZeroState(BuildContext context, Color accent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Glass Icon Container with Glow
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 36,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              CupertinoIcons.music_albums,
              size: 42,
              color: Colors.white70,
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'No playlists created yet',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 8),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Your local playlist vault is currently empty. Create your own custom playlist or import directly from Spotify & Apple Music.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Primary "Create Playlist" Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _showCreatePlaylistDialog(context),
            icon: const Icon(CupertinoIcons.add, size: 18),
            label: const Text(
              'Create Playlist',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: accent.withValues(alpha: 0.5),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Secondary "Import from Link / File" Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _showImportOptionsSheet(context),
            icon: const Icon(CupertinoIcons.arrow_down_to_line, size: 17),
            label: const Text(
              'Import from Link / File',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 1-Click Load Starter Templates
        TextButton(
          onPressed: () => _loadCuratedTemplates(context),
          child: Text(
            'Or load Curated Spatial Mixes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: accent.withValues(alpha: 0.9),
            ),
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildPlaylistCard(BuildContext context, PlaylistModel playlist, Color accent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: FrostedGlassBox(
        blurSigma: 20,
        borderRadius: BorderRadius.circular(20),
        borderColor: Colors.white.withValues(alpha: 0.12),
        backgroundColor: const Color(0xFF161922).withValues(alpha: 0.7),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _playPlaylist(context, playlist),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Artwork or Gradient
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (playlist.artworkUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: playlist.artworkUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, _) => Container(
                          color: const Color(0xFF222630),
                          child: const Icon(CupertinoIcons.music_albums, color: Colors.white30),
                        ),
                        errorWidget: (context, _, __) => _buildFallbackGradient(playlist),
                      )
                    else
                      _buildFallbackGradient(playlist),

                    // Song Count Pill Badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${playlist.songCount} TRACKS',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Play Button Overlay
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.play_fill,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Title & Subtitle Info
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      playlist.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }

  Widget _buildFallbackGradient(PlaylistModel playlist) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(int.parse(playlist.coverGradientStart)),
            Color(int.parse(playlist.coverGradientEnd)),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(CupertinoIcons.music_note_list, color: Colors.white60, size: 36),
      ),
    );
  }

  Widget _buildSecondaryActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1E28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: const Text('Create New Playlist', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Playlist Name',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Description (Optional)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  context.read<PlaylistProvider>().createPlaylist(
                    title,
                    subtitle: descController.text.trim().isEmpty ? 'Custom Collection' : descController.text.trim(),
                  );
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appleRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _showImportLinkDialog(BuildContext context) {
    final linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1E28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: const Text('Import from Link', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste a public Spotify, Apple Music, or JioSaavn playlist URL to import into Hearable.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: linkController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'https://open.spotify.com/playlist/...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                final link = linkController.text.trim();
                if (link.isNotEmpty) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('Importing playlist & resolving 320kbps audio...'),
                        ],
                      ),
                      duration: Duration(seconds: 15),
                    ),
                  );
                  final success = await context.read<PlaylistProvider>().importPlaylistFromLink(link);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Playlist imported successfully!' : 'Failed to import playlist'),
                        backgroundColor: success ? const Color(0xFF1DB954) : Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appleRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Import', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _showImportJsonDialog(BuildContext context) {
    final jsonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1E28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: const Text('Import from JSON', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste JSON backup data from exported Hearable or M3U playlist format.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: jsonController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: '{"title": "My Trap Hits", "songs": [...]}',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                final text = jsonController.text.trim();
                if (text.isNotEmpty) {
                  context.read<PlaylistProvider>().importFromJson(text);
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appleRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Import', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _showImportOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Import Playlist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(CupertinoIcons.link, color: AppColors.appleRed),
                  title: const Text('Import from Public Link', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Spotify, Apple Music, JioSaavn link', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showImportLinkDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.doc_text_fill, color: AppColors.cyan),
                  title: const Text('Import from JSON Backup', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Direct JSON string or exported format', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showImportJsonDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _loadCuratedTemplates(BuildContext context) {
    final templates = PlaylistModel.getCuratedPlaylists();
    final provider = context.read<PlaylistProvider>();
    for (final t in templates) {
      provider.createPlaylist(t.title, subtitle: t.subtitle);
    }
  }

  void _playPlaylist(BuildContext context, PlaylistModel playlist) {
    if (playlist.songs.isNotEmpty) {
      context.read<PlayerProvider>().playSong(
        playlist.songs.first,
        queue: playlist.songs,
      );
    } else {
      // Fallback tracks
      final fallbacks = SaavnApiService.getFallbackSongs();
      context.read<PlayerProvider>().playSong(
        fallbacks.first,
        queue: fallbacks,
      );
    }
  }
}
