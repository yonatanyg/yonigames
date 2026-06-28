import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_definition.dart';
import '../models/model.dart';
import '../models/player.dart';
import '../models/word_deck.dart';
import '../services/room_service.dart';
import '../theme/app_theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.roomCode});

  final String roomCode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _roomService = RoomService();
  Timer? _timer;
  var _endedAutomatically = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  int _remainingSeconds(GameSession session) {
    final endsAt = session.endsAt;
    if (endsAt == null) {
      return session.durationSeconds;
    }
    final remaining = endsAt.difference(DateTime.now()).inSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  void _endWhenTimerRunsOut(GameRoom room) {
    if (room.status != RoomStatus.inGame || _endedAutomatically) {
      return;
    }
    if (!room.selectedGame.usesTimer) {
      return;
    }
    if (_remainingSeconds(room.session) > 0) {
      return;
    }

    _endedAutomatically = true;
    _roomService.endGame(widget.roomCode);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameRoom>(
      stream: _roomService.watchRoom(widget.roomCode),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _GameStatus(message: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const _GameStatus(message: 'Loading game...');
        }

        final room = snapshot.data!;
        _endWhenTimerRunsOut(room);

        final session = room.session;
        final selectedGame = room.selectedGame;
        final focusPlayer = room.playerById(session.focusPlayerId);
        final currentPlayerId = _roomService.currentPlayerId;
        final isFocusPlayer = currentPlayerId == session.focusPlayerId;
        final isHost = currentPlayerId == room.hostId;
        final remainingSeconds = _remainingSeconds(session);
        final activeDeckName = _activeWordSourceName(room);

        if (room.status == RoomStatus.inGame &&
            selectedGame.id == GameIds.outOfTheLoop) {
          return GameShell(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(selectedGame.name),
            ),
            maxWidth: 680,
            child: _OutOfTheLoopRound(
              room: room,
              currentPlayerId: currentPlayerId,
              isHost: isHost,
              categoryName: activeDeckName,
              onAction: _handleAction,
              roomService: _roomService,
            ),
          );
        }

        return GameShell(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              room.status == RoomStatus.gameOver
                  ? 'Round complete'
                  : selectedGame.name,
            ),
          ),
          maxWidth: 620,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Scoreboard(
                score: session.score,
                passes: session.passes,
                remainingSeconds: remainingSeconds,
                isGameOver: room.status == RoomStatus.gameOver,
                deckName: activeDeckName,
                gameName: selectedGame.name,
                usesScore: selectedGame.usesScore,
                usesTimer: selectedGame.usesTimer,
              ),
              const SizedBox(height: 24),
              GamePanel(
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isFocusPlayer ? AppColors.coral : AppColors.mint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isFocusPlayer
                            ? Icons.visibility
                            : Icons.tips_and_updates,
                        color: isFocusPlayer ? Colors.white : AppColors.ink,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFocusPlayer
                                ? selectedGame.hiddenRoleLabel
                                : selectedGame.wordRoleLabel,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            focusPlayer == null
                                ? 'Roles are being assigned.'
                                : selectedGame.id == GameIds.outOfTheLoop
                                ? '${focusPlayer.name} is out of the loop.'
                                : '${focusPlayer.name} is guessing.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (room.status == RoomStatus.inGame) ...[
                if (isFocusPlayer)
                  _HiddenWordPanel(message: selectedGame.hiddenWordMessage)
                else
                  _WordPanel(
                    word: session.currentWord,
                    deckName: activeDeckName,
                    label: selectedGame.wordRoleLabel,
                  ),
                const SizedBox(height: 24),
              ],
              if (room.status == RoomStatus.inGame &&
                  isFocusPlayer &&
                  selectedGame.usesScore)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _handleAction(
                          () => _roomService.markSuccess(widget.roomCode),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Success'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleAction(
                          () => _roomService.markPass(widget.roomCode),
                        ),
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Skip'),
                      ),
                    ),
                  ],
                )
              else if (room.status == RoomStatus.inGame)
                GamePanel(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.record_voice_over,
                        color: AppColors.deepTeal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(selectedGame.actionLabel)),
                    ],
                  ),
                ),
              if (room.status == RoomStatus.inGame && isHost) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _handleAction(
                    () => _roomService.returnToLobby(widget.roomCode),
                  ),
                  icon: const Icon(Icons.stop_circle),
                  label: const Text('Stop game and go to lobby'),
                ),
              ],
              if (room.status == RoomStatus.gameOver) ...[
                FilledButton.icon(
                  onPressed: isHost
                      ? () => _handleAction(
                          () => _roomService.startGame(widget.roomCode),
                        )
                      : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Play another round'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isHost
                      ? () => _handleAction(
                          () => _roomService.returnToLobby(widget.roomCode),
                        )
                      : null,
                  icon: const Icon(Icons.groups),
                  label: const Text('Back to lobby'),
                ),
                if (!isHost) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Waiting for the host...',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  String _activeWordSourceName(GameRoom room) {
    final selectedGame = room.selectedGame;
    switch (selectedGame.wordSource) {
      case GameWordSource.category:
        return WordCategories.byId(room.categoryId).name;
      case GameWordSource.deck:
        if (room.session.deckId == WordDecks.manualDeckId) {
          return 'Manual deck';
        }
        return WordDecks.byId(
          room.session.deckId,
          catalog: selectedGame.deckCatalog,
        ).name;
      case GameWordSource.none:
        return selectedGame.name;
    }
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.score,
    required this.passes,
    required this.remainingSeconds,
    required this.isGameOver,
    required this.deckName,
    required this.gameName,
    required this.usesScore,
    required this.usesTimer,
  });

  final int score;
  final int passes;
  final int remainingSeconds;
  final bool isGameOver;
  final String deckName;
  final String gameName;
  final bool usesScore;
  final bool usesTimer;

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
                isGameOver ? 'Round complete' : '$gameName - $deckName',
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
              if (usesTimer)
                _Metric(label: 'Time', value: timerText)
              else
                const _Metric(label: 'Timer', value: 'Off'),
              if (usesScore) ...[
                _Metric(label: 'Score', value: '$score'),
                _Metric(label: 'Passes', value: '$passes'),
              ] else ...[
                const _Metric(label: 'Goal', value: 'Blend'),
                const _Metric(label: 'Secret', value: 'Safe'),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OutOfTheLoopRound extends StatelessWidget {
  const _OutOfTheLoopRound({
    required this.room,
    required this.currentPlayerId,
    required this.isHost,
    required this.categoryName,
    required this.onAction,
    required this.roomService,
  });

  final GameRoom room;
  final String? currentPlayerId;
  final bool isHost;
  final String categoryName;
  final Future<void> Function(Future<void> Function()) onAction;
  final RoomService roomService;

  @override
  Widget build(BuildContext context) {
    final session = room.session;
    final outPlayer = room.playerById(session.focusPlayerId);
    final isOutOfTheLoop = currentPlayerId == session.focusPlayerId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OutOfLoopPhaseBanner(
          phase: session.phase,
          categoryName: categoryName,
          outPlayerName: outPlayer?.name,
        ),
        const SizedBox(height: 20),
        switch (session.phase) {
          OutOfTheLoopPhase.wordReveal => _buildWordReveal(
            context,
            isOutOfTheLoop,
          ),
          OutOfTheLoopPhase.question => _buildQuestion(context),
          OutOfTheLoopPhase.discussion => _buildDiscussion(context),
          OutOfTheLoopPhase.vote => _buildVote(context),
          OutOfTheLoopPhase.revealOutOfLoop => _buildReveal(context, outPlayer),
          OutOfTheLoopPhase.guess => _buildGuess(context, isOutOfTheLoop),
          OutOfTheLoopPhase.finalReveal => _buildFinalReveal(context),
        },
        if (isHost && session.phase != OutOfTheLoopPhase.finalReveal) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                onAction(() => roomService.returnToLobby(room.code)),
            icon: const Icon(Icons.stop_circle),
            label: const Text('Stop game and go to lobby'),
          ),
        ],
      ],
    );
  }

  Widget _buildWordReveal(BuildContext context, bool isOutOfTheLoop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOutOfTheLoop)
          const _HiddenWordPanel(
            message: 'You are out of the loop. Blend in and listen closely.',
          )
        else
          _WordPanel(
            word: room.session.currentWord,
            deckName: categoryName,
            label: 'Secret word',
          ),
        if (isHost) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onAction(
              () => roomService.startOutOfTheLoopQuestions(room.code),
            ),
            icon: const Icon(Icons.quiz),
            label: const Text('Start questions'),
          ),
        ] else ...[
          const SizedBox(height: 16),
          const _WaitingPanel(
            message: 'Waiting for the host to start questions.',
          ),
        ],
      ],
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final player = room.playerById(room.session.currentQuestionPlayerId ?? '');
    final question = room.session.currentQuestion ?? 'Question incoming...';
    final isCurrentPlayer = currentPlayerId == player?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GamePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCurrentPlayer
                        ? Icons.person_pin
                        : Icons.record_voice_over,
                    color: AppColors.deepTeal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isCurrentPlayer
                          ? 'Your question'
                          : 'Question for ${player?.name ?? 'a player'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${room.session.questionIndex + 1}/${room.session.questionOrder.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(question, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isHost)
          FilledButton.icon(
            onPressed: () =>
                onAction(() => roomService.nextOutOfTheLoopQuestion(room.code)),
            icon: const Icon(Icons.navigate_next),
            label: const Text('Next question'),
          )
        else
          const _WaitingPanel(message: 'Answer out loud. The host advances.'),
      ],
    );
  }

  Widget _buildDiscussion(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GamePanel(
          child: Row(
            children: [
              Icon(Icons.forum, color: AppColors.deepTeal),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Discuss who sounded suspicious. The out-of-loop player should keep blending in.',
                ),
              ),
            ],
          ),
        ),
        if (isHost) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                onAction(() => roomService.startOutOfTheLoopVote(room.code)),
            icon: const Icon(Icons.how_to_vote),
            label: const Text('Start vote'),
          ),
        ],
      ],
    );
  }

  Widget _buildVote(BuildContext context) {
    final hasVoted =
        currentPlayerId != null &&
        room.session.votes.containsKey(currentPlayerId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GamePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.how_to_vote, color: AppColors.deepTeal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Vote for who is out of the loop',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${room.session.votes.length}/${room.players.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final player in room.players)
                if (player.id != currentPlayerId) ...[
                  OutlinedButton(
                    onPressed: hasVoted || currentPlayerId == null
                        ? null
                        : () => onAction(
                            () => roomService.submitOutOfTheLoopVote(
                              roomCode: room.code,
                              votedPlayerId: player.id,
                            ),
                          ),
                    child: Text(player.name),
                  ),
                  const SizedBox(height: 8),
                ],
              if (hasVoted)
                Text(
                  'Vote locked in.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        if (isHost) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: room.session.votes.length >= room.players.length
                ? () =>
                      onAction(() => roomService.revealOutOfTheLoop(room.code))
                : null,
            icon: const Icon(Icons.visibility),
            label: const Text('Reveal out-of-loop player'),
          ),
        ],
      ],
    );
  }

  Widget _buildReveal(BuildContext context, Player? outPlayer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GamePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${outPlayer?.name ?? 'Someone'} was out of the loop',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _VoteResults(room: room),
            ],
          ),
        ),
        if (isHost) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                onAction(() => roomService.startOutOfTheLoopGuess(room.code)),
            icon: const Icon(Icons.psychology),
            label: const Text('Start final guess'),
          ),
        ],
      ],
    );
  }

  Widget _buildGuess(BuildContext context, bool isOutOfTheLoop) {
    if (!isOutOfTheLoop) {
      return const _WaitingPanel(
        message: 'The out-of-loop player is guessing the secret word.',
      );
    }

    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Guess the real word',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          for (final option in room.session.guessOptions) ...[
            FilledButton.tonal(
              onPressed: () => onAction(
                () => roomService.submitOutOfTheLoopGuess(
                  roomCode: room.code,
                  guess: option,
                ),
              ),
              child: Text(option),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildFinalReveal(BuildContext context) {
    final succeeded = room.session.outOfTheLoopSucceeded == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GamePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                succeeded ? Icons.check_circle : Icons.cancel,
                color: succeeded ? AppColors.deepTeal : AppColors.coral,
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                succeeded
                    ? 'The out-of-loop player guessed it'
                    : 'The secret stayed hidden',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text('Real word: ${room.session.currentWord}'),
              Text('Guess: ${room.session.outOfTheLoopGuess ?? '-'}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: isHost
              ? () => onAction(() => roomService.startGame(room.code))
              : null,
          icon: const Icon(Icons.refresh),
          label: const Text('Play another round'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isHost
              ? () => onAction(() => roomService.returnToLobby(room.code))
              : null,
          icon: const Icon(Icons.groups),
          label: const Text('Back to lobby'),
        ),
      ],
    );
  }
}

