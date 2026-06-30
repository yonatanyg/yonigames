import 'package:cloud_firestore/cloud_firestore.dart';

import 'game_definition.dart';
import '../localization/app_language.dart';
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

enum CodenamesTeam {
  red,
  blue;

  static CodenamesTeam fromString(String? value) {
    return CodenamesTeam.values.firstWhere(
      (team) => team.name == value,
      orElse: () => CodenamesTeam.red,
    );
  }
}

enum CodenamesCardType {
  red,
  blue,
  neutral,
  black;

  static CodenamesCardType fromString(String? value) {
    return CodenamesCardType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => CodenamesCardType.neutral,
    );
  }
}

enum CodenamesPhase {
  clue,
  guessing,
  complete;

  static CodenamesPhase fromString(String? value) {
    return CodenamesPhase.values.firstWhere(
      (phase) => phase.name == value,
      orElse: () => CodenamesPhase.clue,
    );
  }
}

class CodenamesCard {
  const CodenamesCard({
    required this.word,
    required this.type,
    required this.revealed,
  });

  final String word;
  final CodenamesCardType type;
  final bool revealed;

  factory CodenamesCard.fromMap(Map<String, dynamic> data) {
    return CodenamesCard(
      word: data['word'] as String? ?? '',
      type: CodenamesCardType.fromString(data['type'] as String?),
      revealed: data['revealed'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'word': word, 'type': type.name, 'revealed': revealed};
  }

  CodenamesCard copyWith({bool? revealed}) {
    return CodenamesCard(
      word: word,
      type: type,
      revealed: revealed ?? this.revealed,
    );
  }
}

class GameSession {
  static const codenamesInfinityClueNumber = -1;

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
    required this.codenamesPhase,
    required this.codenamesCurrentTeam,
    required this.codenamesFirstTeam,
    required this.codenamesCards,
    required this.codenamesRedRemaining,
    required this.codenamesBlueRemaining,
    required this.codenamesClue,
    required this.codenamesClueNumber,
    required this.codenamesGuessesTaken,
    required this.codenamesHinterSeconds,
    required this.codenamesGuesserSeconds,
    this.outOfTheLoopGuess,
    this.outOfTheLoopSucceeded,
    this.codenamesWinner,
    this.codenamesTurnEndsAt,
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
  final CodenamesPhase codenamesPhase;
  final CodenamesTeam codenamesCurrentTeam;
  final CodenamesTeam codenamesFirstTeam;
  final List<CodenamesCard> codenamesCards;
  final int codenamesRedRemaining;
  final int codenamesBlueRemaining;
  final String codenamesClue;
  final int codenamesClueNumber;
  final int codenamesGuessesTaken;
  final int codenamesHinterSeconds;
  final int codenamesGuesserSeconds;
  final String? outOfTheLoopGuess;
  final bool? outOfTheLoopSucceeded;
  final CodenamesTeam? codenamesWinner;
  final DateTime? codenamesTurnEndsAt;
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
        codenamesPhase: CodenamesPhase.clue,
        codenamesCurrentTeam: CodenamesTeam.red,
        codenamesFirstTeam: CodenamesTeam.red,
        codenamesCards: [],
        codenamesRedRemaining: 0,
        codenamesBlueRemaining: 0,
        codenamesClue: '',
        codenamesClueNumber: 0,
        codenamesGuessesTaken: 0,
        codenamesHinterSeconds: 60,
        codenamesGuesserSeconds: 90,
      );
    }

    final endsAtValue = data['endsAt'];
    final codenamesTurnEndsAtValue = data['codenamesTurnEndsAt'];
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
      codenamesPhase: CodenamesPhase.fromString(
        data['codenamesPhase'] as String?,
      ),
      codenamesCurrentTeam: CodenamesTeam.fromString(
        data['codenamesCurrentTeam'] as String?,
      ),
      codenamesFirstTeam: CodenamesTeam.fromString(
        data['codenamesFirstTeam'] as String?,
      ),
      codenamesCards: (data['codenamesCards'] as List? ?? const [])
          .whereType<Map>()
          .map((card) => CodenamesCard.fromMap(Map<String, dynamic>.from(card)))
          .toList(),
      codenamesRedRemaining: data['codenamesRedRemaining'] as int? ?? 0,
      codenamesBlueRemaining: data['codenamesBlueRemaining'] as int? ?? 0,
      codenamesClue: data['codenamesClue'] as String? ?? '',
      codenamesClueNumber: data['codenamesClueNumber'] as int? ?? 0,
      codenamesGuessesTaken: data['codenamesGuessesTaken'] as int? ?? 0,
      codenamesHinterSeconds: data['codenamesHinterSeconds'] as int? ?? 60,
      codenamesGuesserSeconds: data['codenamesGuesserSeconds'] as int? ?? 90,
      outOfTheLoopGuess: data['outOfTheLoopGuess'] as String?,
      outOfTheLoopSucceeded: data['outOfTheLoopSucceeded'] as bool?,
      codenamesWinner: data['codenamesWinner'] == null
          ? null
          : CodenamesTeam.fromString(data['codenamesWinner'] as String?),
      codenamesTurnEndsAt: codenamesTurnEndsAtValue is Timestamp
          ? codenamesTurnEndsAtValue.toDate()
          : null,
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

  int get codenamesMaxGuesses {
    if (codenamesHasUnlimitedGuesses) {
      return 999;
    }
    return codenamesClueNumber + 1;
  }

  bool get codenamesHasUnlimitedGuesses {
    return codenamesClueNumber == 0 ||
        codenamesClueNumber == codenamesInfinityClueNumber;
  }

  int get codenamesRemainingGuesses {
    if (codenamesHasUnlimitedGuesses) {
      return 999;
    }
    final remaining = codenamesMaxGuesses - codenamesGuessesTaken;
    return remaining < 0 ? 0 : remaining;
  }

  String get codenamesClueNumberLabel {
    if (codenamesClueNumber == codenamesInfinityClueNumber) {
      return '∞';
    }
    return '$codenamesClueNumber';
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
    required this.languageCode,
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
  final String languageCode;
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
      languageCode:
          (data['settings'] as Map?)?[GameSettingKeys.languageCode]
              as String? ??
          data['languageCode'] as String? ??
          GameLanguage.defaultCode,
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
        return WordDecks.byId(
          deckId,
          catalog: selectedGame.deckCatalog,
          languageCode: languageCode,
        ).words;
      case GameWordSource.category:
        return WordCategories.byId(
          categoryId,
          languageCode: languageCode,
        ).words;
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

  int settingInt(String key, int fallback) {
    final value = settings[key];
    return value is int ? value : fallback;
  }

  int get codenamesHinterSeconds {
    return settingInt(GameSettingKeys.codenamesHinterSeconds, 60);
  }

  int get codenamesGuesserSeconds {
    return settingInt(GameSettingKeys.codenamesGuesserSeconds, 90);
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
