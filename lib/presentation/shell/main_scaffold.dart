import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../state/player_provider.dart';
import '../../state/settings_provider.dart';
import '../tabs/club_party_tab.dart';
import '../tabs/library_tab.dart';
import '../tabs/playlists_tab.dart';
import '../tabs/settings_tab.dart';
import '../tabs/songs_tab.dart';
import '../widgets/ambient_glow_background.dart';
import '../widgets/frosted_pill_tab_bar.dart';
import '../widgets/mini_player.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentTab = 0;

  final List<Widget> _tabs = const [
    SongsTab(),
    PlaylistsTab(),
    LibraryTab(),
    ClubPartyTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final settings = context.watch<SettingsProvider>();
    final hasCurrentSong = player.currentSong != null;

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // User requested floating dock positioned at bottom: 24px
    final tabBarBottom = bottomInset > 0 ? bottomInset + 10 : 24.0;
    final miniPlayerBottom = tabBarBottom + 66.0 + 10.0;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: settings.currentTheme == AppThemeMode.pitchBlackOled
          ? AppColors.backgroundOled
          : settings.currentTheme == AppThemeMode.glassmorphismDark
              ? AppColors.backgroundTealDark
              : AppColors.background,
      body: AmbientGlowBackground(
        child: Stack(
          children: [
            // Persistent Tab Pages (using IndexedStack to preserve scroll state)
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _currentTab,
                children: _tabs,
              ),
            ),

            // Persistent Frosted Glass Mini-Player
            // Positioned floating cleanly above the frosted dock
            if (hasCurrentSong)
              Positioned(
                left: 0,
                right: 0,
                bottom: miniPlayerBottom,
                child: const MiniPlayer(),
              ),

            // Ultra-Glossy Floating Dock (5 Tabs)
            Positioned(
              left: 0,
              right: 0,
              bottom: tabBarBottom,
              child: FrostedPillTabBar(
                selectedIndex: _currentTab,
                onTabSelected: (index) {
                  setState(() => _currentTab = index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
