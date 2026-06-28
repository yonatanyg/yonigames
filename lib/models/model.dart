import 'package:cloud_firestore/cloud_firestore.dart';

import 'player.dart';

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

class BuildQuestionGame {
  const BuildQuestionGame({
    required this.guesserId,
    required this.score,
    required this.skips,
    required this.round,
    required this.durationSeconds,
    this.endsAt,
  });

  final String guesserId;
  final int score;
  final int skips;
  final int round;
  final int durationSeconds;
  final DateTime? endsAt;

  factory BuildQuestionGame.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const BuildQuestionGame(
        guesserId: '',
        score: 0,
        skips: 0,
        round: 1,
        durationSeconds: 60,
      );
    }

    final endsAtValue = data['endsAt'];
    return BuildQuestionGame(
      guesserId: data['guesserId'] as String? ?? '',
      score: data['score'] as int? ?? 0,
      skips: data['skips'] as int? ?? 0,
      round: data['round'] as int? ?? 1,
      durationSeconds: data['durationSeconds'] as int? ?? 60,
      endsAt: endsAtValue is Timestamp ? endsAtValue.toDate() : null,
    );
  }
}

class GameRoom {
  const GameRoom({
    required this.code,
    required this.hostId,
    required this.status,
    required this.selectedGame,
    required this.players,
    required this.buildQuestion,
  });

  final String code;
  final String hostId;
  final RoomStatus status;
  final String selectedGame;
  final List<Player> players;
  final BuildQuestionGame buildQuestion;

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
      selectedGame: data['selectedGame'] as String? ?? 'build_a_question',
      players: players,
      buildQuestion: BuildQuestionGame.fromMap(
        data['buildQuestion'] == null
            ? null
            : Map<String, dynamic>.from(data['buildQuestion'] as Map),
      ),
    );
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
