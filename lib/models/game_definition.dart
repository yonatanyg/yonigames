class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.lobbyDescription,
    required this.assetPath,
    required this.minPlayers,
    required this.wordRoleLabel,
    required this.hiddenRoleLabel,
    required this.hiddenWordMessage,
    required this.actionLabel,
    required this.roleStrategy,
    required this.settings,
    this.usesScore = true,
    this.wordSource = GameWordSource.deck,
    this.deckCatalog = GameDeckCatalog.party,
    this.playerRoles = const [],
    this.focusRoleId,
  });

  final String id;
  final String name;
  final String shortDescription;
  final String lobbyDescription;
  final String assetPath;
  final int minPlayers;
  final String wordRoleLabel;
  final String hiddenRoleLabel;
  final String hiddenWordMessage;
  final String actionLabel;
  final GameRoleStrategy roleStrategy;
  final List<GameSettingDefinition> settings;
  final bool usesScore;
  final GameWordSource wordSource;
  final GameDeckCatalog deckCatalog;
  final List<GamePlayerRole> playerRoles;
  final String? focusRoleId;

  bool get usesTimer {
    return settings.any((setting) => setting.type == GameSettingType.timer);
  }

  String? get defaultRoleId {
    return playerRoles.isEmpty ? null : playerRoles.first.id;
  }

  String? roleIdToMeetDemand(Map<String, int> roleCounts) {
    if (playerRoles.isEmpty) {
      return null;
    }

    for (final role in playerRoles) {
      final count = roleCounts[role.id] ?? 0;
      if (role.hasOpenSpot(count) && count < role.minPlayers) {
        return role.id;
      }
    }

    final openRoles = playerRoles
        .where((role) => role.hasOpenSpot(roleCounts[role.id] ?? 0))
        .toList();
    if (openRoles.isEmpty) {
      return null;
    }

    openRoles.sort((a, b) {
      final aCount = roleCounts[a.id] ?? 0;
      final bCount = roleCounts[b.id] ?? 0;
      final byCount = aCount.compareTo(bCount);
      return byCount == 0 ? a.name.compareTo(b.name) : byCount;
    });
    return openRoles.first.id;
  }

  GamePlayerRole? roleById(String? roleId) {
    if (playerRoles.isEmpty) {
      return null;
    }

    return playerRoles.firstWhere(
      (role) => role.id == roleId,
      orElse: () => playerRoles.first,
    );
  }

  bool hasRole(String roleId) {
    return playerRoles.any((role) => role.id == roleId);
  }

  List<GamePlayerRole> unmetRoleRequirements(Map<String, int> roleCounts) {
    return playerRoles
        .where((role) => (roleCounts[role.id] ?? 0) < role.minPlayers)
        .toList();
  }
}

enum GameRoleStrategy { oneGuesser, oneOutOfTheLoop }

enum GameWordSource { deck, category, none }

enum GameDeckCatalog { party, password }

enum GameSettingType { deck, category, timer }

class GameSettingKeys {
  const GameSettingKeys._();

  static const deckId = 'deckId';
  static const categoryId = 'categoryId';
  static const durationSeconds = 'durationSeconds';
}

class GameSettingDefinition {
  const GameSettingDefinition({
    required this.key,
    required this.label,
    required this.type,
  });

  final String key;
  final String label;
  final GameSettingType type;
}

class GamePlayerRole {
  const GamePlayerRole({
    required this.id,
    required this.name,
    required this.description,
    required this.colorValue,
    this.minPlayers = 0,
    this.maxPlayers,
  });

  final String id;
  final String name;
  final String description;
  final int colorValue;
  final int minPlayers;
  final int? maxPlayers;

  bool hasOpenSpot(int currentPlayers) {
    return maxPlayers == null || currentPlayers < maxPlayers!;
  }
}

class GameRoleIds {
  const GameRoleIds._();

  static const hinter = 'hinter';
  static const guesser = 'guesser';
  static const player = 'player';
  static const teamOne = 'team_one';
  static const teamTwo = 'team_two';
}

class GameIds {
  const GameIds._();

  static const buildQuestion = 'build_a_question';
  static const outOfTheLoop = 'out_of_the_loop';
  static const password = 'password';
}

class GameCatalog {
  const GameCatalog._();

