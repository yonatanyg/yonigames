import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game_definition.dart';
import '../models/model.dart';
import '../models/player.dart';
import '../models/word_deck.dart';

class GameSessionFactory {
  GameSessionFactory({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  Map<String, dynamic> createSessionData({
    required GameRoom room,
    required int durationSeconds,
    required DateTime now,
  }) {
    final game = room.selectedGame;
    final words = room.words;
    if (game.wordSource != GameWordSource.none && words.isEmpty) {
      throw StateError('Add at least one word before starting.');
    }

    final focusPlayer = _selectFocusPlayer(room);
    final wordIndex = words.isEmpty ? 0 : _random.nextInt(words.length);

    final sessionData = {
      'type': game.id,
      'gameId': game.id,
      'focusPlayerId': focusPlayer.id,
      'deckId': room.deckId,
      'currentWord': words.isEmpty ? '' : words[wordIndex],
      'wordIndex': wordIndex,
      'score': 0,
      'passes': 0,
      'round': 1,
      'durationSeconds': durationSeconds,
      'startedAt': Timestamp.fromDate(now),
      'endsAt': game.usesTimer
          ? Timestamp.fromDate(now.add(Duration(seconds: durationSeconds)))
          : null,
    };

    if (game.id == GameIds.outOfTheLoop) {
      sessionData.addAll(_createOutOfTheLoopData(room, words[wordIndex]));
    }

    return sessionData;
  }

  int nextWordIndex({required int currentIndex, required int wordCount}) {
    if (wordCount <= 1) {
      return 0;
    }

    var nextIndex = _random.nextInt(wordCount);
    while (nextIndex == currentIndex) {
      nextIndex = _random.nextInt(wordCount);
    }
    return nextIndex;
  }

  Player _selectFocusPlayer(GameRoom room) {
    final game = room.selectedGame;
    final focusRoleId = game.focusRoleId;
    final eligiblePlayers = focusRoleId == null
        ? room.players
        : room.players.where((player) => player.roleId == focusRoleId).toList();
    final players = eligiblePlayers.isEmpty ? room.players : eligiblePlayers;
    final focusIndex = _random.nextInt(players.length);

    switch (game.roleStrategy) {
      case GameRoleStrategy.oneGuesser:
      case GameRoleStrategy.oneOutOfTheLoop:
        return players[focusIndex];
    }
  }

  Map<String, dynamic> _createOutOfTheLoopData(
    GameRoom room,
    String currentWord,
  ) {
    final questionOrder = room.players.map((player) => player.id).toList()
      ..shuffle(_random);
    final questionBucket = [
      ...OutOfTheLoopQuestions.forCategory(room.categoryId),
    ]..shuffle(_random);
    final questions = List.generate(
      questionOrder.length,
      (index) => questionBucket[index % questionBucket.length],
    );
    final guessOptions = _guessOptions(room.words, currentWord);

    return {
      'phase': OutOfTheLoopPhase.wordReveal.name,
      'questionIndex': 0,
      'questionOrder': questionOrder,
      'questions': questions,
      'votes': <String, String>{},
      'guessOptions': guessOptions,
    };
  }

  List<String> _guessOptions(List<String> categoryWords, String currentWord) {
    final options = <String>{currentWord};
    final distractors =
        categoryWords
            .where((word) => word.toLowerCase() != currentWord.toLowerCase())
            .toList()
          ..shuffle(_random);

    for (final word in distractors.take(5)) {
      options.add(word);
    }

    return options.toList()..shuffle(_random);
  }
}
