import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/game_definition.dart';
import '../models/model.dart';
import '../models/player.dart';
import '../models/word_deck.dart';
import 'game_session_factory.dart';

class RoomService {
  RoomService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final _random = Random.secure();
  late final GameSessionFactory _sessionFactory = GameSessionFactory(
    random: _random,
  );
  static const _firebaseTimeout = Duration(seconds: 12);
  static const defaultDurationSeconds = 60;
  static const minDurationSeconds = 15;
  static const maxDurationSeconds = 300;

  String? get currentPlayerId => _auth.currentUser?.uid;

  Future<String> ensurePlayerId() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return currentUser.uid;
    }

    final credential = await _withTimeout(
      _auth.signInAnonymously(),
      'Signing in anonymously timed out. Check Firebase Auth and network.',
    );
    return credential.user!.uid;
  }

  Stream<GameRoom> watchRoom(String roomCode) {
    return _roomRef(roomCode).snapshots().map(GameRoom.fromSnapshot);
  }

  Future<String> createRoom(String playerName, {String? selectedGameId}) async {
    final playerId = await ensurePlayerId();
    final trimmedName = _cleanName(playerName);
    final selectedGame = GameCatalog.byId(selectedGameId);
    final defaultDeckId = WordDecks.defaultDeckIdFor(selectedGame.deckCatalog);
    final roleId = selectedGame.roleIdToMeetDemand(const {});
    final hostData = <String, dynamic>{
      'name': trimmedName,
      'isHost': true,
      'joinedAt': FieldValue.serverTimestamp(),
    };
    if (roleId != null) {
      hostData['roleId'] = roleId;
    }

    for (var attempt = 0; attempt < 8; attempt++) {
      final code = _generateRoomCode();
      final roomRef = _roomRef(code);
      final existing = await _withTimeout(
        roomRef.get(),
        'Checking the room code timed out. Is Cloud Firestore enabled?',
      );
      if (existing.exists) {
        continue;
      }

      await _withTimeout(
        roomRef.set({
          'hostId': playerId,
          'status': RoomStatus.lobby.name,
          'selectedGameId': selectedGame.id,
          'settings': {
            GameSettingKeys.deckId: defaultDeckId,
            GameSettingKeys.categoryId: WordCategories.defaultCategoryId,
            GameSettingKeys.durationSeconds: defaultDurationSeconds,
          },
          'deckId': defaultDeckId,
          'categoryId': WordCategories.defaultCategoryId,
          'customWords': <String>[],
          'durationSeconds': defaultDurationSeconds,
          'createdAt': FieldValue.serverTimestamp(),
          'players': {playerId: hostData},
        }),
        'Creating the room timed out. Check Firestore rules and setup.',
      );

      return code;
    }

    throw StateError('Could not generate a free room code. Try again.');
  }

  Future<void> joinRoom({
    required String roomCode,
    required String playerName,
  }) async {
    final playerId = await ensurePlayerId();
    final code = roomCode.trim().toUpperCase();
    final roomRef = _roomRef(code);
    await _withTimeout(
      _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(roomRef);
        if (!snapshot.exists) {
          throw StateError('Room $code does not exist.');
        }

        final room = GameRoom.fromSnapshot(snapshot);
        final selectedGame = room.selectedGame;
        final roleId = selectedGame.roleIdToMeetDemand(room.roleCounts);
        final playerData = <String, dynamic>{
          'name': _cleanName(playerName),
          'isHost': false,
          'joinedAt': FieldValue.serverTimestamp(),
        };
        if (roleId != null) {
          playerData['roleId'] = roleId;
        }

        transaction.update(roomRef, {'players.$playerId': playerData});
      }),
      'Joining the room timed out. Check Firestore rules and setup.',
    );
  }

  Future<void> leaveRoom(String roomCode) async {
    final playerId = await ensurePlayerId();
    await _roomRef(roomCode).update({'players.$playerId': FieldValue.delete()});
  }

  Future<void> updateDeck({
    required String roomCode,
    required String deckId,
  }) async {
    final playerId = await ensurePlayerId();
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      final deck = WordDecks.byId(
        deckId,
        catalog: room.selectedGame.deckCatalog,
      );
      if (room.hostId != playerId) {
        throw StateError('Only the host can choose the deck.');
      }
      if (room.status != RoomStatus.lobby) {
        throw StateError('Decks can only be changed in the lobby.');
      }

      transaction.update(roomRef, {
        'deckId': deck.id,
        'settings.${GameSettingKeys.deckId}': deck.id,
      });
    });
  }

  Future<void> updateSelectedGame({
    required String roomCode,
    required String gameId,
  }) async {
    final playerId = await ensurePlayerId();
    final game = GameCatalog.byId(gameId);
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      if (room.hostId != playerId) {
        throw StateError('Only the host can change the game.');
      }
      if (room.status != RoomStatus.lobby) {
        throw StateError('Games can only be changed in the lobby.');
      }

      final updates = <String, dynamic>{'selectedGameId': game.id};
      final roleAssignments = _roleAssignmentsFor(game, room.players);
      for (final entry in roleAssignments.entries) {
        updates['players.${entry.key}.roleId'] =
            entry.value ?? FieldValue.delete();
      }
      if (game.wordSource == GameWordSource.deck) {
        final deckId = WordDecks.defaultDeckIdFor(game.deckCatalog);
        updates['deckId'] = deckId;
        updates['settings.${GameSettingKeys.deckId}'] = deckId;
      }
      if (game.wordSource == GameWordSource.category &&
          room.categoryId.isEmpty) {
        updates['categoryId'] = WordCategories.defaultCategoryId;
        updates['settings.${GameSettingKeys.categoryId}'] =
            WordCategories.defaultCategoryId;
      }
      transaction.update(roomRef, updates);
    });
  }

  Future<void> updatePlayerRole({
    required String roomCode,
    required String roleId,
  }) async {
    final playerId = await ensurePlayerId();
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      final game = room.selectedGame;
      if (room.status != RoomStatus.lobby) {
        throw StateError('Roles can only be changed in the lobby.');
      }
      if (room.playerById(playerId) == null) {
        throw StateError('Join the room before choosing a role.');
      }
      if (!game.hasRole(roleId)) {
        throw StateError('${game.name} does not support that role.');
      }
      final role = game.roleById(roleId);
      final currentRoleId = room.playerById(playerId)?.roleId;
      final roleCounts = room.roleCounts;
      if (currentRoleId != null && roleCounts.containsKey(currentRoleId)) {
        roleCounts[currentRoleId] = roleCounts[currentRoleId]! - 1;
      }
      if (role != null && !role.hasOpenSpot(roleCounts[role.id] ?? 0)) {
        throw StateError('${role.name} is full.');
      }

      transaction.update(roomRef, {'players.$playerId.roleId': roleId});
    });
  }

  Future<void> randomizePlayerRoles(String roomCode) async {
    final playerId = await ensurePlayerId();
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      if (room.hostId != playerId) {
        throw StateError('Only the host can randomize roles.');
      }
      if (room.status != RoomStatus.lobby) {
        throw StateError('Roles can only be randomized in the lobby.');
      }

      final roleAssignments = _roleAssignmentsFor(
        room.selectedGame,
        room.players,
        shuffle: true,
      );
      final updates = <String, dynamic>{};
      for (final entry in roleAssignments.entries) {
        updates['players.${entry.key}.roleId'] =
            entry.value ?? FieldValue.delete();
      }

      if (updates.isNotEmpty) {
        transaction.update(roomRef, updates);
      }
    });
  }

  Future<void> updateCategory({
    required String roomCode,
    required String categoryId,
  }) async {
    final playerId = await ensurePlayerId();
    final category = WordCategories.byId(categoryId);
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      if (room.hostId != playerId) {
        throw StateError('Only the host can choose the category.');
      }
      if (room.status != RoomStatus.lobby) {
        throw StateError('Categories can only be changed in the lobby.');
      }

      transaction.update(roomRef, {
        'categoryId': category.id,
        'settings.${GameSettingKeys.categoryId}': category.id,
      });
    });
  }

  Future<void> updateCustomWords({
    required String roomCode,
    required List<String> words,
  }) async {
    final playerId = await ensurePlayerId();
    final cleanWords = words
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList();
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      if (room.hostId != playerId) {
        throw StateError('Only the host can edit the deck.');
      }
      if (room.status != RoomStatus.lobby) {
        throw StateError('Decks can only be changed in the lobby.');
      }

      transaction.update(roomRef, {
        'deckId': cleanWords.isEmpty
            ? WordDecks.defaultDeckId
            : WordDecks.manualDeckId,
        'settings.${GameSettingKeys.deckId}': cleanWords.isEmpty
            ? WordDecks.defaultDeckId
            : WordDecks.manualDeckId,
        'customWords': cleanWords,
      });
    });
  }

  Future<void> updateDuration({
    required String roomCode,
    required int durationSeconds,
  }) async {
    final playerId = await ensurePlayerId();
    final roomRef = _roomRef(roomCode);
    final cleanDuration = _cleanDurationSeconds(durationSeconds);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      if (room.hostId != playerId) {
        throw StateError('Only the host can change the timer.');
      }
      if (room.status != RoomStatus.lobby) {
        throw StateError('Timer can only be changed in the lobby.');
      }

      transaction.update(roomRef, {
        'durationSeconds': cleanDuration,
        'settings.${GameSettingKeys.durationSeconds}': cleanDuration,
      });
    });
  }

  Future<void> startGame(String roomCode) async {
    final playerId = await ensurePlayerId();
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      if (room.hostId != playerId) {
        throw StateError('Only the host can start the game.');
      }
      final selectedGame = room.selectedGame;
      if (room.players.length < selectedGame.minPlayers) {
        throw StateError(
          '${selectedGame.name} needs at least ${selectedGame.minPlayers} players.',
        );
      }
      final missingRoles = room.unmetRoleRequirements;
      if (missingRoles.isNotEmpty) {
        final missingText = missingRoles
            .map(
              (role) =>
                  '${role.name} (${room.roleCounts[role.id] ?? 0}/${role.minPlayers})',
            )
            .join(', ');
        throw StateError('Fill required roles before starting: $missingText.');
      }

      final now = DateTime.now();
      final durationSeconds = selectedGame.usesTimer
          ? _cleanDurationSeconds(room.durationSeconds)
          : 0;

      transaction.update(roomRef, {
        'status': RoomStatus.inGame.name,
        'session': _sessionFactory.createSessionData(
          room: room,
          durationSeconds: durationSeconds,
          now: now,
        ),
      });
    });
  }

  Future<void> markSuccess(String roomCode) async {
    await advanceCurrentWord(
      roomCode: roomCode,
      scoreIncrement: 1,
      passIncrement: 0,
    );
  }

  Future<void> markPass(String roomCode) async {
    await advanceCurrentWord(
      roomCode: roomCode,
      scoreIncrement: 0,
      passIncrement: 1,
    );
  }

  Future<void> endGame(String roomCode) async {
    await _roomRef(roomCode).update({'status': RoomStatus.gameOver.name});
  }

  Future<void> startOutOfTheLoopQuestions(String roomCode) async {
    await _updateOutOfTheLoopAsHost(
      roomCode,
      allowedPhase: OutOfTheLoopPhase.wordReveal,
      updates: {'session.phase': OutOfTheLoopPhase.question.name},
    );
  }

  Future<void> nextOutOfTheLoopQuestion(String roomCode) async {
    final playerId = await ensurePlayerId();
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      _ensureOutOfTheLoopHost(room, playerId);
      if (room.session.phase != OutOfTheLoopPhase.question) {
        throw StateError('Questions are not active.');
      }

      final nextIndex = room.session.questionIndex + 1;
      transaction.update(roomRef, {
        'session.questionIndex': nextIndex,
        if (nextIndex >= room.session.questionOrder.length)
          'session.phase': OutOfTheLoopPhase.discussion.name,
      });
    });
  }

  Future<void> startOutOfTheLoopVote(String roomCode) async {
    await _updateOutOfTheLoopAsHost(
      roomCode,
      allowedPhase: OutOfTheLoopPhase.discussion,
      updates: {
        'session.phase': OutOfTheLoopPhase.vote.name,
        'session.votes': <String, String>{},
      },
    );
  }

  Future<void> submitOutOfTheLoopVote({
    required String roomCode,
    required String votedPlayerId,
  }) async {
    final playerId = await ensurePlayerId();
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      _ensureOutOfTheLoopGame(room);
      if (room.session.phase != OutOfTheLoopPhase.vote) {
        throw StateError('Voting is not active.');
      }
      if (room.playerById(playerId) == null) {
        throw StateError('Join the room before voting.');
      }
      if (votedPlayerId == playerId) {
        throw StateError('Vote for another player.');
      }
      if (room.playerById(votedPlayerId) == null) {
        throw StateError('That player is not in the room.');
      }

      transaction.update(roomRef, {'session.votes.$playerId': votedPlayerId});
    });
  }

  Future<void> revealOutOfTheLoop(String roomCode) async {
    final playerId = await ensurePlayerId();
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      _ensureOutOfTheLoopHost(room, playerId);
      if (room.session.phase != OutOfTheLoopPhase.vote) {
        throw StateError('Voting is not active.');
      }
      if (room.session.votes.length < room.players.length) {
        throw StateError('Wait for everyone to vote.');
      }

      transaction.update(roomRef, {
        'session.phase': OutOfTheLoopPhase.revealOutOfLoop.name,
      });
    });
  }

  Future<void> startOutOfTheLoopGuess(String roomCode) async {
    await _updateOutOfTheLoopAsHost(
      roomCode,
      allowedPhase: OutOfTheLoopPhase.revealOutOfLoop,
      updates: {'session.phase': OutOfTheLoopPhase.guess.name},
    );
  }

  Future<void> submitOutOfTheLoopGuess({
    required String roomCode,
    required String guess,
  }) async {
    final playerId = await ensurePlayerId();
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      _ensureOutOfTheLoopGame(room);
      if (room.session.phase != OutOfTheLoopPhase.guess) {
        throw StateError('Guessing is not active.');
      }
      if (playerId != room.session.focusPlayerId) {
        throw StateError('Only the out-of-the-loop player can guess.');
      }
      if (!room.session.guessOptions.contains(guess)) {
        throw StateError('Choose one of the available words.');
      }

      transaction.update(roomRef, {
        'session.outOfTheLoopGuess': guess,
        'session.outOfTheLoopSucceeded':
            guess.toLowerCase() == room.session.currentWord.toLowerCase(),
        'session.phase': OutOfTheLoopPhase.finalReveal.name,
      });
    });
  }

  Future<void> returnToLobby(String roomCode) async {
    final playerId = await ensurePlayerId();
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      if (room.hostId != playerId) {
        throw StateError('Only the host can return to the lobby.');
      }

      transaction.update(roomRef, {
        'status': RoomStatus.lobby.name,
        'session': FieldValue.delete(),
        'buildQuestion': FieldValue.delete(),
      });
    });
  }

  Future<void> advanceCurrentWord({
    required String roomCode,
    required int scoreIncrement,
    required int passIncrement,
  }) async {
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      if (room.status != RoomStatus.inGame) {
        return;
      }

      final game = room.session;
      final words = room.words;
      if (words.isEmpty) {
        throw StateError('No words are available for this round.');
      }
      final nextIndex = _sessionFactory.nextWordIndex(
        currentIndex: game.wordIndex,
        wordCount: words.length,
      );

      transaction.update(roomRef, {
        'session.score': FieldValue.increment(scoreIncrement),
        'session.passes': FieldValue.increment(passIncrement),
        'session.wordIndex': nextIndex,
        'session.currentWord': words[nextIndex],
      });
    });
  }

  DocumentReference<Map<String, dynamic>> _roomRef(String roomCode) {
    return _firestore.collection('rooms').doc(roomCode.trim().toUpperCase());
  }

  String _generateRoomCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      5,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }

  String _cleanName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Player ${_random.nextInt(900) + 100}';
    }
    return trimmed.length > 24 ? trimmed.substring(0, 24) : trimmed;
  }

  int _cleanDurationSeconds(int value) {
    return value.clamp(minDurationSeconds, maxDurationSeconds);
  }

  Map<String, String?> _roleAssignmentsFor(
    GameDefinition game,
    List<Player> players, {
    bool shuffle = false,
  }) {
    final assignments = <String, String?>{};
    final orderedPlayers = [...players];
    if (shuffle) {
      orderedPlayers.shuffle(_random);
    }

    final counts = {for (final role in game.playerRoles) role.id: 0};
    for (final player in orderedPlayers) {
      final roleId = game.roleIdToMeetDemand(counts);
      assignments[player.id] = roleId;
      if (roleId != null) {
        counts[roleId] = (counts[roleId] ?? 0) + 1;
      }
    }
    return assignments;
  }

  Future<void> _updateOutOfTheLoopAsHost(
    String roomCode, {
    required OutOfTheLoopPhase allowedPhase,
    required Map<String, dynamic> updates,
  }) async {
    final playerId = await ensurePlayerId();
    final roomRef = _roomRef(roomCode);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) {
        throw StateError('Room no longer exists.');
      }

      final room = GameRoom.fromSnapshot(snapshot);
      _ensureOutOfTheLoopHost(room, playerId);
      if (room.session.phase != allowedPhase) {
        throw StateError('That action is not available right now.');
      }

      transaction.update(roomRef, updates);
    });
  }

  void _ensureOutOfTheLoopGame(GameRoom room) {
    if (room.status != RoomStatus.inGame ||
        room.selectedGame.id != GameIds.outOfTheLoop) {
      throw StateError('Out of the Loop is not active.');
    }
  }

  void _ensureOutOfTheLoopHost(GameRoom room, String playerId) {
    _ensureOutOfTheLoopGame(room);
    if (room.hostId != playerId) {
      throw StateError('Only the host can control this phase.');
    }
  }

  Future<T> _withTimeout<T>(Future<T> future, String message) {
    return future.timeout(
      _firebaseTimeout,
      onTimeout: () => throw TimeoutException(message),
    );
  }
}
