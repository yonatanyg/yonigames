import 'dart:async';

import 'package:flutter/material.dart';

import '../localization/app_language.dart';
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
  var _expiringCodenamesTurn = false;

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
    if (room.selectedGame.id == GameIds.codenames) {
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

  void _expireCodenamesTurnWhenNeeded(GameRoom room) {
    if (_expiringCodenamesTurn ||
        room.status != RoomStatus.inGame ||
        room.selectedGame.id != GameIds.codenames ||
        room.session.codenamesPhase == CodenamesPhase.complete) {
      return;
    }
    final turnEndsAt = room.session.codenamesTurnEndsAt;
    if (turnEndsAt == null || turnEndsAt.isAfter(DateTime.now())) {
      return;
    }

    _expiringCodenamesTurn = true;
    _roomService.expireCodenamesTurn(widget.roomCode).whenComplete(() {
      _expiringCodenamesTurn = false;
    });
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
          return _GameStatus(
            message: AppCopy.of(context).isHebrew
                ? 'טוען משחק...'
                : 'Loading game...',
          );
        }

        final room = snapshot.data!;
        _endWhenTimerRunsOut(room);
        _expireCodenamesTurnWhenNeeded(room);

        final session = room.session;
        final selectedGame = room.selectedGame;
        final copy = AppCopy.of(context);
        final focusPlayer = room.playerById(session.focusPlayerId);
        final currentPlayerId = _roomService.currentPlayerId;
        final isFocusPlayer = currentPlayerId == session.focusPlayerId;
        final isHost = currentPlayerId == room.hostId;
        final remainingSeconds = _remainingSeconds(session);
        final activeDeckName = _activeWordSourceName(room);

        if (room.status == RoomStatus.inGame &&
            selectedGame.id == GameIds.codenames) {
          return GameShell(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(copy.gameName(selectedGame.id)),
            ),
            maxWidth: 760,
            child: _CodenamesRound(
              room: room,
              currentPlayerId: currentPlayerId,
              isHost: isHost,
              onAction: _handleAction,
              roomService: _roomService,
            ),
          );
        }

        if (room.status == RoomStatus.inGame &&
            selectedGame.id == GameIds.outOfTheLoop) {
          return GameShell(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(copy.gameName(selectedGame.id)),
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
                  ? copy.roundComplete
                  : copy.gameName(selectedGame.id),
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
                gameName: copy.gameName(selectedGame.id),
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
                                ? copy.hiddenRoleLabel(selectedGame.id)
                                : copy.wordRoleLabel(selectedGame.id),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            focusPlayer == null
                                ? (copy.isHebrew
                                      ? 'התפקידים מחולקים.'
                                      : 'Roles are being assigned.')
                                : selectedGame.id == GameIds.outOfTheLoop
                                ? (copy.isHebrew
                                      ? '${focusPlayer.name} מחוץ לעניינים.'
                                      : '${focusPlayer.name} is out of the loop.')
                                : (copy.isHebrew
                                      ? '${focusPlayer.name} מנחש.'
                                      : '${focusPlayer.name} is guessing.'),
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
                  _HiddenWordPanel(
                    message: copy.hiddenWordMessage(selectedGame.id),
                  )
                else
                  _WordPanel(
                    word: session.currentWord,
                    deckName: activeDeckName,
                    label: copy.wordRoleLabel(selectedGame.id),
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
                        label: Text(copy.success),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleAction(
                          () => _roomService.markPass(widget.roomCode),
                        ),
                        icon: const Icon(Icons.skip_next),
                        label: Text(copy.skip),
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
                      Expanded(child: Text(copy.actionLabel(selectedGame.id))),
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
                  label: Text(copy.stopGameAndLobby),
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
                  label: Text(copy.playAnotherRound),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isHost
                      ? () => _handleAction(
                          () => _roomService.returnToLobby(widget.roomCode),
                        )
                      : null,
                  icon: const Icon(Icons.groups),
                  label: Text(copy.backToLobby),
                ),
                if (!isHost) ...[
                  const SizedBox(height: 12),
                  Text(
                    copy.isHebrew ? 'מחכים למארח...' : 'Waiting for the host...',
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
        return WordCategories.byId(
          room.categoryId,
          languageCode: room.languageCode,
        ).name;
      case GameWordSource.deck:
        if (room.session.deckId == WordDecks.manualDeckId) {
          return AppCopy.of(context).manualDeck;
        }
        return WordDecks.byId(
          room.session.deckId,
          catalog: selectedGame.deckCatalog,
          languageCode: room.languageCode,
        ).name;
      case GameWordSource.none:
        return AppCopy.of(context).gameName(selectedGame.id);
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
    final copy = AppCopy.of(context);

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
                isGameOver ? copy.roundComplete : '$gameName - $deckName',
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
                _Metric(label: copy.time, value: timerText)
              else
                _Metric(label: copy.timer, value: copy.off),
              if (usesScore) ...[
                _Metric(label: copy.score, value: '$score'),
                _Metric(label: copy.passes, value: '$passes'),
              ] else ...[
                _Metric(
                  label: copy.isHebrew ? 'מטרה' : 'Goal',
                  value: copy.isHebrew ? 'להשתלב' : 'Blend',
                ),
                _Metric(
                  label: copy.isHebrew ? 'סוד' : 'Secret',
                  value: copy.isHebrew ? 'מוגן' : 'Safe',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CodenamesRound extends StatelessWidget {
  const _CodenamesRound({
    required this.room,
    required this.currentPlayerId,
    required this.isHost,
    required this.onAction,
    required this.roomService,
  });

  final GameRoom room;
  final String? currentPlayerId;
  final bool isHost;
  final Future<void> Function(Future<void> Function()) onAction;
  final RoomService roomService;

  @override
  Widget build(BuildContext context) {
    final session = room.session;
    final roleId = currentPlayerId == null
        ? null
        : room.playerById(currentPlayerId!)?.roleId;
    final canSeeKey =
        _isCodenamesHinterRole(roleId) ||
        session.codenamesPhase == CodenamesPhase.complete;
    final canGuess =
        _isCurrentCodenamesGuesser(roleId, session) &&
        session.codenamesPhase == CodenamesPhase.guessing;
    final canGiveClue =
        _isCurrentCodenamesHinter(roleId, session) &&
        session.codenamesPhase == CodenamesPhase.clue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CodenamesHeader(room: room),
        const SizedBox(height: 16),
        if (session.codenamesPhase == CodenamesPhase.complete)
          _CodenamesResult(
            room: room,
            isHost: isHost,
            onAction: onAction,
            roomService: roomService,
          )
        else if (canGiveClue)
          _CodenamesCluePanel(
            roomCode: room.code,
            team: session.codenamesCurrentTeam,
            onAction: onAction,
            roomService: roomService,
          )
        else
          _CodenamesTurnPanel(
            room: room,
            canEndTurn:
                isHost ||
                _isCurrentCodenamesGuesser(roleId, session) ||
                _isCurrentCodenamesHinter(roleId, session),
            onAction: onAction,
            roomService: roomService,
          ),
        const SizedBox(height: 16),
        _CodenamesBoard(
          cards: session.codenamesCards,
          canSeeKey: canSeeKey,
          canGuess: canGuess,
          remainingGuesses: session.codenamesRemainingGuesses,
          onReveal: (index) => onAction(
            () => roomService.revealCodenamesCard(
              roomCode: room.code,
              cardIndex: index,
            ),
          ),
        ),
        if (isHost && session.codenamesPhase != CodenamesPhase.complete) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                onAction(() => roomService.returnToLobby(room.code)),
            icon: const Icon(Icons.stop_circle),
            label: Text(AppCopy.of(context).stopGameAndLobby),
          ),
        ],
      ],
    );
  }
}

class _CodenamesHeader extends StatelessWidget {
  const _CodenamesHeader({required this.room});

  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final session = room.session;
    final palette = AppPalette.of(context);
    final teamColor = _codenamesTeamColor(session.codenamesCurrentTeam);
    final copy = AppCopy.of(context);
    final turnTimerText = _codenamesTurnTimerText(context, session);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.ink.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view, color: teamColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  session.codenamesPhase == CodenamesPhase.complete
                      ? (copy.isHebrew ? 'המשחק הסתיים' : 'Game complete')
                      : (copy.isHebrew
                            ? 'תור ${_teamName(context, session.codenamesCurrentTeam)}'
                            : '${_teamName(context, session.codenamesCurrentTeam)} turn'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text('5x5', style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.timer, size: 18),
              const SizedBox(width: 8),
              Text(
                turnTimerText,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CodenamesTeamMetric(
                  label: _teamName(context, CodenamesTeam.red),
                  remaining: session.codenamesRedRemaining,
                  color: _codenamesTeamColor(CodenamesTeam.red),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CodenamesTeamMetric(
                  label: _teamName(context, CodenamesTeam.blue),
                  remaining: session.codenamesBlueRemaining,
                  color: _codenamesTeamColor(CodenamesTeam.blue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CodenamesTeamMetric extends StatelessWidget {
  const _CodenamesTeamMetric({
    required this.label,
    required this.remaining,
    required this.color,
  });

  final String label;
  final int remaining;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Text(
            AppCopy.of(context).isHebrew ? 'נשארו $remaining' : '$remaining left',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _CodenamesCluePanel extends StatefulWidget {
  const _CodenamesCluePanel({
    required this.roomCode,
    required this.team,
    required this.onAction,
    required this.roomService,
  });

  final String roomCode;
  final CodenamesTeam team;
  final Future<void> Function(Future<void> Function()) onAction;
  final RoomService roomService;

  @override
  State<_CodenamesCluePanel> createState() => _CodenamesCluePanelState();
}

class _CodenamesCluePanelState extends State<_CodenamesCluePanel> {
  final _clueController = TextEditingController();
  var _number = 1;

  @override
  void dispose() {
    _clueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppCopy.of(context).isHebrew
                ? 'רמז ${_teamName(context, widget.team)}'
                : '${_teamName(context, widget.team)} hinter clue',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _clueController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: AppCopy.of(context).oneWordClue,
              prefixIcon: const Icon(Icons.lightbulb),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _number,
            decoration: InputDecoration(
              labelText: AppCopy.of(context).number,
              prefixIcon: const Icon(Icons.tag),
            ),
            items: [
              const DropdownMenuItem(value: 0, child: Text('0')),
              for (var value = 1; value <= 9; value++)
                DropdownMenuItem(value: value, child: Text('$value')),
              const DropdownMenuItem(
                value: GameSession.codenamesInfinityClueNumber,
                child: Text('∞'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _number = value);
              }
            },
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => widget.onAction(
              () => widget.roomService.submitCodenamesClue(
                roomCode: widget.roomCode,
                clue: _clueController.text,
                number: _number,
              ),
            ),
            icon: const Icon(Icons.send),
            label: Text(AppCopy.of(context).giveClue),
          ),
        ],
      ),
    );
  }
}

class _CodenamesTurnPanel extends StatelessWidget {
  const _CodenamesTurnPanel({
    required this.room,
    required this.canEndTurn,
    required this.onAction,
    required this.roomService,
  });

  final GameRoom room;
  final bool canEndTurn;
  final Future<void> Function(Future<void> Function()) onAction;
  final RoomService roomService;

  @override
  Widget build(BuildContext context) {
    final session = room.session;
    final waitingForClue = session.codenamesPhase == CodenamesPhase.clue;
    final copy = AppCopy.of(context);
    final guessesText = session.codenamesHasUnlimitedGuesses
        ? (copy.isHebrew ? 'ניחושים ללא הגבלה' : 'unlimited guesses')
        : (copy.isHebrew
              ? 'נשארו ${session.codenamesRemainingGuesses} ניחושים'
              : '${session.codenamesRemainingGuesses} guesses left');

    return GamePanel(
      child: Row(
        children: [
          Icon(
            waitingForClue ? Icons.lightbulb : Icons.touch_app,
            color: _codenamesTeamColor(session.codenamesCurrentTeam),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              waitingForClue
                  ? (copy.isHebrew
                        ? 'מחכים לנותן הרמזים של ${_teamName(context, session.codenamesCurrentTeam)}.'
                        : 'Waiting for the ${_teamName(context, session.codenamesCurrentTeam).toLowerCase()} hinter.')
                  : (copy.isHebrew
                        ? 'רמז: ${session.codenamesClue} ${session.codenamesClueNumberLabel}. $guessesText.'
                        : 'Clue: ${session.codenamesClue} ${session.codenamesClueNumberLabel}. $guessesText.'),
            ),
          ),
          if (!waitingForClue && canEndTurn) ...[
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: copy.endTurn,
              onPressed: () =>
                  onAction(() => roomService.endCodenamesTurn(room.code)),
              icon: const Icon(Icons.skip_next),
            ),
          ],
        ],
      ),
    );
  }
}

class _CodenamesBoard extends StatelessWidget {
  const _CodenamesBoard({
    required this.cards,
    required this.canSeeKey,
    required this.canGuess,
    required this.remainingGuesses,
    required this.onReveal,
  });

  final List<CodenamesCard> cards;
  final bool canSeeKey;
  final bool canGuess;
  final int remainingGuesses;
  final ValueChanged<int> onReveal;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _CodenamesCardTile(
          card: card,
          showKey: canSeeKey,
          canReveal: canGuess && remainingGuesses > 0 && !card.revealed,
          onTap: () => onReveal(index),
        );
      },
    );
  }
}

class _CodenamesCardTile extends StatelessWidget {
  const _CodenamesCardTile({
    required this.card,
    required this.showKey,
    required this.canReveal,
    required this.onTap,
  });

  final CodenamesCard card;
  final bool showKey;
  final bool canReveal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final revealType = card.revealed || showKey;
    final color = revealType
        ? _codenamesCardColor(card.type, palette)
        : palette.paper;
    final textColor = revealType ? Colors.white : palette.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canReveal ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: revealType
                  ? Colors.white.withValues(alpha: 0.24)
                  : palette.ink.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              card.word,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodenamesResult extends StatelessWidget {
  const _CodenamesResult({
    required this.room,
    required this.isHost,
    required this.onAction,
    required this.roomService,
  });

  final GameRoom room;
  final bool isHost;
  final Future<void> Function(Future<void> Function()) onAction;
  final RoomService roomService;

  @override
  Widget build(BuildContext context) {
    final winner = room.session.codenamesWinner;
    final copy = AppCopy.of(context);

    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.emoji_events,
            color: winner == null
                ? AppPalette.of(context).gold
                : _codenamesTeamColor(winner),
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            winner == null
                ? (copy.isHebrew ? 'המשחק הסתיים' : 'Game complete')
                : (copy.isHebrew
                      ? '${_teamName(context, winner)} ניצחו'
                      : '${_teamName(context, winner)} wins'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isHost
                ? () => onAction(() => roomService.startGame(room.code))
                : null,
            icon: const Icon(Icons.refresh),
            label: Text(copy.newBoard),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isHost
                ? () => onAction(() => roomService.returnToLobby(room.code))
                : null,
            icon: const Icon(Icons.groups),
            label: Text(copy.backToLobby),
          ),
        ],
      ),
    );
  }
}

