import 'package:flutter/material.dart';

import '../services/room_service.dart';
import 'join_room_screen.dart';
import 'lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  var _isCreating = false;
  String? _createStatus;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() {
      _isCreating = true;
      _createStatus = 'Creating room...';
    });
    try {
      final roomCode = await RoomService().createRoom(_nameController.text);
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LobbyScreen(roomCode: roomCode)),
      );
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _createStatus = null;
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'YoniGames',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: const Color(0xFF163B35),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Social games for one couch, many phones, and no overthinking.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _createRoom(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isCreating ? null : _createRoom,
                    icon: _isCreating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Create room'),
                  ),
                  if (_createStatus != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _createStatus!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              JoinRoomScreen(initialName: _nameController.text),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Join with code'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
