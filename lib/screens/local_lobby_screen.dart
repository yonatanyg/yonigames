import 'package:flutter/material.dart';

import '../models/word_deck.dart';
import '../theme/app_theme.dart';
import 'local_game_screen.dart';

class LocalLobbyScreen extends StatefulWidget {
  const LocalLobbyScreen({super.key});

  @override
  State<LocalLobbyScreen> createState() => _LocalLobbyScreenState();
}

class _LocalLobbyScreenState extends State<LocalLobbyScreen> {
  late final TextEditingController _deckController;
  var _durationSeconds = 60;

  static const _durationOptions = [30, 45, 60, 90, 120, 180, 300];

  @override
  void initState() {
    super.initState();
    _deckController = TextEditingController(
      text: WordDecks.byId(WordDecks.defaultDeckId).words.join('\n'),
    );
  }

  @override
  void dispose() {
    _deckController.dispose();
    super.dispose();
  }

  void _startGame() {
    final words = WordDecks.parseManualWords(_deckController.text);
    if (words.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one word.')));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LocalGameScreen(words: words, durationSeconds: _durationSeconds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      appBar: AppBar(title: const Text('Local setup')),
      maxWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AccentPill(
            icon: Icons.phone_android,
            label: 'One-device play',
            color: AppColors.sky,
          ),
          const SizedBox(height: 16),
          Text(
            'Build a local deck',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The host device shows the word, runs the timer, and controls Success or Pass.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          GamePanel(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _deckController,
                  minLines: 10,
                  maxLines: 14,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Words',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _durationSeconds,
                  decoration: const InputDecoration(
                    labelText: 'Round timer',
                    prefixIcon: Icon(Icons.timer),
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
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _startGame,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start local game'),
                ),
              ],
            ),
          ),
        ],
      ),
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
