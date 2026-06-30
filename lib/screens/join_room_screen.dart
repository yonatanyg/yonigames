import 'package:flutter/material.dart';

import '../localization/app_language.dart';
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
    final copy = AppCopy.of(context);
    if (roomCode.isEmpty) {
      _showError(copy.enterRoomCode);
      return;
    }

    setState(() {
      _isJoining = true;
      _joinStatus = copy.joiningRoom;
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
    final copy = AppCopy.of(context);
    return GameShell(
      appBar: AppBar(title: Text(copy.joinRoom)),
      maxWidth: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AccentPill(
            icon: Icons.vpn_key,
            label: copy.roomCodeRequired,
            color: AppColors.gold,
          ),
          const SizedBox(height: 16),
          Text(
            copy.hopIntoLobby,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            copy.joinInstructions,
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
                  decoration: InputDecoration(
                    labelText: copy.roomCode,
                    prefixIcon: const Icon(Icons.tag),
                  ),
                  onSubmitted: (_) => _joinRoom(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: copy.yourName,
                    prefixIcon: const Icon(Icons.person),
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
                  label: Text(copy.joinLobby),
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
