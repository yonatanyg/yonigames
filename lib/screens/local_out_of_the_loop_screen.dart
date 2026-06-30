import 'dart:math';

import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../models/model.dart';
import '../models/word_deck.dart';
import '../theme/app_theme.dart';

class LocalOutOfTheLoopScreen extends StatefulWidget {
  const LocalOutOfTheLoopScreen({
    super.key,
    required this.players,
    required this.category,
    required this.languageCode,
  });

  final List<String> players;
  final WordCategory category;
  final String languageCode;

  @override
  State<LocalOutOfTheLoopScreen> createState() =>
      _LocalOutOfTheLoopScreenState();
}

class _LocalOutOfTheLoopScreenState extends State<LocalOutOfTheLoopScreen> {
  final _random = Random.secure();
  late String _word;
  late int _outPlayerIndex;
  late List<int> _questionOrder;
  late List<String> _questions;
  late List<String> _guessOptions;
  var _phase = OutOfTheLoopPhase.wordReveal;
  var _revealPlayerIndex = 0;
  var _cardVisible = false;
  var _questionIndex = 0;
  var _voteOpen = false;
  final _votes = <int, int>{};
  String? _guess;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  String get _outPlayer => widget.players[_outPlayerIndex];

  void _startRound() {
    final words = widget.category.words;
    _word = words[_random.nextInt(words.length)];
    _outPlayerIndex = _random.nextInt(widget.players.length);
    _questionOrder = List.generate(widget.players.length, (index) => index)
      ..shuffle(_random);
    _questions = _buildQuestionList();
    _guessOptions = _buildGuessOptions();
    _phase = OutOfTheLoopPhase.wordReveal;
    _revealPlayerIndex = 0;
    _cardVisible = false;
    _questionIndex = 0;
    _voteOpen = false;
    _votes.clear();
    _guess = null;
  }

  List<String> _buildQuestionList() {
    final bank = OutOfTheLoopQuestions.forCategory(
      widget.category.id,
      languageCode: widget.languageCode,
    ).toList()..shuffle(_random);
    return List.generate(
      widget.players.length,
      (index) => bank[index % bank.length],
    );
  }

  List<String> _buildGuessOptions() {
    final options =
        widget.category.words.where((word) => word != _word).toList()
          ..shuffle(_random);
    return ([...options.take(5), _word]..shuffle(_random)).toList();
  }

  void _showSecretCard() {
    setState(() => _cardVisible = true);
  }

