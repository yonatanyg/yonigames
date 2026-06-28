import 'game_definition.dart';

class WordDeck {
  const WordDeck({
    required this.id,
    required this.name,
    required this.description,
    required this.words,
  });

  final String id;
  final String name;
  final String description;
  final List<String> words;
}

class WordDecks {
  const WordDecks._();

  static const defaultDeckId = 'party_mix';
  static const defaultPasswordDeckId = 'password_starters';
  static const manualDeckId = 'manual';

  static const partyDecks = [
    WordDeck(
      id: 'party_mix',
      name: 'Party Mix',
      description: 'Easy everyday words for loud, fast rounds.',
      words: [
        'Pizza',
        'Birthday',
        'Airport',
        'Umbrella',
        'Robot',
        'Popcorn',
        'Backpack',
        'Mirror',
        'Treasure',
        'Fireworks',
        'Snowman',
        'Elevator',
        'Pillow',
        'Guitar',
        'Sandwich',
      ],
    ),
    WordDeck(
      id: 'wild_cards',
      name: 'Wild Cards',
      description: 'Stranger prompts when the room wants chaos.',
      words: [
        'Time Machine',
        'Invisible Ink',
        'Moon Cheese',
        'Secret Agent',
        'Disco Ball',
        'Dragon Egg',
        'Haunted House',
        'Laser Tag',
        'Tiny Crown',
        'Mystery Soup',
        'Space Taxi',
        'Magic Carpet',
        'Clone',
        'Volcano',
        'Fortune Cookie',
      ],
    ),
    WordDeck(
      id: 'movies_games',
      name: 'Movies & Games',
      description: 'Pop-culture-ish words without needing exact titles.',
      words: [
        'Superhero',
        'Controller',
        'Spaceship',
        'Castle',
        'Wizard',
        'Detective',
        'Villain',
        'High Score',
        'Quest',
        'Portal',
        'Movie Trailer',
        'Boss Fight',
        'Sidekick',
        'Treasure Map',
        'Arcade',
      ],
    ),
  ];

  static const passwordDecks = [
    WordDeck(
      id: 'password_starters',
      name: 'Password Starters',
      description: 'Clean clue-friendly words for classic Password rounds.',
      words: [
        'Bridge',
        'Candle',
        'Rocket',
        'Garden',
        'Blanket',
        'Doctor',
        'Window',
        'Puzzle',
        'Silver',
        'Compass',
        'Thunder',
        'Library',
        'Camera',
        'Castle',
        'River',
      ],
    ),
    WordDeck(
      id: 'password_tricky',
      name: 'Tricky Passwords',
      description: 'Harder nouns and concepts for sharper clue-givers.',
      words: [
        'Echo',
        'Gravity',
        'Memory',
        'Shadow',
        'Signal',
        'Velvet',
        'Orbit',
        'Fever',
        'Legend',
        'Harvest',
        'Anchor',
        'Whisper',
        'Pattern',
        'Circuit',
        'Fortune',
      ],
    ),
    WordDeck(
      id: 'password_actions',
      name: 'Action Passwords',
      description: 'Verbs and movement words for energetic clues.',
      words: [
        'Climb',
        'Freeze',
        'Borrow',
        'Escape',
        'Stretch',
        'Whistle',
        'Balance',
        'Capture',
        'Deliver',
        'Pretend',
        'Polish',
        'Chase',
        'Float',
        'Measure',
        'Protect',
      ],
    ),
  ];

  static List<WordDeck> allFor(GameDeckCatalog catalog) {
    switch (catalog) {
      case GameDeckCatalog.party:
        return partyDecks;
      case GameDeckCatalog.password:
        return passwordDecks;
    }
  }

  static String defaultDeckIdFor(GameDeckCatalog catalog) {
    switch (catalog) {
      case GameDeckCatalog.party:
        return defaultDeckId;
      case GameDeckCatalog.password:
        return defaultPasswordDeckId;
    }
  }

  static WordDeck byId(
    String? id, {
    GameDeckCatalog catalog = GameDeckCatalog.party,
  }) {
    final decks = allFor(catalog);
    return decks.firstWhere((deck) => deck.id == id, orElse: () => decks.first);
  }

  static List<String> parseManualWords(String value) {
    final seen = <String>{};
    return value
        .split(RegExp(r'[\n,;]+'))
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .where((word) => seen.add(word.toLowerCase()))
        .toList();
  }
}

class WordCategory {
  const WordCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.words,
  });

  final String id;
  final String name;
  final String description;
  final List<String> words;
}

class WordCategories {
  const WordCategories._();

  static const defaultCategoryId = 'food';

  static const all = [
    WordCategory(
      id: 'food',
      name: 'Food',
      description: 'Snacks, meals, and table-talk classics.',
      words: [
        'Pizza',
        'Sushi',
        'Pancakes',
        'Taco',
        'Ice Cream',
        'Falafel',
        'Chocolate',
        'Spaghetti',
        'Popcorn',
        'Cereal',
      ],
    ),
    WordCategory(
      id: 'movies',
      name: 'Movies',
      description: 'Cinema ideas without needing exact titles.',
      words: [
        'Superhero',
        'Detective',
        'Villain',
        'Spaceship',
        'Movie Trailer',
        'Popcorn',
        'Castle',
        'Wizard',
        'Spy',
        'Soundtrack',
      ],
    ),
    WordCategory(
      id: 'places',
      name: 'Places',
      description: 'Locations everyone can talk around.',
      words: [
        'Airport',
        'Beach',
        'Library',
        'Museum',
        'Restaurant',
        'Hotel',
        'Stadium',
        'Mall',
        'Park',
        'School',
      ],
    ),
    WordCategory(
      id: 'everyday',
      name: 'Everyday',
      description: 'Common objects and situations.',
      words: [
        'Umbrella',
        'Backpack',
        'Elevator',
        'Mirror',
        'Pillow',
        'Birthday',
        'Laundry',
        'Remote Control',
        'Headphones',
        'Calendar',
      ],
    ),
  ];

  static WordCategory byId(String? id) {
    return all.firstWhere(
      (category) => category.id == id,
      orElse: () => all.first,
    );
  }
}

class OutOfTheLoopQuestions {
  const OutOfTheLoopQuestions._();

  static const byCategory = {
    'food': [
      'Would you eat it with ketchup?',
      'Is it better hot or cold?',
      'Could this be breakfast?',
      'Would you order this at a restaurant?',
      'Is it messy to eat?',
      'Could you share it with friends?',
      'Would you find it in a fridge?',
      'Is it something you crave late at night?',
    ],
    'movies': [
      'Would this be better with a sequel?',
      'Could a kid enjoy it?',
      'Does it need a big soundtrack?',
      'Would you watch it in a theater?',
      'Is there probably a villain involved?',
      'Would it work as a comedy?',
      'Could it happen in space?',
      'Would your parents recognize it?',
    ],
    'places': [
      'Would you go there on vacation?',
      'Is it usually noisy?',
      'Would you need a ticket to enter?',
      'Could you spend a whole day there?',
      'Is it better indoors or outdoors?',
      'Would you take photos there?',
      'Can you buy food there?',
      'Would you go there alone?',
    ],
    'everyday': [
      'Do you use it every week?',
      'Could it fit in a backpack?',
      'Would it be annoying to lose?',
      'Is it usually expensive?',
      'Could you find it in a bedroom?',
      'Would you lend it to a friend?',
      'Does it need electricity?',
      'Could it break easily?',
    ],
  };

  static List<String> forCategory(String? categoryId) {
    return byCategory[categoryId] ??
        byCategory[WordCategories.defaultCategoryId]!;
  }
}