  // Add new games here first. If the new game can reuse one of the existing
  // role strategies and word-deck flow, no service or screen changes are needed.
  static const all = [
    GameDefinition(
      id: GameIds.buildQuestion,
      name: 'Build a Question',
      shortDescription: 'One guesser. Everyone else can only ask hints.',
      lobbyDescription:
          'The guesser tries to find the word while the room builds clues out loud.',
      assetPath: 'assets/game_tiles/build_question.png',
      minPlayers: 2,
      wordRoleLabel: 'Hint this word',
      hiddenRoleLabel: 'You are guessing',
      hiddenWordMessage: 'Listen to the hints and make the call.',
      actionLabel:
          'Give hints out loud. The guesser controls success and skip.',
      roleStrategy: GameRoleStrategy.oneGuesser,
      deckCatalog: GameDeckCatalog.party,
      focusRoleId: GameRoleIds.guesser,
      playerRoles: [
        GamePlayerRole(
          id: GameRoleIds.hinter,
          name: 'Hinter',
          description: 'Sees the word and gives clues.',
          colorValue: 0xFF8FCBB7,
          minPlayers: 1,
        ),
        GamePlayerRole(
          id: GameRoleIds.guesser,
          name: 'Guesser',
          description: 'Does not see the word and guesses out loud.',
          colorValue: 0xFFF4C95D,
          minPlayers: 1,
          maxPlayers: 1,
        ),
      ],
      settings: [
        GameSettingDefinition(
          key: GameSettingKeys.deckId,
          label: 'Deck',
          type: GameSettingType.deck,
        ),
        GameSettingDefinition(
          key: GameSettingKeys.durationSeconds,
          label: 'Round timer',
          type: GameSettingType.timer,
        ),
      ],
    ),
    GameDefinition(
      id: GameIds.outOfTheLoop,
      name: 'Out of the Loop',
      shortDescription: 'Everyone knows the secret except one player.',
      lobbyDescription:
          'Talk around the secret. The out-of-loop player tries to blend in.',
      assetPath: 'assets/game_tiles/out_of_the_loop.png',
      minPlayers: 3,
      wordRoleLabel: 'Secret word',
      hiddenRoleLabel: 'You are out of the loop',
      hiddenWordMessage: 'Blend in, listen closely, and guess the secret.',
      actionLabel: 'Discuss the secret without making it too obvious.',
      roleStrategy: GameRoleStrategy.oneOutOfTheLoop,
      playerRoles: [
        GamePlayerRole(
          id: GameRoleIds.player,
          name: 'Player',
          description: 'The game secretly chooses who is out of the loop.',
          colorValue: 0xFF9CBCE3,
          minPlayers: 3,
        ),
      ],
      settings: [
        GameSettingDefinition(
          key: GameSettingKeys.categoryId,
          label: 'Category',
          type: GameSettingType.category,
        ),
      ],
      usesScore: false,
      wordSource: GameWordSource.category,
    ),
    GameDefinition(
      id: GameIds.password,
      name: 'Password',
      shortDescription: 'Give one-word clues to unlock the password.',
      lobbyDescription:
          'Clue-givers see the password. The guesser tries to say it before time runs out.',
      assetPath: 'assets/game_tiles/password.png',
      minPlayers: 2,
      wordRoleLabel: 'Password',
      hiddenRoleLabel: 'You are guessing',
      hiddenWordMessage: 'Listen for one-word clues and guess the password.',
      actionLabel: 'Give short clues. The guesser controls success and pass.',
      roleStrategy: GameRoleStrategy.oneGuesser,
      deckCatalog: GameDeckCatalog.password,
      playerRoles: [
        GamePlayerRole(
          id: GameRoleIds.teamOne,
          name: 'Team 1',
          description: 'Plays for the first team.',
          colorValue: 0xFF8FCBB7,
          minPlayers: 1,
        ),
        GamePlayerRole(
          id: GameRoleIds.teamTwo,
          name: 'Team 2',
          description: 'Plays for the second team.',
          colorValue: 0xFFE98B74,
          minPlayers: 1,
        ),
      ],
      settings: [
        GameSettingDefinition(
          key: GameSettingKeys.deckId,
          label: 'Deck',
          type: GameSettingType.deck,
        ),
      ],
    ),
  ];

  static GameDefinition byId(String? id) {
    return all.firstWhere((game) => game.id == id, orElse: () => all.first);
  }
}