  void _nextSecretCard() {
    setState(() {
      if (_revealPlayerIndex >= widget.players.length - 1) {
        _phase = OutOfTheLoopPhase.question;
        _cardVisible = false;
        return;
      }
      _revealPlayerIndex++;
      _cardVisible = false;
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_questionIndex >= widget.players.length - 1) {
        _phase = OutOfTheLoopPhase.discussion;
        return;
      }
      _questionIndex++;
    });
  }

  void _startVote() {
    setState(() {
      _phase = OutOfTheLoopPhase.vote;
      _questionIndex = 0;
      _voteOpen = false;
    });
  }

  void _openVote() {
    setState(() => _voteOpen = true);
  }

  void _castVote(int votedPlayerIndex) {
    setState(() {
      final voter = _questionOrder[_questionIndex];
      _votes[voter] = votedPlayerIndex;
      if (_questionIndex >= widget.players.length - 1) {
        _phase = OutOfTheLoopPhase.revealOutOfLoop;
        _voteOpen = false;
        return;
      }
      _questionIndex++;
      _voteOpen = false;
    });
  }

  void _startGuess() {
    setState(() => _phase = OutOfTheLoopPhase.guess);
  }

  void _selectGuess(String guess) {
    setState(() {
      _guess = guess;
      _phase = OutOfTheLoopPhase.finalReveal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return GameShell(
      appBar: AppBar(title: Text(copy.localOutOfTheLoop)),
      maxWidth: 680,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LocalPhaseHeader(
            categoryName: widget.category.name,
            phase: _phase,
            playerCount: widget.players.length,
          ),
          const SizedBox(height: 18),
          switch (_phase) {
            OutOfTheLoopPhase.wordReveal => _buildWordReveal(context),
            OutOfTheLoopPhase.question => _buildQuestion(context),
            OutOfTheLoopPhase.discussion => _buildDiscussion(context),
            OutOfTheLoopPhase.vote => _buildVote(context),
            OutOfTheLoopPhase.revealOutOfLoop => _buildReveal(context),
            OutOfTheLoopPhase.guess => _buildGuess(context),
            OutOfTheLoopPhase.finalReveal => _buildFinalReveal(context),
          },
        ],
      ),
    );
  }

  Widget _buildWordReveal(BuildContext context) {
    final player = widget.players[_revealPlayerIndex];
    final isOutPlayer = _revealPlayerIndex == _outPlayerIndex;
    return GamePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _cardVisible ? player : AppCopy.of(context).passTo(player),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _cardVisible
                ? _SecretCard(
                    key: ValueKey('secret-$_revealPlayerIndex'),
                    title: isOutPlayer
                        ? AppCopy.of(context).youAreOut
                        : AppCopy.of(context).secretWord,
                    value: isOutPlayer ? AppCopy.of(context).blendIn : _word,
                    color: isOutPlayer ? AppColors.coral : AppColors.gold,
                  )
                : const _HiddenCard(key: ValueKey('hidden-secret')),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _cardVisible ? _nextSecretCard : _showSecretCard,
            icon: Icon(_cardVisible ? Icons.visibility_off : Icons.visibility),
            label: Text(
              _cardVisible
                  ? AppCopy.of(context).hideAndContinue
                  : AppCopy.of(context).showCard,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final playerIndex = _questionOrder[_questionIndex];
    final player = widget.players[playerIndex];
    final question = _questions[_questionIndex];
    return GamePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppCopy.of(
              context,
            ).questionNumber(_questionIndex + 1, widget.players.length),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(player, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          _QuestionCard(question: question),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _nextQuestion,
            icon: const Icon(Icons.navigate_next),
            label: Text(
              _questionIndex >= widget.players.length - 1
                  ? AppCopy.of(context).startDiscussion
                  : AppCopy.of(context).nextQuestion,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussion(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.forum, color: AppColors.deepTeal, size: 32),
          const SizedBox(height: 10),
          Text(
            AppCopy.of(context).discussion,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            AppCopy.of(context).discussionPrompt,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _startVote,
            icon: const Icon(Icons.how_to_vote),
            label: Text(AppCopy.of(context).startVote),
          ),
        ],
      ),
    );
  }

  Widget _buildVote(BuildContext context) {
    final voterIndex = _questionOrder[_questionIndex];
    final voter = widget.players[voterIndex];
    if (!_voteOpen) {
      return GamePanel(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppCopy.of(context).passTo(voter),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const _HiddenCard(),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openVote,
              icon: const Icon(Icons.how_to_vote),
              label: Text(
                AppCopy.of(context).isHebrew ? 'פתח הצבעה' : 'Open ballot',
              ),
            ),
          ],
        ),
      );
    }

    return GamePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppCopy.of(context).playerVotes(voter),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            AppCopy.of(context).votePrompt,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var index = 0; index < widget.players.length; index++)
                if (index != voterIndex)
                  _VoteButton(
                    player: widget.players[index],
                    onPressed: () => _castVote(index),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReveal(BuildContext context) {
    final voteCounts = <int, int>{};
    for (final votedIndex in _votes.values) {
      voteCounts[votedIndex] = (voteCounts[votedIndex] ?? 0) + 1;
    }
    final sortedVotes = List.generate(widget.players.length, (index) => index)
      ..sort((a, b) => (voteCounts[b] ?? 0).compareTo(voteCounts[a] ?? 0));

    return GamePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.radar, color: AppColors.coral, size: 34),
          const SizedBox(height: 10),
          Text(
            AppCopy.of(context).outPlayer(_outPlayer),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          for (final index in sortedVotes)
            _VoteResultRow(
              player: widget.players[index],
              votes: voteCounts[index] ?? 0,
              isOutPlayer: index == _outPlayerIndex,
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _startGuess,
            icon: const Icon(Icons.psychology),
            label: Text(
              AppCopy.of(context).isHebrew ? 'תן לו לנחש' : 'Let them guess',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuess(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppCopy.of(context).outPlayerGuesses(_outPlayer),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            AppCopy.of(context).pickRealWord,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final option in _guessOptions)
                _GuessButton(
                  option: option,
                  onPressed: () => _selectGuess(option),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinalReveal(BuildContext context) {
    final succeeded = _guess == _word;
    return GamePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            succeeded ? Icons.verified : Icons.cancel,
            color: succeeded ? AppColors.deepTeal : AppColors.coral,
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(
            succeeded
                ? AppCopy.of(context).theyGotIt
                : AppCopy.of(context).theyMissedIt,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          _SecretCard(
            title: AppCopy.of(context).correctWord,
            value: _word,
            color: succeeded ? AppColors.mint : AppColors.gold,
          ),
          if (_guess != null && _guess != _word) ...[
            const SizedBox(height: 10),
            Text(AppCopy.of(context).guess(_guess!)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => setState(_startRound),
            icon: const Icon(Icons.refresh),
            label: Text(AppCopy.of(context).playAgain),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.tune),
            label: Text(AppCopy.of(context).backToSetup),
          ),
        ],
      ),
    );
  }
}

class _LocalPhaseHeader extends StatelessWidget {
  const _LocalPhaseHeader({
    required this.categoryName,
    required this.phase,
    required this.playerCount,
  });

  final String categoryName;
  final OutOfTheLoopPhase phase;
  final int playerCount;

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          const Icon(Icons.radar, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _phaseTitle(context, phase),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  AppCopy.of(context).isHebrew
                      ? '$categoryName · $playerCount שחקנים'
                      : '$categoryName · $playerCount players',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _phaseTitle(BuildContext context, OutOfTheLoopPhase phase) {
    final copy = AppCopy.of(context);
    switch (phase) {
      case OutOfTheLoopPhase.wordReveal:
        return copy.secretReveal;
      case OutOfTheLoopPhase.question:
        return copy.questionPhase;
      case OutOfTheLoopPhase.discussion:
        return copy.discussion;
      case OutOfTheLoopPhase.vote:
        return copy.vote;
      case OutOfTheLoopPhase.revealOutOfLoop:
        return copy.reveal;
      case OutOfTheLoopPhase.guess:
        return copy.finalGuess;
      case OutOfTheLoopPhase.finalReveal:
        return copy.result;
    }
  }
}

class _HiddenCard extends StatelessWidget {
  const _HiddenCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.visibility_off,
            color: Colors.white.withValues(alpha: 0.9),
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            AppCopy.of(context).private,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SecretCard extends StatelessWidget {
  const _SecretCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.ink,
              fontSize: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        question,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: AppColors.ink),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({required this.player, required this.onPressed});

  final String player;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.person_search),
        label: Text(player, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _GuessButton extends StatelessWidget {
  const _GuessButton({required this.option, required this.onPressed});

  final String option;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: FilledButton.tonal(
        onPressed: onPressed,
        child: Text(option, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _VoteResultRow extends StatelessWidget {
  const _VoteResultRow({
    required this.player,
    required this.votes,
    required this.isOutPlayer,
  });

  final String player;
  final int votes;
  final bool isOutPlayer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            isOutPlayer ? Icons.radar : Icons.person,
            color: isOutPlayer ? AppColors.coral : AppColors.deepTeal,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(player, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            AppCopy.of(context).voteCount(votes),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}
