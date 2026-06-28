import 'package:flutter/material.dart';

import '../services/room_service.dart';
import '../theme/app_theme.dart';
import 'lobby_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key, this.initialName = ''});

  final String initialName;

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _roomCodeController = TextEditingController();
  late final TextEditingController _nameController;
  final _roomService = RoomService();
  var _isJoining = false;
  String? _joinStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final roomCode = _roomCodeController.text.trim().toUpperCase();
    if (roomCode.isEmpty) {
      _showError('Enter a room code.');
      return;
    }

    setState(() {
      _isJoining = true;
      _joinStatus = 'Joining room...';
    });
    try {
      await _roomService.joinRoom(
        roomCode: roomCode,
        playerName: _nameController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LobbyScreen(roomCode: roomCode)),
      );
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _joinStatus = null;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      appBar: AppBar(title: const Text('Join room')),
      maxWidth: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AccentPill(
            icon: Icons.vpn_key,
            label: 'Room code required',
            color: AppColors.gold,
          ),
          const SizedBox(height: 16),
          Text(
            'Hop into the lobby',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the code on the host screen and pick the name your friends will see.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          GamePanel(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _roomCodeController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Room code',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  onSubmitted: (_) => _joinRoom(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  onSubmitted: (_) => _joinRoom(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isJoining ? null : _joinRoom,
                  icon: _isJoining
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Join lobby'),
                ),
                if (_joinStatus != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _joinStatus!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
