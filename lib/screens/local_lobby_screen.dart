import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../models/game_definition.dart';
import '../models/word_deck.dart';
import '../theme/app_theme.dart';
import 'local_game_screen.dart';
import 'local_out_of_the_loop_screen.dart';
import 'local_password_game_screen.dart';

class LocalLobbyScreen extends StatefulWidget {
  const LocalLobbyScreen({super.key});

  @override
  State<LocalLobbyScreen> createState() => _LocalLobbyScreenState();
}

class _LocalLobbyScreenState extends State<LocalLobbyScreen> {
  late final TextEditingController _deckController;
  late final TextEditingController _playersController;
  var _selectedGameId = GameIds.buildQuestion;
  var _languageCode = GameLanguage.defaultCode;
  var _passwordDeckId = WordDecks.defaultPasswordDeckId;
  var _categoryId = WordCategories.defaultCategoryId;
  var _durationSeconds = 60;

  static const _durationOptions = [30, 45, 60, 90, 120, 180, 300];
  static const _localGameIds = [
    GameIds.buildQuestion,
    GameIds.password,
    GameIds.outOfTheLoop,
  ];

  @override
  void initState() {
    super.initState();
    _deckController = TextEditingController(
      text: WordDecks.byId(
        WordDecks.defaultDeckId,
        languageCode: _languageCode,
      ).words.join('\n'),
    );
    _playersController = TextEditingController(
      text: const ['Player 1', 'Player 2', 'Player 3'].join('\n'),
    );
  }

  @override
  void dispose() {
    _deckController.dispose();
    _playersController.dispose();
    super.dispose();
  }

  void _startGame() {
    switch (_selectedGameId) {
      case GameIds.password:
        _startPassword();
        return;
      case GameIds.outOfTheLoop:
        _startOutOfTheLoop();
        return;
      case GameIds.buildQuestion:
      default:
        _startBuildQuestion();
        return;
    }
  }

  void _startBuildQuestion() {
    final copy = AppCopy.of(context);
    final words = WordDecks.parseManualWords(_deckController.text);
    if (words.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.addAtLeastOneWord)));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LocalGameScreen(words: words, durationSeconds: _durationSeconds),
      ),
    );
  }

  void _startPassword() {
    final deck = WordDecks.byId(
      _passwordDeckId,
      catalog: GameDeckCatalog.password,
      languageCode: _languageCode,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocalPasswordGameScreen(words: deck.words),
      ),
    );
  }

  void _startOutOfTheLoop() {
    final copy = AppCopy.of(context);
    final players = WordDecks.parseManualWords(_playersController.text);
    if (players.length < GameCatalog.byId(GameIds.outOfTheLoop).minPlayers) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.addAtLeastThreePlayers)));
      return;
    }

    final category = WordCategories.byId(
      _categoryId,
      languageCode: _languageCode,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocalOutOfTheLoopScreen(
          players: players,
          category: category,
          languageCode: _languageCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedGame = GameCatalog.byId(_selectedGameId);
    final copy = AppCopy.of(context);
    return GameShell(
      appBar: AppBar(title: Text(copy.localSetup)),
      maxWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AccentPill(
            icon: Icons.phone_android,
            label: copy.oneDevicePlay,
            color: AppColors.sky,
          ),
          const SizedBox(height: 16),
          Text(
            copy.chooseLocalGame,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            copy.localSetupDescription,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          _LocalGameSelector(
            selectedGameId: _selectedGameId,
            onSelected: (gameId) => setState(() => _selectedGameId = gameId),
          ),
          const SizedBox(height: 16),
          GamePanel(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  copy.gameName(selectedGame.id),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(copy.gameLobbyDescription(selectedGame.id)),
                const SizedBox(height: 18),
                _buildLanguageSetting(),
                const SizedBox(height: 14),
                _buildSelectedSettings(selectedGame),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _startGame,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(copy.startGameName(copy.gameName(selectedGame.id))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSettings(GameDefinition selectedGame) {
    final copy = AppCopy.of(context);
    switch (selectedGame.id) {
      case GameIds.password:
        return DropdownButtonFormField<String>(
          initialValue: _passwordDeckId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: copy.passwordDeck,
            prefixIcon: const Icon(Icons.style),
          ),
          items: [
            for (final deck in WordDecks.allFor(
              GameDeckCatalog.password,
              languageCode: _languageCode,
            ))
              DropdownMenuItem(value: deck.id, child: Text(deck.name)),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _passwordDeckId = value);
            }
          },
        );
      case GameIds.outOfTheLoop:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: copy.category,
                prefixIcon: const Icon(Icons.category),
              ),
              items: [
                for (final category in WordCategories.allFor(
                  languageCode: _languageCode,
                ))
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _categoryId = value);
                }
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _playersController,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: copy.players,
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.groups),
              ),
            ),
          ],
        );
      case GameIds.buildQuestion:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _deckController,
              minLines: 8,
              maxLines: 12,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: copy.words,
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _durationSeconds,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: copy.roundTimer,
                prefixIcon: const Icon(Icons.timer),
              ),
              items: [
                for (final option in _durationOptions)
                  DropdownMenuItem(
                    value: option,
                    child: Text(_formatDuration(option)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _durationSeconds = value);
                }
              },
            ),
          ],
        );
    }
  }

  Widget _buildLanguageSetting() {
    final copy = AppCopy.of(context);
    return DropdownButtonFormField<String>(
      initialValue: _languageCode,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: copy.language,
        prefixIcon: const Icon(Icons.language),
      ),
      items: [
        for (final language in GameLanguage.all)
          DropdownMenuItem(
            value: language.code,
            child: Text(language.nativeName, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value == null || value == _languageCode) {
          return;
        }
        setState(() {
          _languageCode = value;
          _deckController.text = WordDecks.byId(
            WordDecks.defaultDeckId,
            languageCode: _languageCode,
          ).words.join('\n');
        });
      },
    );
  }

  String _formatDuration(int seconds) {
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

class _LocalGameSelector extends StatelessWidget {
  const _LocalGameSelector({
    required this.selectedGameId,
    required this.onSelected,
  });

  final String selectedGameId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final gameId in _LocalLobbyScreenState._localGameIds)
          _LocalGameChoice(
            game: GameCatalog.byId(gameId),
            isSelected: selectedGameId == gameId,
            onTap: () => onSelected(gameId),
          ),
      ],
    );
  }
}

class _LocalGameChoice extends StatelessWidget {
  const _LocalGameChoice({
    required this.game,
    required this.isSelected,
    required this.onTap,
  });

  final GameDefinition game;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final copy = AppCopy.of(context);
    return SizedBox(
      width: 170,
      child: Material(
        color: isSelected
            ? palette.mint.withValues(alpha: 0.34)
            : palette.paper,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? palette.deepTeal
                    : palette.ink.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(_iconForGame(game.id), color: palette.deepTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    copy.gameName(game.id),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForGame(String gameId) {
    switch (gameId) {
      case GameIds.password:
        return Icons.password;
      case GameIds.outOfTheLoop:
        return Icons.radar;
      case GameIds.buildQuestion:
      default:
        return Icons.question_answer;
    }
  }
}
