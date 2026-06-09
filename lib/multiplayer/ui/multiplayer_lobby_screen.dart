import 'package:flutter/material.dart';
import 'package:cubix_blast/multiplayer/logic/multiplayer_connection.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  final _connection = MultiplayerConnection.instance;

  @override
  void initState() {
    super.initState();
    _connection.addListener(_onStateChange);
    _connection.requestPermissions();
  }

  @override
  void dispose() {
    _connection.removeListener(_onStateChange);
    _connection.disconnect();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
    
    if (_connection.status == MultiplayerStatus.playing) {
      Navigator.pushReplacementNamed(context, '/multiplayer_match');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      appBar: AppBar(
        title: const Text('MULTIJUGADOR LOCAL'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Tu nombre: ${_connection.userName}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 40),
            
            if (_connection.status == MultiplayerStatus.disconnected) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Crear Partida (Host)'),
                onPressed: _connection.startAdvertising,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Buscar Partida (Join)'),
                onPressed: _connection.startDiscovery,
              ),
            ],
            
            if (_connection.status == MultiplayerStatus.advertising) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Esperando oponente...', style: TextStyle(color: Colors.white)),
            ],
            
            if (_connection.status == MultiplayerStatus.discovering) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Buscando partidas...', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              ..._connection.discoveredPeers.entries.map((e) => ListTile(
                title: Text(e.value, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.link, color: Colors.greenAccent),
                onTap: () => _connection.requestConnection(e.key),
              )),
            ],
            
            if (_connection.status == MultiplayerStatus.connected) ...[
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
              const SizedBox(height: 16),
              const Text('¡Conectado!', style: TextStyle(color: Colors.white, fontSize: 24)),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                onPressed: _connection.startGame,
                child: const Text('¡INICIAR BATALLA!'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
