import 'package:cloud_firestore/cloud_firestore.dart';

import 'game_definition.dart';
import 'player.dart';
import 'word_deck.dart';

enum RoomStatus {
  lobby,
  inGame,
  gameOver;

  static RoomStatus fromString(String? value) {
    return RoomStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => RoomStatus.lobby,
    );
  }
}

enum OutOfTheLoopPhase {
  wordReveal,
  question,
  discussion,
  vote,
  revealOutOfLoop,
  guess,
  finalReveal;

  static OutOfTheLoopPhase fromString(String? value) {
    return OutOfTheLoopPhase.values.firstWhere(
      (phase) => phase.name == value,
      orElse: () => OutOfTheLoopPhase.wordReveal,
    );
  }
}

class GameSession {
  const GameSession({
    required this.focusPlayerId,
    required this.score,
    required this.passes,
    required this.round,
    required this.durationSeconds,
    required this.deckId,
    required this.currentWord,
    required this.wordIndex,
    required this.phase,
    required this.questionIndex,
    required this.questionOrder,
    required this.questions,
    required this.votes,
    required this.guessOptions,
    this.outOfTheLoopGuess,
    this.outOfTheLoopSucceeded,
    this.endsAt,
  });

  final String focusPlayerId;
  final int score;
  final int passes;
  final int round;
  final int durationSeconds;
  final String deckId;
  final String currentWord;
  final int wordIndex;
  final OutOfTheLoopPhase phase;
  final int questionIndex;
  final List<String> questionOrder;
  final List<String> questions;
  final Map<String, String> votes;
  final List<String> guessOptions;
  final String? outOfTheLoopGuess;
  final bool? outOfTheLoopSucceeded;
  final DateTime? endsAt;

  factory GameSession.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const GameSession(
        focusPlayerId: '',
        score: 0,
        passes: 0,
        round: 1,
        durationSeconds: 60,
        deckId: WordDecks.defaultDeckId,
        currentWord: '',
        wordIndex: 0,
        phase: OutOfTheLoopPhase.wordReveal,
        questionIndex: 0,
        questionOrder: [],
        questions: [],
        votes: {},
        guessOptions: [],
      );
    }

    final endsAtValue = data['endsAt'];
    return GameSession(
      focusPlayerId:
          data['focusPlayerId'] as String? ??
          data['guesserId'] as String? ??
          '',
      score: data['score'] as int? ?? 0,
      passes: data['passes'] as int? ?? data['skips'] as int? ?? 0,
      round: data['round'] as int? ?? 1,
      durationSeconds: data['durationSeconds'] as int? ?? 60,
      deckId: data['deckId'] as String? ?? WordDecks.defaultDeckId,
      currentWord: data['currentWord'] as String? ?? '',
      wordIndex: data['wordIndex'] as int? ?? 0,
      phase: OutOfTheLoopPhase.fromString(data['phase'] as String?),
      questionIndex: data['questionIndex'] as int? ?? 0,
      questionOrder: (data['questionOrder'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      questions: (data['questions'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      votes: Map<String, String>.from(data['votes'] as Map? ?? const {}),
      guessOptions: (data['guessOptions'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      outOfTheLoopGuess: data['outOfTheLoopGuess'] as String?,
      outOfTheLoopSucceeded: data['outOfTheLoopSucceeded'] as bool?,
      endsAt: endsAtValue is Timestamp ? endsAtValue.toDate() : null,
    );
  }

  String? get currentQuestionPlayerId {
    if (questionIndex < 0 || questionIndex >= questionOrder.length) {
      return null;
    }
    return questionOrder[questionIndex];
  }

  String? get currentQuestion {
    if (questionIndex < 0 || questionIndex >= questions.length) {
      return null;
    }
    return questions[questionIndex];
  }

  bool get answeredAllQuestions {
    return questionIndex >= questionOrder.length;
  }
}

class GameRoom {
  const GameRoom({
    required this.code,
    required this.hostId,
    required this.status,
    required this.selectedGameId,
    required this.deckId,
    required this.categoryId,
    required this.customWords,
    required this.durationSeconds,
    required this.settings,
    required this.players,
    required this.session,
  });

  final String code;
  final String hostId;
  final RoomStatus status;
  final String selectedGameId;
  final String deckId;
  final String categoryId;
  final List<String> customWords;
  final int durationSeconds;
  final Map<String, dynamic> settings;
  final List<Player> players;
  final GameSession session;

  factory GameRoom.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final playersMap = Map<String, dynamic>.from(
      data['players'] as Map? ?? const <String, dynamic>{},
    );

    final players =
        playersMap.entries
            .map(
              (entry) => Player.fromMap(
                entry.key,
                Map<String, dynamic>.from(entry.value as Map),
              ),
            )
            .toList()
          ..sort((a, b) {
            if (a.isHost != b.isHost) {
              return a.isHost ? -1 : 1;
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

    return GameRoom(
      code: doc.id,
      hostId: data['hostId'] as String? ?? '',
      status: RoomStatus.fromString(data['status'] as String?),
      selectedGameId:
          data['selectedGameId'] as String? ??
          data['selectedGame'] as String? ??
          GameIds.buildQuestion,
      deckId:
          (data['settings'] as Map?)?[GameSettingKeys.deckId] as String? ??
          data['deckId'] as String? ??
          data['buildQuestionDeckId'] as String? ??
          WordDecks.defaultDeckId,
      categoryId:
          (data['settings'] as Map?)?[GameSettingKeys.categoryId] as String? ??
          data['categoryId'] as String? ??
          WordCategories.defaultCategoryId,
      customWords:
          (data['customWords'] as List? ??
                  data['buildQuestionCustomWords'] as List? ??
                  const [])
              .whereType<String>()
              .toList(),
      durationSeconds:
          (data['settings'] as Map?)?[GameSettingKeys.durationSeconds]
              as int? ??
          data['durationSeconds'] as int? ??
          data['buildQuestionDurationSeconds'] as int? ??
          60,
      settings: Map<String, dynamic>.from(data['settings'] as Map? ?? const {}),
      players: players,
      session: GameSession.fromMap(
        data['session'] == null && data['buildQuestion'] == null
            ? null
            : Map<String, dynamic>.from(
                (data['session'] ?? data['buildQuestion']) as Map,
              ),
      ),
    );
  }

  List<String> get words {
    switch (selectedGame.wordSource) {
      case GameWordSource.deck:
        if (deckId == WordDecks.manualDeckId && customWords.isNotEmpty) {
          return customWords;
        }
        return WordDecks.byId(deckId, catalog: selectedGame.deckCatalog).words;
      case GameWordSource.category:
        return WordCategories.byId(categoryId).words;
      case GameWordSource.none:
        return const [];
    }
  }

  GameDefinition get selectedGame => GameCatalog.byId(selectedGameId);

  Map<String, int> get roleCounts {
    final counts = <String, int>{};
    for (final player in players) {
      final role = selectedGame.roleById(player.roleId);
      if (role == null) {
        continue;
      }
      counts[role.id] = (counts[role.id] ?? 0) + 1;
    }
    return counts;
  }

  List<GamePlayerRole> get unmetRoleRequirements {
    return selectedGame.unmetRoleRequirements(roleCounts);
  }

  bool get hasRequiredRoles {
    return unmetRoleRequirements.isEmpty;
  }

  Player? playerById(String id) {
    for (final player in players) {
      if (player.id == id) {
        return player;
      }
    }
    return null;
  }
}