class _OutOfLoopPhaseBanner extends StatelessWidget {
  const _OutOfLoopPhaseBanner({
    required this.phase,
    required this.categoryName,
    required this.outPlayerName,
  });

  final OutOfTheLoopPhase phase;
  final String categoryName;
  final String? outPlayerName;

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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _phaseTitle(phase),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Category: $categoryName',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _phaseTitle(OutOfTheLoopPhase phase) {
    switch (phase) {
      case OutOfTheLoopPhase.wordReveal:
        return 'Secret word';
      case OutOfTheLoopPhase.question:
        return 'Question phase';
      case OutOfTheLoopPhase.discussion:
        return 'Discussion phase';
      case OutOfTheLoopPhase.vote:
        return 'Vote phase';
      case OutOfTheLoopPhase.revealOutOfLoop:
        return 'Reveal';
      case OutOfTheLoopPhase.guess:
        return 'Final guess';
      case OutOfTheLoopPhase.finalReveal:
        return 'Result';
    }
  }
}

class _VoteResults extends StatelessWidget {
  const _VoteResults({required this.room});

  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final votedPlayerId in room.session.votes.values) {
      counts[votedPlayerId] = (counts[votedPlayerId] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Votes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final player in room.players)
          Text('${player.name}: ${counts[player.id] ?? 0}'),
      ],
    );
  }
}

class _WaitingPanel extends StatelessWidget {
  const _WaitingPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      child: Row(
        children: [
          const Icon(Icons.hourglass_top, color: AppColors.deepTeal),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _WordPanel extends StatelessWidget {
  const _WordPanel({
    required this.word,
    required this.deckName,
    required this.label,
  });

  final String word;
  final String deckName;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.36),
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
              const Icon(Icons.visibility, color: AppColors.ink),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            word.isEmpty ? 'Get ready...' : word,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.ink,
              fontSize: 38,
            ),
          ),
          const SizedBox(height: 6),
          Text(deckName, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _HiddenWordPanel extends StatelessWidget {
  const _HiddenWordPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      child: Row(
        children: [
          const Icon(Icons.visibility_off, color: AppColors.coral),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

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

class _GameStatus extends StatelessWidget {
  const _GameStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GameShell(
      child: GamePanel(child: Text(message, textAlign: TextAlign.center)),
    );
  }
}
