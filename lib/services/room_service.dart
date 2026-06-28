import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/model.dart';

class RoomService {
  RoomService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final _random = Random.secure();
  static const _firebaseTimeout = Duration(seconds: 12);

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

  Future<String> createRoom(String playerName) async {
    final playerId = await ensurePlayerId();
    final trimmedName = _cleanName(playerName);

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
          'selectedGame': 'build_a_question',
          'createdAt': FieldValue.serverTimestamp(),
          'players': {
            playerId: {
              'name': trimmedName,
              'isHost': true,
              'joinedAt': FieldValue.serverTimestamp(),
            },
          },
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
    final room = await _withTimeout(
      roomRef.get(),
      'Looking up room $code timed out. Check Cloud Firestore.',
    );

    if (!room.exists) {
      throw StateError('Room $code does not exist.');
    }

    await _withTimeout(
      roomRef.update({
        'players.$playerId': {
          'name': _cleanName(playerName),
          'isHost': false,
          'joinedAt': FieldValue.serverTimestamp(),
        },
      }),
      'Joining the room timed out. Check Firestore rules and setup.',
    );
  }

  Future<void> leaveRoom(String roomCode) async {
    final playerId = await ensurePlayerId();
    await _roomRef(roomCode).update({'players.$playerId': FieldValue.delete()});
  }

  Future<void> startBuildQuestion(String roomCode) async {
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
      if (room.players.length < 2) {
        throw StateError('Build a Question needs at least 2 players.');
      }

      final guesserIndex =
          DateTime.now().millisecondsSinceEpoch % room.players.length;
      final guesser = room.players[guesserIndex];
      final now = DateTime.now();

      transaction.update(roomRef, {
        'status': RoomStatus.inGame.name,
        'buildQuestion': {
          'type': 'build_a_question',
          'guesserId': guesser.id,
          'score': 0,
          'skips': 0,
          'round': 1,
          'durationSeconds': 60,
          'startedAt': Timestamp.fromDate(now),
          'endsAt': Timestamp.fromDate(now.add(const Duration(seconds: 60))),
        },
      });
    });
  }

  Future<void> markCorrect(String roomCode) async {
    await _roomRef(
      roomCode,
    ).update({'buildQuestion.score': FieldValue.increment(1)});
  }

  Future<void> markSkip(String roomCode) async {
    await _roomRef(
      roomCode,
    ).update({'buildQuestion.skips': FieldValue.increment(1)});
  }

  Future<void> endGame(String roomCode) async {
    await _roomRef(roomCode).update({'status': RoomStatus.gameOver.name});
  }

  Future<void> returnToLobby(String roomCode) async {
    await _roomRef(roomCode).update({
      'status': RoomStatus.lobby.name,
      'buildQuestion': FieldValue.delete(),
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

  Future<T> _withTimeout<T>(Future<T> future, String message) {
    return future.timeout(
      _firebaseTimeout,
      onTimeout: () => throw TimeoutException(message),
    );
  }
}
