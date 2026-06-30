import 'package:flutter/material.dart';

import '../models/game_definition.dart';
import '../services/room_service.dart';
import '../theme/app_theme.dart';
import 'lobby_screen.dart';

class GameDashboardScreen extends StatefulWidget {
  const GameDashboardScreen({super.key, required this.playerName});

  final String playerName;

  @override
  State<GameDashboardScreen> createState() => _GameDashboardScreenState();
}

class _GameDashboardScreenState extends State<GameDashboardScreen> {
  final _roomService = RoomService();
  String? _creatingGameId;

  Future<void> _createRoom(GameDefinition game) async {
    setState(() => _creatingGameId = game.id);
    try {
      final roomCode = await _roomService.createRoom(
        widget.playerName,
        selectedGameId: game.id,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LobbyScreen(roomCode: roomCode)),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _creatingGameId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      appBar: AppBar(title: const Text('Choose game')),
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AccentPill(
            icon: Icons.dashboard_customize,
            label: 'Game dashboard',
            color: AppColors.gold,
          ),
          const SizedBox(height: 16),
          Text(
            'Pick the first game',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'You can still change the game later from the lobby.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final useTwoColumns = constraints.maxWidth >= 620;
              final tileWidth = useTwoColumns
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final game in GameCatalog.all)
                    SizedBox(
                      width: tileWidth,
                      child: _DashboardGameTile(
                        game: game,
                        isCreating: _creatingGameId == game.id,
                        isDisabled: _creatingGameId != null,
                        onTap: () => _createRoom(game),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardGameTile extends StatelessWidget {
  const _DashboardGameTile({
    required this.game,
    required this.isCreating,
    required this.isDisabled,
    required this.onTap,
  });

  final GameDefinition game;
  final bool isCreating;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: palette.paper.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.ink.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: palette.brightness == Brightness.dark ? 0.24 : 0.1,
              ),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(game.assetPath, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    game.shortDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: isDisabled ? null : onTap,
                    icon: isCreating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(isCreating ? 'Creating room...' : 'Start room'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
