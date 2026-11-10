import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'core/audio/audio_player_handler.dart';
import 'core/theme/app_theme.dart';
import 'presentation/shell/main_scaffold.dart';
import 'state/music_provider.dart';
import 'state/party_provider.dart';
import 'state/player_provider.dart';
import 'state/playlist_provider.dart';
import 'state/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge immersive display – no black bars
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));

  // Initialize just_audio_background for lock-screen & notification controls
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.hearable.music.channel.audio',
    androidNotificationChannelName: 'Hearable Audio Playback',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
    preloadArtwork: true,
  );

  // Initialize AudioPlayerHandler singleton
  await AudioPlayerHandler.instance.initialize();

  runApp(const HearableApp());
}

class HearableApp extends StatelessWidget {
  const HearableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => PartyProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
      ],
      child: MaterialApp(
        title: 'Hearable',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainScaffold(),
      ),
    );
  }
}
