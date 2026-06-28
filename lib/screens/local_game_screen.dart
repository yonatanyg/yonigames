import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LocalGameScreen extends StatefulWidget {
  const LocalGameScreen({
    super.key,
    required this.words,
    required this.durationSeconds,
  });

  final List<String> words;
  final int durationSeconds;

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  final _random = Random.secure();
  Timer? _timer;
  late DateTime _endsAt;
  late int _wordIndex;
  var _score = 0;
  var _passes = 0;
  var _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _startRound();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      if (_remainingSeconds == 0 && !_isGameOver) {
        setState(() => _isGameOver = true);
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _remainingSeconds {
    final remaining = _endsAt.difference(DateTime.now()).inSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  String get _currentWord {
    if (widget.words.isEmpty) {
      return 'No words';
    }
    return widget.words[_wordIndex];
  }

  void _startRound() {
    _score = 0;
    _passes = 0;
    _isGameOver = false;
    _wordIndex = widget.words.isEmpty
        ? 0
        : _random.nextInt(widget.words.length);
    _endsAt = DateTime.now().add(Duration(seconds: widget.durationSeconds));
  }

  void _markSuccess() {
    if (_isGameOver) {
      return;
    }
    setState(() {
      _score++;
      _advanceWord();
    });
  }

  void _markPass() {
    if (_isGameOver) {
      return;
    }
    setState(() {
      _passes++;
      _advanceWord();
    });
  }

  void _advanceWord() {
    if (widget.words.length <= 1) {
      _wordIndex = 0;
      return;
    }

    var nextIndex = _random.nextInt(widget.words.length);
    while (nextIndex == _wordIndex) {
      nextIndex = _random.nextInt(widget.words.length);
    }
    _wordIndex = nextIndex;
  }

  void _playAgain() {
    setState(_startRound);
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      appBar: AppBar(title: const Text('Local game')),
      maxWidth: 620,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LocalScoreboard(
            score: _score,
            passes: _passes,
            remainingSeconds: _remainingSeconds,
            isGameOver: _isGameOver,
          ),
          const SizedBox(height: 24),
          _LocalWordCard(word: _currentWord, isGameOver: _isGameOver),
          const SizedBox(height: 24),
          if (_isGameOver) ...[
            FilledButton.icon(
              onPressed: _playAgain,
              icon: const Icon(Icons.refresh),
              label: const Text('Play again'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.tune),
              label: const Text('Edit deck'),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _markSuccess,
                    icon: const Icon(Icons.check),
                    label: const Text('Success'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _markPass,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Pass'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LocalScoreboard extends StatelessWidget {
  const _LocalScoreboard({
    required this.score,
    required this.passes,
    required this.remainingSeconds,
    required this.isGameOver,
  });

  final int score;
  final int passes;
  final int remainingSeconds;
  final bool isGameOver;

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final timerText = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isGameOver ? AppColors.ink : AppColors.deepTeal,
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
        children: [
          Row(
            children: [
              Icon(
                isGameOver ? Icons.flag : Icons.timer,
                color: AppColors.gold,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isGameOver ? 'Round complete' : 'Local round',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LocalMetric(label: 'Time', value: timerText),
              _LocalMetric(label: 'Score', value: '$score'),
              _LocalMetric(label: 'Passes', value: '$passes'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocalWordCard extends StatelessWidget {
  const _LocalWordCard({required this.word, required this.isGameOver});

  final String word;
  final bool isGameOver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isGameOver ? AppColors.paper : AppColors.gold,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGameOver ? Icons.lock_clock : Icons.style,
                color: AppColors.ink,
              ),
              const SizedBox(width: 8),
              Text(
                isGameOver ? 'Final score' : 'Current word',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isGameOver ? 'Time is up' : word,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.ink,
              fontSize: 38,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalMetric extends StatelessWidget {
  const _LocalMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}
