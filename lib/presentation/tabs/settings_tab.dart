import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../state/playlist_provider.dart';
import '../../state/settings_provider.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final accent = settings.activeAccentColor;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Audio Tuning, Glossy Aesthetics & Local Vault',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Section A: Audio & Equalizer (Core)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildAudioEqualizerSection(context, settings, accent),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 18)),

        // Section B: Appearance & Glossy UI
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildAppearanceSection(context, settings, accent),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 18)),

        // Section C: Library & Storage
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLibraryStorageSection(context, settings, accent),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 18)),

        // Section D: Playlists & Data Transfer
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDataTransferSection(context, settings, accent),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 18)),

        // Section E: Lyrics & Display
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLyricsDisplaySection(context, settings, accent),
          ),
        ),

        // Bottom space for floating dock & mini-player
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // --- Section A: Audio & Equalizer (Core) ---
  Widget _buildAudioEqualizerSection(
    BuildContext context,
    SettingsProvider settings,
    Color accent,
  ) {
    return FrostedGlassBox(
      blurSigma: settings.glassBlurSigma,
      borderRadius: BorderRadius.circular(22),
      borderColor: Colors.white.withValues(alpha: settings.borderOpacity),
      backgroundColor: const Color(0xFF141920).withValues(alpha: 0.65),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: CupertinoIcons.tuningfork,
            title: 'Audio & Equalizer (Core)',
            accent: accent,
          ),
          const SizedBox(height: 16),

          // Master EQ Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Custom Equalizer (EQ)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('Multi-band DSP acoustic processing', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                ],
              ),
              CupertinoSwitch(
                value: settings.eqEnabled,
                activeTrackColor: accent,
                onChanged: (v) => settings.setEqEnabled(v),
              ),
            ],
          ),

          if (settings.eqEnabled) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),

            // Tone Controls: Preamp, Bass, Treble, Balance
            const Text('Tone Controls', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            _buildSliderRow(
              label: 'Preamp',
              value: settings.preamp,
              min: -12.0,
              max: 12.0,
              valueDisplay: '${settings.preamp >= 0 ? '+' : ''}${settings.preamp.toStringAsFixed(1)}dB',
              accent: accent,
              onChanged: (v) => settings.setPreamp(v),
            ),
            _buildSliderRow(
              label: 'Bass Tone',
              value: settings.bass,
              min: -10.0,
              max: 10.0,
              valueDisplay: '${settings.bass >= 0 ? '+' : ''}${settings.bass.toStringAsFixed(1)}dB',
              accent: accent,
              onChanged: (v) => settings.setBass(v),
            ),
            _buildSliderRow(
              label: 'Treble Tone',
              value: settings.treble,
              min: -10.0,
              max: 10.0,
              valueDisplay: '${settings.treble >= 0 ? '+' : ''}${settings.treble.toStringAsFixed(1)}dB',
              accent: accent,
              onChanged: (v) => settings.setTreble(v),
            ),
            _buildSliderRow(
              label: 'Balance',
              value: settings.balance,
              min: -1.0,
              max: 1.0,
              valueDisplay: settings.balance == 0
                  ? 'Center'
                  : settings.balance < 0
                      ? 'L ${(-settings.balance * 100).toInt()}%'
                      : 'R ${(settings.balance * 100).toInt()}%',
              accent: accent,
              onChanged: (v) => settings.setBalance(v),
            ),

            const SizedBox(height: 14),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),

            // Multi-band EQ (5, 10, 15, 31 bands toggle)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Multi-Band EQ Bands', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
                Row(
                  children: [5, 10, 15, 31].map((bands) {
                    final isSel = settings.eqBandCount == bands;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GestureDetector(
                        onTap: () => settings.setEqBandCount(bands),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSel ? accent : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? accent : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            '$bands',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSel ? Colors.white : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Interactive Multi-band Drag Sliders (Horizontal scrollable for 10, 15, 31 bands)
            SizedBox(
              height: 140,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: settings.currentFrequencies.map((freq) {
                    final gain = settings.getBandGain(freq);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: gain != 0 ? accent : Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 90,
                            width: 32,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 3.5,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                  activeTrackColor: accent,
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: gain,
                                  min: -12.0,
                                  max: 12.0,
                                  onChanged: (v) => settings.setBandGain(freq, v),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            freq,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // EQ Presets Selector + Custom Save
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EQ Preset', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: () => _showSaveCustomPresetDialog(context, settings),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.floppy_disk, size: 13, color: accent),
                      const SizedBox(width: 4),
                      Text('Save Preset', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                'Flat',
                'Bass Boost',
                'Vocal',
                'Rock',
                'Pop',
                'Electronic',
                'Custom',
                ...settings.savedCustomPresets.map((p) => p.name),
              ].map((preset) {
                final isSel = settings.selectedPreset == preset;
                return GestureDetector(
                  onTap: () => settings.applyPreset(preset),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSel ? accent : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel ? accent : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      preset,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 18),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Streaming Bitrate (96kbps / 160kbps / 320kbps)
          const Text('Streaming Bitrate', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: ['96kbps', '160kbps', '320kbps'].map((quality) {
              final isSel = settings.streamingQuality == quality;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => settings.setStreamingQuality(quality),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? accent : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? accent : Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          quality,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Audio Normalization / ReplayGain
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ReplayGain Normalization', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Prevents sudden volume jumps between tracks', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
              CupertinoSwitch(
                value: settings.replayGainEnabled,
                activeTrackColor: accent,
                onChanged: (v) => settings.setReplayGainEnabled(v),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Crossfade / Gapless playback (0s - 12s slider)
          _buildSliderRow(
            label: 'Crossfade Playback',
            value: settings.crossfadeDuration,
            min: 0.0,
            max: 12.0,
            valueDisplay: '${settings.crossfadeDuration.toInt()}s',
            accent: accent,
            onChanged: (v) => settings.setCrossfadeDuration(v),
          ),
        ],
      ),
    );
  }

  // --- Section B: Appearance & Glossy UI ---
  Widget _buildAppearanceSection(
    BuildContext context,
    SettingsProvider settings,
    Color accent,
  ) {
    return FrostedGlassBox(
      blurSigma: settings.glassBlurSigma,
      borderRadius: BorderRadius.circular(22),
      borderColor: Colors.white.withValues(alpha: settings.borderOpacity),
      backgroundColor: const Color(0xFF141920).withValues(alpha: 0.65),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: CupertinoIcons.sparkles,
            title: 'Appearance & Glossy UI',
            accent: accent,
          ),
          const SizedBox(height: 16),

          // App Themes
          const Text('App Theme', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildThemeCard(
                title: 'Glassmorphic Dark',
                desc: 'Deep Charcoal / Teal',
                selected: settings.currentTheme == AppThemeMode.glassmorphismDark,
                accent: accent,
                onTap: () => settings.setAppTheme(AppThemeMode.glassmorphismDark),
              ),
              _buildThemeCard(
                title: 'Pitch Black OLED',
                desc: 'AMOLED Zero Battery',
                selected: settings.currentTheme == AppThemeMode.pitchBlackOled,
                accent: accent,
                onTap: () => settings.setAppTheme(AppThemeMode.pitchBlackOled),
              ),
              _buildThemeCard(
                title: 'Dynamic Album Glow',
                desc: 'Adapts to song cover',
                selected: settings.currentTheme == AppThemeMode.dynamicAlbumArt,
                accent: accent,
                onTap: () => settings.setAppTheme(AppThemeMode.dynamicAlbumArt),
              ),
              _buildThemeCard(
                title: 'Classic Obsidian',
                desc: '#050508 Minimalist',
                selected: settings.currentTheme == AppThemeMode.classicObsidian,
                accent: accent,
                onTap: () => settings.setAppTheme(AppThemeMode.classicObsidian),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Accent Colors: Burnt Orange, Cyan, Electric Blue, Emerald, Apple Red
          const Text('Accent Color', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: AccentColorOption.values.map((option) {
              final isSel = settings.accentColor == option;
              return GestureDetector(
                onTap: () => settings.setAccentColor(option),
                child: Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: option.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: option.color.withValues(alpha: isSel ? 0.6 : 0.2),
                            blurRadius: isSel ? 14 : 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSel ? const Icon(CupertinoIcons.checkmark, size: 16, color: Colors.white) : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                        color: isSel ? Colors.white : Colors.white60,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Logo Customization Style
          const Text('Hearable Brand Logo Style', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),

          Row(
            children: LogoStyle.values.map((style) {
              final isSel = settings.logoStyle == style;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => settings.setLogoStyle(style),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel ? accent : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(style.icon, color: isSel ? Colors.white : Colors.white60, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            style.label.split(' ').first,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? Colors.white : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Glass Intensity: Blur strength slider (10px - 30px)
          _buildSliderRow(
            label: 'Glass Blur Strength',
            value: settings.glassBlurSigma,
            min: 10.0,
            max: 30.0,
            valueDisplay: '${settings.glassBlurSigma.toInt()}px',
            accent: accent,
            onChanged: (v) => settings.setGlassBlurSigma(v),
          ),

          // Border Stroke Opacity (0.05 - 0.30)
          _buildSliderRow(
            label: 'Border Stroke Opacity',
            value: settings.borderOpacity,
            min: 0.05,
            max: 0.30,
            valueDisplay: '${(settings.borderOpacity * 100).toInt()}%',
            accent: accent,
            onChanged: (v) => settings.setBorderOpacity(v),
          ),

          // Reflection Glow Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reflection Glow Effect', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
              CupertinoSwitch(
                value: settings.reflectionGlowEnabled,
                activeTrackColor: accent,
                onChanged: (v) => settings.setReflectionGlowEnabled(v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Section C: Library & Storage ---
  Widget _buildLibraryStorageSection(
    BuildContext context,
    SettingsProvider settings,
    Color accent,
  ) {
    return FrostedGlassBox(
      blurSigma: settings.glassBlurSigma,
      borderRadius: BorderRadius.circular(22),
      borderColor: Colors.white.withValues(alpha: settings.borderOpacity),
      backgroundColor: const Color(0xFF141920).withValues(alpha: 0.65),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: CupertinoIcons.folder,
            title: 'Library & Storage',
            accent: accent,
          ),
          const SizedBox(height: 16),

          // Download Storage Path
          const Text('Download Storage Path', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.device_phone_portrait, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    settings.downloadStoragePath,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Auto-Scan Local Audio Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Auto-Scan Local Audio', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Automatically detects songs on device storage', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
              CupertinoSwitch(
                value: settings.autoScanLocalAudio,
                activeTrackColor: accent,
                onChanged: (v) => settings.setAutoScanLocalAudio(v),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Manage Downloads: Cache Size + Single-click Clear
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Downloaded Audio Cache', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('${settings.downloadCacheSizeMb.toStringAsFixed(1)} MB currently cached', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
              OutlinedButton(
                onPressed: () {
                  settings.clearDownloadCache();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1E222D),
                      content: const Text('Audio cache cleared successfully', style: TextStyle(color: Colors.white)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Clear Cache', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Section D: Playlists & Data Transfer ---
  Widget _buildDataTransferSection(
    BuildContext context,
    SettingsProvider settings,
    Color accent,
  ) {
    final playlistProvider = context.watch<PlaylistProvider>();

    return FrostedGlassBox(
      blurSigma: settings.glassBlurSigma,
      borderRadius: BorderRadius.circular(22),
      borderColor: Colors.white.withValues(alpha: settings.borderOpacity),
      backgroundColor: const Color(0xFF141920).withValues(alpha: 0.65),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: CupertinoIcons.arrow_2_squarepath,
            title: 'Playlists & Data Transfer',
            accent: accent,
          ),
          const SizedBox(height: 16),

          // Import from Spotify / Apple Music
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(CupertinoIcons.link, color: accent, size: 18),
            ),
            title: const Text('Import from Spotify / Apple Music', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Paste a public playlist URL or share sheet', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            trailing: const Icon(CupertinoIcons.chevron_forward, color: Colors.white38, size: 16),
            onTap: () => _showImportLinkPrompt(context),
          ),

          const Divider(color: Colors.white12),

          // Export Local Playlists (JSON backup)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(CupertinoIcons.share_up, color: AppColors.cyan, size: 18),
            ),
            title: const Text('Export Local Playlists', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Export ${playlistProvider.count} playlists to JSON format', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            trailing: const Icon(CupertinoIcons.chevron_forward, color: Colors.white38, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1E222D),
                  content: Text('${playlistProvider.count} playlists exported to Documents/Hearable_Backup.json', style: const TextStyle(color: Colors.white)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Section E: Lyrics & Display ---
  Widget _buildLyricsDisplaySection(
    BuildContext context,
    SettingsProvider settings,
    Color accent,
  ) {
    return FrostedGlassBox(
      blurSigma: settings.glassBlurSigma,
      borderRadius: BorderRadius.circular(22),
      borderColor: Colors.white.withValues(alpha: settings.borderOpacity),
      backgroundColor: const Color(0xFF141920).withValues(alpha: 0.65),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: CupertinoIcons.captions_bubble_fill,
            title: 'Lyrics & Display',
            accent: accent,
          ),
          const SizedBox(height: 16),

          // Synced Lyrics Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Real-Time Synced Lyrics', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Karaoke follow-along with LRC timestamps', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
              CupertinoSwitch(
                value: settings.syncedLyricsEnabled,
                activeTrackColor: accent,
                onChanged: (v) => settings.setSyncedLyricsEnabled(v),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Lyrics Provider Picker
          const Text('Lyrics Provider API', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: ['LRCLIB', 'Musixmatch', 'Genius'].map((provider) {
              final isSel = settings.lyricsProvider == provider;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => settings.setLyricsProvider(provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? accent : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? accent : Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          provider,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Karaoke Follow Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Karaoke Follow Mode', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Active line auto-scroll & glow scaling', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
              CupertinoSwitch(
                value: settings.karaokeFollowMode,
                activeTrackColor: accent,
                onChanged: (v) => settings.setKaraokeFollowMode(v),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Font Size Selector: Small 18, Medium 22, Large 28
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lyrics Font Size', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  _buildSizeOption('Small', 18.0, settings, accent),
                  _buildSizeOption('Medium', 22.0, settings, accent),
                  _buildSizeOption('Large', 28.0, settings, accent),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Screen Wake Lock Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Screen Wake Lock', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Keep screen on while displaying lyrics', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
              CupertinoSwitch(
                value: settings.screenWakeLock,
                activeTrackColor: accent,
                onChanged: (v) => settings.setScreenWakeLock(v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color accent,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accent, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String valueDisplay,
    required Color accent,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Colors.white70),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: accent,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              valueDisplay,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String desc,
    required bool selected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : Colors.white.withValues(alpha: 0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(
                fontSize: 10,
                color: selected ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeOption(String label, double size, SettingsProvider settings, Color accent) {
    final isSel = settings.lyricsFontSize == size;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: () => settings.setLyricsFontSize(size),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSel ? accent : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSel ? accent : Colors.white.withValues(alpha: 0.12)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
              color: isSel ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  void _showSaveCustomPresetDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1E28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Save Custom Preset', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Preset Name (e.g. Club Spatial)',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  settings.saveCustomPreset(name);
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: settings.activeAccentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _showImportLinkPrompt(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1E28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Import Playlist', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'https://open.spotify.com/playlist/...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  await context.read<PlaylistProvider>().importPlaylistFromLink(text);
                }
                if (ctx.mounted) Navigator.pop(ctx);
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
}

