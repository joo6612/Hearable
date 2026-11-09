import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Set immersive dark obsidian system overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Allow edge-to-edge system navigation
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
