import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../state/party_provider.dart';
import '../../state/player_provider.dart';

class ClubPartyTab extends StatefulWidget {
  const ClubPartyTab({super.key});

  @override
  State<ClubPartyTab> createState() => _ClubPartyTabState();
}

class _ClubPartyTabState extends State<ClubPartyTab> {
  final TextEditingController _ipController = TextEditingController();

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final party = context.watch<PartyProvider>();
    final player = context.watch<PlayerProvider>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Club Sync',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: Colors.white,
                      ),
                    ),
                    if (party.isConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.appleRed.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.appleRed),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.appleRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              party.isHost ? 'HOST ACTIVE' : 'SYNCED',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.appleRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Multi-Device Local Wi-Fi Synchronized Playback',
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

        // Error message if any
        if (party.errorMessage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                        color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        party.errorMessage!,
                        style: const TextStyle(
                            fontSize: 12.5, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Connected Live Dashboard
        if (party.isConnected)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildLivePartyDashboard(context, party, player),
            ),
          )
        else ...[
          // Action 1: Host Party Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: _buildHostPartyCard(context, party),
            ),
          ),

          // Action 2: Join Party Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _buildJoinPartyCard(context, party),
            ),
          ),
        ],

        // Protocol Info Banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: FrostedGlassBox(
              blurSigma: 20,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(18),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(CupertinoIcons.waveform_path_badge_plus,
                          color: AppColors.dspActiveGlow, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Millisecond Clock Offset Engine',
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hearable calculates network trip latency (RTT / 2) and applies dynamic buffer lead to achieve true phase-aligned synchronous multi-speaker playback over standard 2.4GHz / 5GHz Wi-Fi.',
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 160),
        ),
      ],
    );
  }

  Widget _buildLivePartyDashboard(
      BuildContext context, PartyProvider party, PlayerProvider player) {
    return FrostedGlassBox(
      blurSigma: 32,
      borderRadius: BorderRadius.circular(24),
      backgroundColor: Colors.white.withValues(alpha: 0.09),
      borderColor: AppColors.appleRed.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.appleRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(CupertinoIcons.radiowaves_right,
                    color: AppColors.appleRed, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.isHost
                          ? 'Hosting Wi-Fi Party'
                          : 'Connected to Party',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    Text(
                      party.isHost
                          ? 'Address: ws://${party.localIp}:${party.port}'
                          : 'Target: ${party.partyCode}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Peer count and party code chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.person_2_fill,
                        color: AppColors.glowNeonCyan, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${party.peerCount} Synced Devices',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.ticket_fill,
                        color: AppColors.badgeGold, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Code: ${party.partyCode}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.badgeGold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Currently streaming song info
          if (player.currentSong != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.music_note_2,
                      color: AppColors.appleRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.currentSong!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                        Text(
                          player.currentSong!.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    player.isPlaying ? 'BROADCASTING' : 'PAUSED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: player.isPlaying
                          ? AppColors.dspActiveGlow
                          : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // End party button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(CupertinoIcons.stop_circle, size: 18),
              label: Text(party.isHost ? 'Stop Host Server' : 'Leave Party'),
              onPressed: () => party.leaveParty(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostPartyCard(BuildContext context, PartyProvider party) {
    return FrostedGlassBox(
      blurSigma: 28,
      borderRadius: BorderRadius.circular(24),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      borderColor: Colors.white.withValues(alpha: 0.16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.appleRed, AppColors.glowPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.appleRed.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.antenna_radiowaves_left_right,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Host Party',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Broadcast WebSocket on port 8080',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Make your phone the audio master. All friends on the same Wi-Fi connect to your IP and stream in millisecond synchronization.',
            style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appleRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 6,
              ),
              onPressed:
                  party.isLoading ? null : () => party.hostParty(port: 8080),
              child: party.isLoading
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : const Text(
                      'Create Party Host (Port 8080)',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinPartyCard(BuildContext context, PartyProvider party) {
    return FrostedGlassBox(
      blurSigma: 28,
      borderRadius: BorderRadius.circular(24),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      borderColor: Colors.white.withValues(alpha: 0.16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.glowBlue, AppColors.glowNeonCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.glowBlue.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.link,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Join Party',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sync with Host IP / Party Code',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Enter Host IP (e.g. 192.168.1.15:8080)',
                hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                border: InputBorder.none,
                icon: Icon(CupertinoIcons.antenna_radiowaves_left_right,
                    color: Colors.white38, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: party.isLoading
                  ? null
                  : () => party.joinParty(_ipController.text),
              child: party.isLoading
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : const Text(
                      'Connect & Sync Stream',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
