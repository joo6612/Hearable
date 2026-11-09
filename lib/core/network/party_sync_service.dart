import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/party_message_model.dart';
import '../models/song_model.dart';

enum PartyRole { none, host, client }

class PartySyncEvent {
  final String action;
  final SongModel song;
  final int targetSeekMs;
  final bool isPlaying;
  final int estimatedLatencyMs;

  PartySyncEvent({
    required this.action,
    required this.song,
    required this.targetSeekMs,
    required this.isPlaying,
    required this.estimatedLatencyMs,
  });
}

class PartySyncService {
  static final PartySyncService instance = PartySyncService._();
  PartySyncService._();

  PartyRole _role = PartyRole.none;
  HttpServer? _server;
  final List<WebSocket> _connectedClients = [];
  WebSocket? _clientSocket;

  String? _localIp;
  int _port = 8080;
  String _partyCode = '';

  final StreamController<PartySyncEvent> _syncEventController = StreamController<PartySyncEvent>.broadcast();
  final StreamController<int> _peerCountController = StreamController<int>.broadcast();

  PartyRole get role => _role;
  bool get isHost => _role == PartyRole.host;
  bool get isClient => _role == PartyRole.client;
  bool get isConnected => _role != PartyRole.none;
  String? get localIp => _localIp;
  int get port => _port;
  String get partyCode => _partyCode;
  int get connectedPeerCount => _role == PartyRole.host ? _connectedClients.length : (_clientSocket != null ? 1 : 0);

  Stream<PartySyncEvent> get onSyncEvent => _syncEventController.stream;
  Stream<int> get onPeerCountChange => _peerCountController.stream;

