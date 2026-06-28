import 'package:flutter/material.dart';

import '../models/game_definition.dart';
import '../models/model.dart';
import '../models/player.dart';
import '../models/word_deck.dart';
import '../services/room_service.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.roomCode});

  final String roomCode;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final RoomService _roomService = RoomService();
  final _manualDeckController = TextEditingController();
  var _manualDeckSeeded = false;
  var _isSavingDeck = false;

  @override
  void dispose() {
    _manualDeckController.dispose();
    super.dispose();
  }

  Future<void> _startGame(BuildContext context) async {
    try {
      await _roomService.startGame(widget.roomCode);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _updateDeck(BuildContext context, String deckId) async {
    try {
      await _roomService.updateDeck(roomCode: widget.roomCode, deckId: deckId);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _updateCategory(BuildContext context, String categoryId) async {
    try {
      await _roomService.updateCategory(
        roomCode: widget.roomCode,
        categoryId: categoryId,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _updateSelectedGame(BuildContext context, String gameId) async {
    try {
      await _roomService.updateSelectedGame(
        roomCode: widget.roomCode,
        gameId: gameId,
      );
    } catch (error) {
      if (context.mounted) {
        _showError(context, error.toString());
      }
    }
  }

  Future<void> _saveManualDeck(BuildContext context) async {
    final words = WordDecks.parseManualWords(_manualDeckController.text);
    if (words.isEmpty) {
      _showError(context, 'Add at least one word.');
      return;
    }

    setState(() => _isSavingDeck = true);
    try {
      await _roomService.updateCustomWords(
        roomCode: widget.roomCode,
        words: words,
      );
    } catch (error) {
      if (context.mounted) {
        _showError(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingDeck = false);
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateDuration(
    BuildContext context,
    int durationSeconds,
  ) async {
    try {
      await _roomService.updateDuration(
        roomCode: widget.roomCode,
        durationSeconds: durationSeconds,
      );
    } catch (error) {
      if (context.mounted) {
        _showError(context, error.toString());
      }
    }
  }

  Future<void> _updatePlayerRole(BuildContext context, String roleId) async {
    try {
      await _roomService.updatePlayerRole(
        roomCode: widget.roomCode,
        roleId: roleId,
      );
    } catch (error) {
      if (context.mounted) {
        _showError(context, error.toString());
      }
    }
  }

  Future<void> _randomizeRoles(BuildContext context) async {
    try {
      await _roomService.randomizePlayerRoles(widget.roomCode);
    } catch (error) {
      if (context.mounted) {
        _showError(context, error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameRoom>(
      stream: _roomService.watchRoom(widget.roomCode),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StatusScaffold(message: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const _StatusScaffold(message: 'Loading lobby...');
        }

        final room = snapshot.data!;
        if (room.status != RoomStatus.lobby) {
          return GameScreen(roomCode: widget.roomCode);
        }

        if (!_manualDeckSeeded && room.customWords.isNotEmpty) {
          _manualDeckController.text = room.customWords.join('\n');
          _manualDeckSeeded = true;
        }

        final currentPlayerId = _roomService.currentPlayerId;
        final isHost = currentPlayerId == room.hostId;
        final selectedGame = room.selectedGame;
        final isManualDeck = room.deckId == WordDecks.manualDeckId;
        final selectedDeck = isManualDeck
            ? null
            : WordDecks.byId(room.deckId, catalog: selectedGame.deckCatalog);
        final selectedCategory = WordCategories.byId(room.categoryId);
        final canStart =
            room.players.length >= selectedGame.minPlayers &&
            room.hasRequiredRoles &&
            (selectedGame.wordSource != GameWordSource.deck ||
                !isManualDeck ||
                room.customWords.isNotEmpty);

        return GameShell(
          appBar: AppBar(title: const Text('Lobby')),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RoomCodePanel(roomCode: widget.roomCode),
              const SizedBox(height: 20),
              _GameSelectorPanel(
                selectedGame: selectedGame,
                isHost: isHost,
                onSelected: (gameId) => _updateSelectedGame(context, gameId),
              ),
              const SizedBox(height: 18),
              _GameSettingsPanel(
                game: selectedGame,
                selectedDeck: selectedDeck,
                selectedCategory: selectedCategory,
                durationSeconds: room.durationSeconds,
                isHost: isHost,
                manualWordCount: room.customWords.length,
                manualController: _manualDeckController,
                isSaving: _isSavingDeck,
                onDeckChanged: (deckId) => _updateDeck(context, deckId),
                onCategoryChanged: (categoryId) =>
                    _updateCategory(context, categoryId),
                onDurationChanged: (durationSeconds) =>
                    _updateDuration(context, durationSeconds),
                onSaveManualDeck: () => _saveManualDeck(context),
              ),
              const SizedBox(height: 24),
              _RoleBoard(
                game: selectedGame,
                players: room.players,
                roleCounts: room.roleCounts,
                currentPlayerId: currentPlayerId,
                isHost: isHost,
                onRoleSelected: (roleId) => _updatePlayerRole(context, roleId),
                onRandomize: () => _randomizeRoles(context),
              ),
              const SizedBox(height: 16),
              if (isHost)
                FilledButton.icon(
                  onPressed: canStart ? () => _startGame(context) : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start game'),
                )
              else
                const GamePanel(
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_top, color: AppColors.deepTeal),
                      SizedBox(width: 12),
                      Expanded(child: Text('Waiting for the host to start...')),
                    ],
                  ),
                ),
              if (isHost && room.players.length < selectedGame.minPlayers) ...[
                const SizedBox(height: 8),
                Text(
                  'Need at least ${selectedGame.minPlayers} players.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (isHost && !room.hasRequiredRoles) ...[
                const SizedBox(height: 8),
                Text(
                  _missingRoleText(room),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (isHost &&
                  selectedGame.wordSource == GameWordSource.deck &&
                  isManualDeck &&
                  room.customWords.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Add words before starting.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GameSelectorPanel extends StatelessWidget {
  const _GameSelectorPanel({
    required this.selectedGame,
    required this.isHost,
    required this.onSelected,
  });

  final GameDefinition selectedGame;
  final bool isHost;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 86,
              height: 64,
              child: Image.asset(selectedGame.assetPath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Game', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                if (isHost)
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedGame.id,
                    decoration: const InputDecoration(
                      labelText: 'Selected game',
                      prefixIcon: Icon(Icons.casino),
                    ),
                    items: [
                      for (final game in GameCatalog.all)
                        DropdownMenuItem(
                          value: game.id,
                          child: Text(
                            game.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (gameId) {
                      if (gameId != null && gameId != selectedGame.id) {
                        onSelected(gameId);
                      }
                    },
                  )
                else
                  Text(
                    selectedGame.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                const SizedBox(height: 8),
                Text(
                  selectedGame.lobbyDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCodePanel extends StatelessWidget {
  const _RoomCodePanel({required this.roomCode});

  final String roomCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AccentPill(
            icon: Icons.ios_share,
            label: 'Share this code',
            color: AppColors.gold,
          ),
          const SizedBox(height: 12),
          SelectableText(
            roomCode,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameSettingsPanel extends StatelessWidget {
  const _GameSettingsPanel({
    required this.game,
    required this.selectedDeck,
    required this.selectedCategory,
    required this.durationSeconds,
    required this.isHost,
    required this.manualWordCount,
    required this.manualController,
    required this.isSaving,
    required this.onDeckChanged,
    required this.onCategoryChanged,
    required this.onDurationChanged,
    required this.onSaveManualDeck,
  });

  final GameDefinition game;
  final WordDeck? selectedDeck;
  final WordCategory selectedCategory;
  final int durationSeconds;
  final bool isHost;
  final int manualWordCount;
  final TextEditingController manualController;
  final bool isSaving;
  final ValueChanged<String> onDeckChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onSaveManualDeck;

  static const _durationOptions = [30, 45, 60, 90, 120, 180, 300];

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.deepTeal),
              const SizedBox(width: 10),
              Text(
                'Game settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in game.settings.indexed) ...[
            if (entry.$1 > 0) const SizedBox(height: 12),
            _buildSetting(context, entry.$2),
          ],
        ],
      ),
    );
  }

  Widget _buildSetting(BuildContext context, GameSettingDefinition setting) {
    switch (setting.type) {
      case GameSettingType.deck:
        return _buildDeckSetting(context, setting);
      case GameSettingType.category:
        return _buildCategorySetting(context, setting);
      case GameSettingType.timer:
        return _buildTimerSetting(context, setting);
    }
  }

  Widget _buildDeckSetting(
    BuildContext context,
    GameSettingDefinition setting,
  ) {
    final deckName = selectedDeck?.name ?? 'Manual deck';
    final deckDescription =
        selectedDeck?.description ?? '$manualWordCount saved words.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isHost)
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: selectedDeck?.id ?? WordDecks.manualDeckId,
            decoration: InputDecoration(
              labelText: setting.label,
              prefixIcon: const Icon(Icons.library_books),
            ),
            items: [
              for (final deck in WordDecks.allFor(game.deckCatalog))
                DropdownMenuItem(
                  value: deck.id,
                  child: Text(deck.name, overflow: TextOverflow.ellipsis),
                ),
              const DropdownMenuItem(
                value: WordDecks.manualDeckId,
                child: Text('Manual deck', overflow: TextOverflow.ellipsis),
              ),
            ],
            onChanged: (deckId) {
              if (deckId == null) {
                return;
              }
              if (deckId == WordDecks.manualDeckId) {
                onSaveManualDeck();
                return;
              }
              if (deckId != selectedDeck?.id) {
                onDeckChanged(deckId);
              }
            },
          )
        else
          _ReadonlySetting(
            icon: Icons.library_books,
            label: setting.label,
            value: deckName,
            description: deckDescription,
          ),
        if (isHost) ...[
          const SizedBox(height: 10),
          Text(deckDescription, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          TextField(
            controller: manualController,
            minLines: 4,
            maxLines: 7,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Manual words',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.edit_note),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isSaving ? null : onSaveManualDeck,
            icon: isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save manual deck'),
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySetting(
    BuildContext context,
    GameSettingDefinition setting,
  ) {
    if (!isHost) {
      return _ReadonlySetting(
        icon: Icons.category,
        label: setting.label,
        value: selectedCategory.name,
        description: selectedCategory.description,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: selectedCategory.id,
          decoration: InputDecoration(
            labelText: setting.label,
            prefixIcon: const Icon(Icons.category),
          ),
          items: [
            for (final category in WordCategories.all)
              DropdownMenuItem(
                value: category.id,
                child: Text(category.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (categoryId) {
            if (categoryId != null && categoryId != selectedCategory.id) {
              onCategoryChanged(categoryId);
            }
          },
        ),
        const SizedBox(height: 10),
        Text(
          selectedCategory.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildTimerSetting(
    BuildContext context,
    GameSettingDefinition setting,
  ) {
    final options = {..._durationOptions, durationSeconds}.toList()..sort();

    if (!isHost) {
      return _ReadonlySetting(
        icon: Icons.timer,
        label: setting.label,
        value: _formatDuration(durationSeconds),
      );
    }

    return DropdownButtonFormField<int>(
      isExpanded: true,
      initialValue: durationSeconds,
      decoration: InputDecoration(
        labelText: setting.label,
        prefixIcon: const Icon(Icons.hourglass_bottom),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(
              _formatDuration(option),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) {
        if (value != null && value != durationSeconds) {
          onDurationChanged(value);
        }
      },
    );
  }

  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes == 0) {
      return '${remainingSeconds}s';
    }
    if (remainingSeconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${remainingSeconds}s';
  }
}

class _ReadonlySetting extends StatelessWidget {
  const _ReadonlySetting({
    required this.icon,
    required this.label,
    required this.value,
    this.description,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.deepTeal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleBoard extends StatelessWidget {
  const _RoleBoard({
    required this.game,
    required this.players,
    required this.roleCounts,
    required this.currentPlayerId,
    required this.isHost,
    required this.onRoleSelected,
    required this.onRandomize,
  });

  final GameDefinition game;
  final List<Player> players;
  final Map<String, int> roleCounts;
  final String? currentPlayerId;
  final bool isHost;
  final ValueChanged<String> onRoleSelected;
  final VoidCallback onRandomize;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.groups, color: AppColors.deepTeal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Roles (${players.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (isHost && game.playerRoles.length > 1)
                IconButton.filledTonal(
                  tooltip: 'Randomize roles',
                  onPressed: onRandomize,
                  icon: const Icon(Icons.shuffle),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 520 ? 1 : 2;
              final boxWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final role in game.playerRoles)
                    SizedBox(
                      width: boxWidth,
                      child: _RoleBox(
                        role: role,
                        members: _membersFor(role),
                        count: roleCounts[role.id] ?? 0,
                        currentPlayerId: currentPlayerId,
                        onSelected: () => onRoleSelected(role.id),
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

  List<Player> _membersFor(GamePlayerRole role) {
    return players
        .where((player) => game.roleById(player.roleId)?.id == role.id)
        .toList();
  }
}

class _RoleBox extends StatelessWidget {
  const _RoleBox({
    required this.role,
    required this.members,
    required this.count,
    required this.currentPlayerId,
    required this.onSelected,
  });

  final GamePlayerRole role;
  final List<Player> members;
  final int count;
  final String? currentPlayerId;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final roleColor = Color(role.colorValue);
    final isCurrentRole = members.any((player) => player.id == currentPlayerId);
    final isFull = !role.hasOpenSpot(count);
    final canJoin = currentPlayerId != null && !isCurrentRole && !isFull;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: canJoin ? onSelected : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minHeight: 148),
          decoration: BoxDecoration(
            color: isCurrentRole
                ? roleColor.withValues(alpha: 0.22)
                : AppColors.paper.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentRole
                  ? roleColor
                  : AppColors.ink.withValues(alpha: 0.08),
              width: isCurrentRole ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.groups, color: roleColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      role.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _RoleCountBadge(role: role, count: count),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                role.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (members.isEmpty)
                Text(
                  isFull ? 'Full' : 'Open spot',
                  style: Theme.of(context).textTheme.labelLarge,
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final player in members)
                      _MemberChip(
                        player: player,
                        isCurrentPlayer: player.id == currentPlayerId,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCountBadge extends StatelessWidget {
  const _RoleCountBadge({required this.role, required this.count});

  final GamePlayerRole role;
  final int count;

  @override
  Widget build(BuildContext context) {
    final label = role.maxPlayers != null
        ? '$count/${role.maxPlayers}'
        : role.minPlayers > 0
        ? '$count/${role.minPlayers}+'
        : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.player, required this.isCurrentPlayer});

  final Player player;
  final bool isCurrentPlayer;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        child: Text(
          player.name.characters.isEmpty ? '?' : player.name.characters.first,
        ),
      ),
      label: Text(
        isCurrentPlayer ? '${player.name} (You)' : player.name,
        overflow: TextOverflow.ellipsis,
      ),
      side: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
    );
  }
}

String _missingRoleText(GameRoom room) {
  final parts = room.unmetRoleRequirements
      .map((role) {
        final count = room.roleCounts[role.id] ?? 0;
        return '${role.name} $count/${role.minPlayers}';
      })
      .join(', ');
  return 'Fill required roles: $parts.';
}

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GameShell(
      child: GamePanel(child: Text(message, textAlign: TextAlign.center)),
    );
  }
}
