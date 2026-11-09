import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/song_model.dart';
import '../../core/network/saavn_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../state/music_provider.dart';
import '../../state/player_provider.dart';
import '../../state/settings_provider.dart';
import '../widgets/audio_quality_badge.dart';
import '../widgets/hearable_brand_logo.dart';
import '../widgets/song_list_tile.dart';

class SongsTab extends StatefulWidget {
  const SongsTab({super.key});

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  final List<String> _filterChips = [
    'All',
    'Billboard Top',
    'Regional Top',
    'New Trends',
    'Indie Artists',
  ];
  String _selectedChip = 'All';
  List<SongModel> _songs = [];
  bool _isLoading = true;
  SongModel? _spotlightSong;

  @override
  void initState() {
    super.initState();
    _fetchSongsForCategory('All');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (query.trim().isNotEmpty) {
        context.read<MusicProvider>().searchLiveSuggestions(query.trim());
        _onSearchSubmitted(query.trim());
      } else {
        context.read<MusicProvider>().clearSearch();
        _fetchSongsForCategory(_selectedChip);
      }
    });
  }

  Future<void> _fetchSongsForCategory(String category) async {
    setState(() => _isLoading = true);

    String query;
    switch (category) {
      case 'Billboard Top':
        query = 'Billboard Hot 100 English Top';
        break;
      case 'Regional Top':
        query = 'Tamil Top Hits Anirudh';
        break;
      case 'New Trends':
        query = 'Viral Trending 2024';
        break;
      case 'Indie Artists':
        query = 'Indie Pop Acoustic';
        break;
      default:
        query = 'Top Trending Anirudh A.R. Rahman English Hits';
    }

    final results = await SaavnApiService.searchSongs(query);

    if (mounted) {
      setState(() {
        _songs = results;
        if (_songs.isNotEmpty) {
          _spotlightSong = _songs.first;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearchSubmitted(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final results = await SaavnApiService.searchSongs(query);
    if (mounted) {
      setState(() {
        _songs = results;
        if (_songs.isNotEmpty) {
          _spotlightSong = _songs.first;
        }
        _isLoading = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final settings = context.watch<SettingsProvider>();
    final accentColor = settings.activeAccentColor;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // App Bar & Dynamic Greeting Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.dspActiveGlow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Apple DSP Signature • 320kbps Master',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Hearable Frosted Glass Brand Logo with Studio Customizer
                const HearableBrandLogo(size: 44),
              ],
            ),
          ),
        ),

        // Search Input Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: FrostedGlassBox(
              blurSigma: 25,
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchSubmitted,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  icon: const Icon(CupertinoIcons.search,
                      color: Colors.white54, size: 20),
                  hintText: 'Search songs, artists, albums...',
                  hintStyle:
                      const TextStyle(color: Colors.white38, fontSize: 14),
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(CupertinoIcons.clear_circled_solid,
                              color: Colors.white38, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context.read<MusicProvider>().clearSearch();
                            _fetchSongsForCategory(_selectedChip);
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),

        // Live Suggestions Chips (when typing)
        if (context.watch<MusicProvider>().liveSuggestions.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: context.watch<MusicProvider>().liveSuggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final suggestion = context.watch<MusicProvider>().liveSuggestions[idx];
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = suggestion;
                      _onSearchSubmitted(suggestion);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.search, size: 11, color: accentColor),
                          const SizedBox(width: 5),
                          Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        // Filter Chips Row
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _filterChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final chip = _filterChips[index];
                final isSelected = chip == _selectedChip;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedChip = chip);
                    _fetchSongsForCategory(chip);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? accentColor
                            : Colors.white.withValues(alpha: 0.14),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    accentColor.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        chip,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Hero Spotlight Glass Card
        if (_spotlightSong != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: FrostedGlassBox(
                blurSigma: 30,
                borderRadius: BorderRadius.circular(24),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                borderColor: Colors.white.withValues(alpha: 0.18),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    // Spotlight Artwork with shadow
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _spotlightSong!.artworkUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _spotlightSong!.artworkUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, _) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF2E0854), Color(0xFF1B1B26)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(CupertinoIcons.music_note, color: Colors.white30, size: 36),
                                  ),
                                ),
                                errorWidget: (context, _, __) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.appleRed, AppColors.glowPurple],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(CupertinoIcons.music_note_2, color: Colors.white, size: 40),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.appleRed, AppColors.glowPurple],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(CupertinoIcons.music_note_2, color: Colors.white, size: 40),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Spotlight Metadata & Play Action
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              AudioQualityBadge(
                                  label: 'SPOTLIGHT', isHiRes: true),
                              SizedBox(width: 6),
                              AudioQualityBadge(label: '320K', isHiRes: false),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _spotlightSong!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _spotlightSong!.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              player.playSong(_spotlightSong!, queue: _songs);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor
                                        .withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(CupertinoIcons.play_fill,
                                      size: 14, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Listen Now',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
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
                  ],
                ),
              ),
            ),
          ),

        // Section Title: Dynamic Track List
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Tracks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_songs.length} Tracks',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Songs List
        if (_isLoading)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CupertinoActivityIndicator(
                    radius: 16, color: AppColors.appleRed),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = _songs[index];
                return SongListTile(
                  song: song,
                  queue: _songs,
                  index: index,
                );
              },
              childCount: _songs.length,
            ),
          ),

        // Bottom space so mini-player doesn't overlap last item
        const SliverToBoxAdapter(
          child: SizedBox(height: 160),
        ),
      ],
    );
  }
}
