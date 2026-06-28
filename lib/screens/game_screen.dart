import 'dart:async';

import 'package:flutter/material.dart';

import '../models/model.dart';
import '../services/room_service.dart';

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

  int _remainingSeconds(BuildQuestionGame game) {
    final endsAt = game.endsAt;
    if (endsAt == null) {
      return game.durationSeconds;
    }
    final remaining = endsAt.difference(DateTime.now()).inSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  void _endWhenTimerRunsOut(GameRoom room) {
    if (room.status != RoomStatus.inGame || _endedAutomatically) {
      return;
    }
    if (_remainingSeconds(room.buildQuestion) > 0) {
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

        final game = room.buildQuestion;
        final guesser = room.playerById(game.guesserId);
        final currentPlayerId = _roomService.currentPlayerId;
        final isGuesser = currentPlayerId == game.guesserId;
        final isHost = currentPlayerId == room.hostId;
        final remainingSeconds = _remainingSeconds(game);

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              room.status == RoomStatus.gameOver
                  ? 'Round complete'
                  : 'Build a Question',
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Scoreboard(
                        score: game.score,
                        skips: game.skips,
                        remainingSeconds: remainingSeconds,
                        isGameOver: room.status == RoomStatus.gameOver,
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isGuesser
                                    ? 'You are guessing'
                                    : 'You are hinting',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                guesser == null
                                    ? 'The guesser is being assigned.'
                                    : '${guesser.name} is the guesser.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (room.status == RoomStatus.inGame && isGuesser)
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _handleAction(
                                  () =>
                                      _roomService.markCorrect(widget.roomCode),
                                ),
                                icon: const Icon(Icons.check),
                                label: const Text('Success'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _handleAction(
                                  () => _roomService.markSkip(widget.roomCode),
                                ),
                                icon: const Icon(Icons.skip_next),
                                label: const Text('Skip'),
                              ),
                            ),
                          ],
                        )
                      else if (room.status == RoomStatus.inGame)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Give hints out loud. The guesser controls success and skip.',
                            ),
                          ),
                        ),
                      if (room.status == RoomStatus.gameOver) ...[
                        FilledButton.icon(
                          onPressed: isHost
                              ? () => _handleAction(
                                  () => _roomService.startBuildQuestion(
                                    widget.roomCode,
                                  ),
                                )
                              : null,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Play another round'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: isHost
                              ? () => _handleAction(
                                  () => _roomService.returnToLobby(
                                    widget.roomCode,
                                  ),
                                )
                              : null,
                          icon: const Icon(Icons.groups),
                          label: const Text('Back to lobby'),
                        ),
                        if (!isHost) ...[
                          const SizedBox(height: 12),
                          const Text('Waiting for the host...'),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.score,
    required this.skips,
    required this.remainingSeconds,
    required this.isGameOver,
  });

  final int score;
  final int skips;
  final int remainingSeconds;
  final bool isGameOver;

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final timerText = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isGameOver
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Metric(label: 'Time', value: timerText),
          _Metric(label: 'Score', value: '$score'),
          _Metric(label: 'Skips', value: '$skips'),
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
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
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
    return Scaffold(
      body: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
      ),
    );
  }
}