bool _isCodenamesHinterRole(String? roleId) {
  return roleId == GameRoleIds.redHinter || roleId == GameRoleIds.blueHinter;
}

bool _isCurrentCodenamesHinter(String? roleId, GameSession session) {
  return roleId == _codenamesHinterRoleId(session.codenamesCurrentTeam);
}

bool _isCurrentCodenamesGuesser(String? roleId, GameSession session) {
  return roleId == _codenamesGuesserRoleId(session.codenamesCurrentTeam);
}

String _codenamesHinterRoleId(CodenamesTeam team) {
  return team == CodenamesTeam.red
      ? GameRoleIds.redHinter
      : GameRoleIds.blueHinter;
}

String _codenamesGuesserRoleId(CodenamesTeam team) {
  return team == CodenamesTeam.red
      ? GameRoleIds.redGuesser
      : GameRoleIds.blueGuesser;
}

String _teamName(BuildContext context, CodenamesTeam team) {
  final copy = AppCopy.of(context);
  if (copy.isHebrew) {
    return team == CodenamesTeam.red ? 'אדום' : 'כחול';
  }
  return team == CodenamesTeam.red ? 'Red' : 'Blue';
}

String _codenamesTurnTimerText(BuildContext context, GameSession session) {
  if (session.codenamesPhase == CodenamesPhase.complete) {
    return AppCopy.of(context).isHebrew ? 'טיימר כבוי' : 'Timer off';
  }
  final endsAt = session.codenamesTurnEndsAt;
  if (endsAt == null) {
    return AppCopy.of(context).isHebrew ? 'טיימר כבוי' : 'Timer off';
  }
  final remaining = endsAt.difference(DateTime.now()).inSeconds;
  final cleanRemaining = remaining < 0 ? 0 : remaining;
  final minutes = cleanRemaining ~/ 60;
  final seconds = cleanRemaining % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

Color _codenamesTeamColor(CodenamesTeam team) {
  return team == CodenamesTeam.red
      ? const Color(0xFFE84A5F)
      : const Color(0xFF38BDF8);
}

Color _codenamesCardColor(CodenamesCardType type, AppPalette palette) {
  switch (type) {
    case CodenamesCardType.red:
      return const Color(0xFFE84A5F);
    case CodenamesCardType.blue:
      return const Color(0xFF2563EB);
    case CodenamesCardType.black:
      return const Color(0xFF111318);
    case CodenamesCardType.neutral:
      return palette.gold.withValues(alpha: 0.82);
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
            label: Text(AppCopy.of(context).stopGameAndLobby),
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
          _HiddenWordPanel(
            message: AppCopy.of(context).isHebrew
                ? 'אתה מחוץ לעניינים. נסה להשתלב והקשב טוב.'
                : 'You are out of the loop. Blend in and listen closely.',
          )
        else
          _WordPanel(
            word: room.session.currentWord,
            deckName: categoryName,
            label: AppCopy.of(context).secretWord,
          ),
        if (isHost) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onAction(
              () => roomService.startOutOfTheLoopQuestions(room.code),
            ),
            icon: const Icon(Icons.quiz),
            label: Text(AppCopy.of(context).startQuestions),
          ),
        ] else ...[
          const SizedBox(height: 16),
          _WaitingPanel(
            message: AppCopy.of(context).isHebrew
                ? 'מחכים למארח שיתחיל שאלות.'
                : 'Waiting for the host to start questions.',
          ),
        ],
      ],
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final player = room.playerById(room.session.currentQuestionPlayerId ?? '');
    final question =
        room.session.currentQuestion ??
        (AppCopy.of(context).isHebrew ? 'שאלה בדרך...' : 'Question incoming...');
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
                          ? (AppCopy.of(context).isHebrew
                                ? 'השאלה שלך'
                                : 'Your question')
                          : (AppCopy.of(context).isHebrew
                                ? 'שאלה עבור ${player?.name ?? 'שחקן'}'
                                : 'Question for ${player?.name ?? 'a player'}'),
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
            label: Text(AppCopy.of(context).nextQuestion),
          )
        else
          _WaitingPanel(
            message: AppCopy.of(context).isHebrew
                ? 'ענה בקול. המארח מתקדם.'
                : 'Answer out loud. The host advances.',
          ),
      ],
    );
  }

  Widget _buildDiscussion(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GamePanel(
          child: Row(
            children: [
              const Icon(Icons.forum, color: AppColors.deepTeal),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppCopy.of(context).isHebrew
                      ? 'דברו על מי נשמע חשוד. השחקן שמחוץ לעניינים צריך להמשיך להשתלב.'
                      : 'Discuss who sounded suspicious. The out-of-loop player should keep blending in.',
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
            label: Text(AppCopy.of(context).startVote),
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
                      AppCopy.of(context).isHebrew
                          ? 'הצביעו מי מחוץ לעניינים'
                          : 'Vote for who is out of the loop',
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
                  AppCopy.of(context).isHebrew
                      ? 'ההצבעה נשמרה.'
                      : 'Vote locked in.',
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
            label: Text(AppCopy.of(context).revealOutPlayer),
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
                AppCopy.of(context).isHebrew
                    ? '${outPlayer?.name ?? 'מישהו'} היה מחוץ לעניינים'
                    : '${outPlayer?.name ?? 'Someone'} was out of the loop',
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
            label: Text(AppCopy.of(context).startFinalGuess),
          ),
        ],
      ],
    );
  }

  Widget _buildGuess(BuildContext context, bool isOutOfTheLoop) {
    if (!isOutOfTheLoop) {
      return _WaitingPanel(
        message: AppCopy.of(context).isHebrew
            ? 'השחקן שמחוץ לעניינים מנחש את המילה הסודית.'
            : 'The out-of-loop player is guessing the secret word.',
      );
    }

    return GamePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppCopy.of(context).isHebrew
                ? 'נחש את המילה האמיתית'
                : 'Guess the real word',
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
                    ? (AppCopy.of(context).isHebrew
                          ? 'השחקן שמחוץ לעניינים ניחש נכון'
                          : 'The out-of-loop player guessed it')
                    : (AppCopy.of(context).isHebrew
                          ? 'הסוד נשאר מוסתר'
                          : 'The secret stayed hidden'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text('${AppCopy.of(context).realWord}: ${room.session.currentWord}'),
              Text(
                AppCopy.of(
                  context,
                ).guess(room.session.outOfTheLoopGuess ?? '-'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: isHost
              ? () => onAction(() => roomService.startGame(room.code))
              : null,
          icon: const Icon(Icons.refresh),
          label: Text(AppCopy.of(context).playAnotherRound),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isHost
              ? () => onAction(() => roomService.returnToLobby(room.code))
              : null,
          icon: const Icon(Icons.groups),
          label: Text(AppCopy.of(context).backToLobby),
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
                  _phaseTitle(context, phase),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  AppCopy.of(context).isHebrew
                      ? '${AppCopy.of(context).category}: $categoryName'
                      : 'Category: $categoryName',
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

  static String _phaseTitle(BuildContext context, OutOfTheLoopPhase phase) {
    final copy = AppCopy.of(context);
    switch (phase) {
      case OutOfTheLoopPhase.wordReveal:
        return copy.secretWord;
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
        Text(AppCopy.of(context).votes, style: Theme.of(context).textTheme.titleMedium),
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
            word.isEmpty
                ? (AppCopy.of(context).isHebrew ? 'מתכוננים...' : 'Get ready...')
                : word,
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
