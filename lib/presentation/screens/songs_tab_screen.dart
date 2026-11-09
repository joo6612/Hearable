import 'package:flutter/material.dart';
import '../tabs/songs_tab.dart';

export '../tabs/songs_tab.dart';

/// SongsTabScreen alias for direct route and test integration
class SongsTabScreen extends StatelessWidget {
  const SongsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SongsTab();
  }
}

