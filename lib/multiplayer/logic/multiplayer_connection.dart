import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

enum MultiplayerStatus { disconnected, advertising, discovering, connected, playing }

class MultiplayerConnection extends ChangeNotifier {
  static final MultiplayerConnection instance = MultiplayerConnection._();
  MultiplayerConnection._();

  final Strategy strategy = Strategy.P2P_STAR;
  final String userName = "Player_${DateTime.now().millisecondsSinceEpoch % 1000}";
  
  MultiplayerStatus status = MultiplayerStatus.disconnected;
  String? connectedEndpointId;
  String? connectedEndpointName;

  // Discovered peers
  Map<String, String> discoveredPeers = {};

  // Callbacks for the game UI
  void Function(int lines)? onGarbageReceived;
  void Function()? onOpponentGameOver;
  void Function()? onGameStart;

  Future<void> requestPermissions() async {
    // If permission handler is added later, handle it here.
    // The plugin usually requests them automatically on startDiscovery/Advertising.
  }

  Future<void> startAdvertising() async {
    status = MultiplayerStatus.advertising;
    notifyListeners();
    try {
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: _onConnectionInit,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      status = MultiplayerStatus.disconnected;
      notifyListeners();
      debugPrint("Advertising error: $e");
    }
  }

  Future<void> startDiscovery() async {
    discoveredPeers.clear();
    status = MultiplayerStatus.discovering;
    notifyListeners();
    try {
      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          discoveredPeers[id] = name;
          notifyListeners();
        },
        onEndpointLost: (id) {
          discoveredPeers.remove(id);
          notifyListeners();
        },
      );
    } catch (e) {
      status = MultiplayerStatus.disconnected;
      notifyListeners();
      debugPrint("Discovery error: $e");
    }
  }

  Future<void> requestConnection(String endpointId) async {
    try {
      await Nearby().requestConnection(
        userName,
        endpointId,
        onConnectionInitiated: _onConnectionInit,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      debugPrint("Request connection error: $e");
    }
  }

  void _onConnectionInit(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES) {
          final str = utf8.decode(payload.bytes!);
          _handleMessage(str);
        }
      },
    );
  }

  void _onConnectionResult(String id, Status connStatus) {
    if (connStatus == Status.CONNECTED) {
      connectedEndpointId = id;
      Nearby().stopDiscovery();
      Nearby().stopAdvertising();
      status = MultiplayerStatus.connected;
      notifyListeners();
    } else {
      status = MultiplayerStatus.disconnected;
      connectedEndpointId = null;
      notifyListeners();
    }
  }

  void _onDisconnected(String id) {
    status = MultiplayerStatus.disconnected;
    connectedEndpointId = null;
    notifyListeners();
  }

  void startGame() {
    _sendMessage('START');
    status = MultiplayerStatus.playing;
    notifyListeners();
    onGameStart?.call();
  }

  void sendGarbage(int lines) {
    if (lines > 0) {
      _sendMessage('GARBAGE:$lines');
    }
  }

  void sendGameOver() {
    _sendMessage('GAMEOVER');
  }

  void _sendMessage(String msg) {
    if (connectedEndpointId != null) {
      Nearby().sendBytesPayload(
        connectedEndpointId!,
        Uint8List.fromList(utf8.encode(msg)),
      );
    }
  }

  void _handleMessage(String msg) {
    if (msg == 'START') {
      status = MultiplayerStatus.playing;
      notifyListeners();
      onGameStart?.call();
    } else if (msg.startsWith('GARBAGE:')) {
      final lines = int.tryParse(msg.split(':')[1]) ?? 0;
      onGarbageReceived?.call(lines);
    } else if (msg == 'GAMEOVER') {
      onOpponentGameOver?.call();
    }
  }

  Future<void> disconnect() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
    status = MultiplayerStatus.disconnected;
    connectedEndpointId = null;
    discoveredPeers.clear();
    notifyListeners();
  }
}
