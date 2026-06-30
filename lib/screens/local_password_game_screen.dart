import 'dart:math';

import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../theme/app_theme.dart';

class LocalPasswordGameScreen extends StatefulWidget {
  const LocalPasswordGameScreen({super.key, required this.words});

  final List<String> words;

  @override
  State<LocalPasswordGameScreen> createState() =>
      _LocalPasswordGameScreenState();
}

class _LocalPasswordGameScreenState extends State<LocalPasswordGameScreen> {
  final _random = Random.secure();
  late int _wordIndex;
  var _score = 0;
  var _passes = 0;

  @override
  void initState() {
    super.initState();
    _wordIndex = widget.words.isEmpty
        ? 0
        : _random.nextInt(widget.words.length);
  }

  String get _currentWord {
    if (widget.words.isEmpty) {
      return AppCopy.of(context).noPasswords;
    }
    return widget.words[_wordIndex];
  }

  void _markSuccess() {
    setState(() {
      _score++;
      _advanceWord();
    });
  }

  void _markPass() {
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

  void _reset() {
    setState(() {
      _score = 0;
      _passes = 0;
      _wordIndex = widget.words.isEmpty
          ? 0
          : _random.nextInt(widget.words.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return GameShell(
      appBar: AppBar(title: Text(copy.localPassword)),
      maxWidth: 620,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PasswordScoreboard(score: _score, passes: _passes),
          const SizedBox(height: 24),
          _PasswordCard(word: _currentWord),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _markSuccess,
                  icon: const Icon(Icons.check),
                  label: Text(copy.success),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _markPass,
                  icon: const Icon(Icons.skip_next),
                  label: Text(copy.pass),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
            label: Text(copy.resetScore),
          ),
        ],
      ),
    );
  }
}

class _PasswordScoreboard extends StatelessWidget {
  const _PasswordScoreboard({required this.score, required this.passes});

  final int score;
  final int passes;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.deepTeal,
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
              const Icon(Icons.password, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              Text(
                copy.oneDeviceRound,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PasswordMetric(label: copy.score, value: '$score'),
              _PasswordMetric(label: copy.passes, value: '$passes'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PasswordCard extends StatelessWidget {
  const _PasswordCard({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.gold,
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
              const Icon(Icons.style, color: AppColors.ink),
              const SizedBox(width: 8),
              Text(copy.password, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            word,
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

class _PasswordMetric extends StatelessWidget {
  const _PasswordMetric({required this.label, required this.value});

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
