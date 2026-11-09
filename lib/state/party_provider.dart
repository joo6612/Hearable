import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/party_sync_service.dart';

class PartyProvider extends ChangeNotifier {
  final PartySyncService _service = PartySyncService.instance;

  bool _isLoading = false;
  String? _errorMessage;
  int _peerCount = 0;
  String? _localIp;

  StreamSubscription? _peerSub;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PartyRole get role => _service.role;
  bool get isHost => _service.isHost;
  bool get isClient => _service.isClient;
  bool get isConnected => _service.isConnected;
  int get peerCount => _peerCount;
  String get partyCode => _service.partyCode;
  String? get localIp => _localIp;
  int get port => _service.port;

  PartyProvider() {
    _init();
  }

  Future<void> _init() async {
    _localIp = await _service.getDeviceIp();
    _peerSub = _service.onPeerCountChange.listen((count) {
      _peerCount = count;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Create Host Party
  Future<bool> hostParty({int port = 8080}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final success = await _service.startHost(port: port);
    _localIp = _service.localIp;
    _peerCount = _service.connectedPeerCount;
    _isLoading = false;

    if (!success) {
      _errorMessage = 'Failed to start Wi-Fi host server on port $port';
    }
    notifyListeners();
    return success;
  }

  /// Join Host Party by IP or Party Code
  Future<bool> joinParty(String targetAddress) async {
    if (targetAddress.trim().isEmpty) {
      _errorMessage = 'Please enter a valid IP address or host:port';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final success = await _service.connectAsClient(targetAddress);
    _peerCount = _service.connectedPeerCount;
    _isLoading = false;

    if (!success) {
      _errorMessage = 'Could not connect to party at $targetAddress. Ensure both devices are on the same Wi-Fi.';
    }
    notifyListeners();
    return success;
  }

  /// Leave or Stop Party
  Future<void> leaveParty() async {
    await _service.stopParty();
    _peerCount = 0;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _peerSub?.cancel();
    super.dispose();
  }
}