  /// Retrieve the device's local Wi-Fi IPv4 address
  Future<String?> getDeviceIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      // Prioritize Wi-Fi interfaces (wlan, wifi, en0, etc.)
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('wlan') || name.contains('wifi') || name.contains('en')) {
          for (final addr in interface.addresses) {
            if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
              _localIp = addr.address;
              return _localIp;
            }
          }
        }
      }

      // Fallback to any active non-loopback IPv4
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        _localIp = interfaces.first.addresses.first.address;
        return _localIp;
      }
    } catch (e) {
      debugPrint('Error finding local Wi-Fi IP: $e');
    }
    _localIp = '127.0.0.1';
    return _localIp;
  }

  /// Start Host Party: Initializes WebSocket server on port 8080
  Future<bool> startHost({int port = 8080}) async {
    await stopParty();
    _port = port;
    await getDeviceIp();

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _role = PartyRole.host;
      _partyCode = _generatePartyCode();

      debugPrint('Club Host started on ws://$_localIp:$_port (Party Code: $_partyCode)');

      _server!.listen((HttpRequest request) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocketTransformer.upgrade(request).then((WebSocket ws) {
            _handleNewClient(ws);
          }).catchError((e) {
            debugPrint('Error upgrading client to WebSocket: $e');
          });
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write('Hearable Club Host is running at port $_port')
            ..close();
        }
      });

      _peerCountController.add(_connectedClients.length);
      return true;
    } catch (e) {
      debugPrint('Error starting Club Host server: $e');
      _role = PartyRole.none;
      return false;
    }
  }

  void _handleNewClient(WebSocket ws) {
    _connectedClients.add(ws);
    debugPrint('New peer joined party! Total peers: ${_connectedClients.length}');
    _peerCountController.add(_connectedClients.length);

    ws.listen(
      (data) {
        // Client heartbeats or requests
        debugPrint('Host received from peer: $data');
      },
      onDone: () {
        _connectedClients.remove(ws);
        debugPrint('Peer disconnected. Remaining: ${_connectedClients.length}');
        _peerCountController.add(_connectedClients.length);
      },
      onError: (e) {
        _connectedClients.remove(ws);
        debugPrint('Peer error: $e');
        _peerCountController.add(_connectedClients.length);
      },
    );
  }

  /// Host broadcasts playback state packet upon any song change, play/pause, or seek
  void broadcastPlaybackSync({
    required String action, // SYNC_PLAY, SYNC_PAUSE, SYNC_SEEK
    required SongModel song,
    required int seekPositionMs,
  }) {
    if (_role != PartyRole.host || _connectedClients.isEmpty) return;

    final packet = PartyMessageModel(
      action: action,
      audioUrl: song.audioUrl,
      title: song.title,
      artist: song.artist,
      imageUrl: song.artworkUrl,
      seekPositionMs: seekPositionMs,
      hostTimestamp: DateTime.now().millisecondsSinceEpoch,
      songId: song.id,
      peerCount: _connectedClients.length,
    );

    final jsonStr = packet.toJson();
    for (final client in List<WebSocket>.from(_connectedClients)) {
      try {
        client.add(jsonStr);
      } catch (e) {
        debugPrint('Error broadcasting to peer: $e');
      }
    }
  }

  /// Connect as Client to an active Host Party using IP or host:port
  Future<bool> connectAsClient(String input) async {
    await stopParty();

    String host = input.trim();
    int targetPort = _port;

    // Remove any ws:// or http:// scheme
    if (host.startsWith('ws://')) host = host.substring(5);
    if (host.startsWith('http://')) host = host.substring(7);

    // Parse host:port if provided
    if (host.contains(':')) {
      final parts = host.split(':');
      host = parts[0];
      targetPort = int.tryParse(parts[1]) ?? 8080;
    }

    final wsUri = Uri.parse('ws://$host:$targetPort');
    debugPrint('Connecting as Client to $wsUri...');

    try {
      _clientSocket = await WebSocket.connect(wsUri.toString()).timeout(const Duration(seconds: 6));
      _role = PartyRole.client;
      _partyCode = input;
      _peerCountController.add(1);

      _clientSocket!.listen(
        (data) {
          _handleHostMessage(data.toString());
        },
        onDone: () {
          debugPrint('Disconnected from Host party.');
          stopParty();
        },
        onError: (err) {
          debugPrint('Host socket error: $err');
          stopParty();
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error connecting to party host: $e');
      _role = PartyRole.none;
      return false;
    }
  }

  /// Millisecond-precision clock offset synchronization
  void _handleHostMessage(String rawJson) {
    try {
      final clientReceiveTime = DateTime.now().millisecondsSinceEpoch;
      final msg = PartyMessageModel.fromJson(rawJson);

      // Latency calculation: offset = (clientReceiveTime - hostTimestamp) / 2
      final transitDuration = clientReceiveTime - msg.hostTimestamp;
      final offset = transitDuration > 0 ? (transitDuration / 2).round() : 0;
      const bufferDelay = 60; // 60ms audio buffer lead
      final targetSeek = msg.seekPositionMs + offset + bufferDelay;

      final song = SongModel(
        id: msg.songId ?? 'club_sync_${msg.hostTimestamp}',
        title: msg.title,
        artist: msg.artist,
        album: 'Club Synced Stream',
        durationMs: targetSeek + 180000,
        audioUrl: msg.audioUrl,
        artworkUrl: msg.imageUrl,
        quality: '320kbps',
      );

      final isPlaying = msg.action == 'SYNC_PLAY';

      _syncEventController.add(PartySyncEvent(
        action: msg.action,
        song: song,
        targetSeekMs: targetSeek,
        isPlaying: isPlaying,
        estimatedLatencyMs: offset,
      ));

      if (msg.peerCount != null) {
        _peerCountController.add(msg.peerCount!);
      }
    } catch (e) {
      debugPrint('Error handling host sync packet: $e');
    }
  }

  /// Disconnect and stop party
  Future<void> stopParty() async {
    for (final ws in _connectedClients) {
      try {
        await ws.close();
      } catch (_) {}
    }
    _connectedClients.clear();

    if (_server != null) {
      try {
        await _server!.close(force: true);
      } catch (_) {}
      _server = null;
    }

    if (_clientSocket != null) {
      try {
        await _clientSocket!.close();
      } catch (_) {}
      _clientSocket = null;
    }

    _role = PartyRole.none;
    _partyCode = '';
    _peerCountController.add(0);
  }

  String _generatePartyCode() {
    final rand = Random();
    final digits = 1000 + rand.nextInt(9000);
    return 'HRB-$digits';
  }
}
