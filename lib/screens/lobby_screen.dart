import 'package:flutter/material.dart';

import '../models/model.dart';
import '../services/room_service.dart';
import 'game_screen.dart';

class LobbyScreen extends StatelessWidget {
  LobbyScreen({super.key, required this.roomCode});

  final String roomCode;
  final RoomService _roomService = RoomService();

  Future<void> _startGame(BuildContext context) async {
    try {
      await _roomService.startBuildQuestion(roomCode);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameRoom>(
      stream: _roomService.watchRoom(roomCode),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StatusScaffold(message: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const _StatusScaffold(message: 'Loading lobby...');
        }

        final room = snapshot.data!;
        if (room.status != RoomStatus.lobby) {
          return GameScreen(roomCode: roomCode);
        }

        final currentPlayerId = _roomService.currentPlayerId;
        final isHost = currentPlayerId == room.hostId;

        return Scaffold(
          appBar: AppBar(title: const Text('Lobby')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RoomCodePanel(roomCode: roomCode),
                      const SizedBox(height: 20),
                      Text(
                        'Build a Question',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'One guesser, everyone else hints. The real play happens in the room; this app tracks roles, time, and score.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Players (${room.players.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final player in room.players)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(player.name.characters.first),
                          ),
                          title: Text(player.name),
                          trailing: player.isHost
                              ? const Chip(label: Text('Host'))
                              : null,
                        ),
                      const SizedBox(height: 24),
                      if (isHost)
                        FilledButton.icon(
                          onPressed: room.players.length < 2
                              ? null
                              : () => _startGame(context),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start game'),
                        )
                      else
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Waiting for the host to start...'),
                          ),
                        ),
                      if (isHost && room.players.length < 2) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Need at least 2 players.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoomCodePanel extends StatelessWidget {
  const _RoomCodePanel({required this.roomCode});

  final String roomCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Room code', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(
            roomCode,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
      ),
    );
  }
}
