import 'game_definition.dart';
import '../localization/app_language.dart';

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

  static List<WordDeck> allFor(
    GameDeckCatalog catalog, {
    String languageCode = GameLanguage.defaultCode,
  }) {
    final decks = switch (catalog) {
      GameDeckCatalog.party => partyDecks,
      GameDeckCatalog.password => passwordDecks,
    };

    if (languageCode == GameLanguage.defaultCode) {
      return decks;
    }

    final localized = _localizedDecks[languageCode] ?? const {};
    return [
      for (final deck in decks)
        localized[deck.id] == null
            ? deck
            : WordDeck(
                id: deck.id,
                name: localized[deck.id]!.name,
                description: localized[deck.id]!.description,
                words: localized[deck.id]!.words,
              ),
    ];
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
    String languageCode = GameLanguage.defaultCode,
  }) {
    final decks = allFor(catalog, languageCode: languageCode);
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

  static final _localizedDecks = <String, Map<String, WordDeck>>{
    'he': {
      'party_mix': const WordDeck(
        id: 'party_mix',
        name: 'מיקס מסיבה',
        description: 'מילים יומיומיות קלילות לסיבובים מהירים ורועשים.',
        words: [
          'פיצה',
          'יום הולדת',
          'שדה תעופה',
          'מטרייה',
          'רובוט',
          'פופקורן',
          'תיק גב',
          'מראה',
          'אוצר',
          'זיקוקים',
          'איש שלג',
          'מעלית',
          'כרית',
          'גיטרה',
          'כריך',
        ],
      ),
      'wild_cards': const WordDeck(
        id: 'wild_cards',
        name: 'קלפים משוגעים',
        description: 'מילים מוזרות יותר כשהחדר רוצה קצת בלגן.',
        words: [
          'מכונת זמן',
          'דיו בלתי נראה',
          'גבינת ירח',
          'סוכן חשאי',
          'כדור דיסקו',
          'ביצת דרקון',
          'בית רדוף',
          'לייזר טאג',
          'כתר קטן',
          'מרק מסתורי',
          'מונית חלל',
          'שטיח מעופף',
          'שיבוט',
          'הר געש',
          'עוגיית מזל',
        ],
      ),
      'movies_games': const WordDeck(
        id: 'movies_games',
        name: 'סרטים ומשחקים',
        description: 'מילים מעולם התרבות בלי צורך בשם מדויק.',
        words: [
          'גיבור על',
          'שלט משחק',
          'חללית',
          'טירה',
          'קוסם',
          'בלש',
          'נבל',
          'שיא',
          'משימה',
          'שער',
          'טריילר',
          'קרב בוס',
          'שותף',
          'מפת אוצר',
          'ארקייד',
        ],
      ),
      'password_starters': const WordDeck(
        id: 'password_starters',
        name: 'סיסמאות להתחלה',
        description: 'מילים נקיות ונוחות לרמזים במשחק Password.',
        words: [
          'גשר',
          'נר',
          'טיל',
          'גינה',
          'שמיכה',
          'רופא',
          'חלון',
          'פאזל',
          'כסף',
          'מצפן',
          'רעם',
          'ספרייה',
          'מצלמה',
          'טירה',
          'נהר',
        ],
      ),
      'password_tricky': const WordDeck(
        id: 'password_tricky',
        name: 'סיסמאות קשות',
        description: 'שמות עצם ורעיונות מאתגרים יותר לרמזים חדים.',
        words: [
          'הד',
          'כבידה',
          'זיכרון',
          'צל',
          'אות',
          'קטיפה',
          'מסלול',
          'חום',
          'אגדה',
          'קציר',
          'עוגן',
          'לחישה',
          'תבנית',
          'מעגל',
          'מזל',
        ],
      ),
      'password_actions': const WordDeck(
        id: 'password_actions',
        name: 'סיסמאות פעולה',
        description: 'פעלים ותנועה לרמזים אנרגטיים.',
        words: [
          'לטפס',
          'לקפוא',
          'לשאול',
          'לברוח',
          'להימתח',
          'לשרוק',
          'לאזן',
          'ללכוד',
          'למסור',
          'להעמיד פנים',
          'להבריק',
          'לרדוף',
          'לצוף',
          'למדוד',
          'להגן',
        ],
      ),
    },
  };
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

  static List<WordCategory> allFor({
    String languageCode = GameLanguage.defaultCode,
  }) {
    if (languageCode == GameLanguage.defaultCode) {
      return all;
    }

    final localized = _localizedCategories[languageCode] ?? const {};
    return [
      for (final category in all)
        localized[category.id] == null
            ? category
            : WordCategory(
                id: category.id,
                name: localized[category.id]!.name,
                description: localized[category.id]!.description,
                words: localized[category.id]!.words,
              ),
    ];
  }

  static WordCategory byId(
    String? id, {
    String languageCode = GameLanguage.defaultCode,
  }) {
    return allFor(languageCode: languageCode).firstWhere(
      (category) => category.id == id,
      orElse: () => allFor(languageCode: languageCode).first,
    );
  }

  static final _localizedCategories = <String, Map<String, WordCategory>>{
    'he': {
      'food': const WordCategory(
        id: 'food',
        name: 'אוכל',
        description: 'חטיפים, ארוחות וקלאסיקות לשיחה סביב השולחן.',
        words: [
          'פיצה',
          'סושי',
          'פנקייק',
          'טאקו',
          'גלידה',
          'פלאפל',
          'שוקולד',
          'ספגטי',
          'פופקורן',
          'דגני בוקר',
        ],
      ),
      'movies': const WordCategory(
        id: 'movies',
        name: 'סרטים',
        description: 'רעיונות קולנועיים בלי צורך בשמות מדויקים.',
        words: [
          'גיבור על',
          'בלש',
          'נבל',
          'חללית',
          'טריילר',
          'פופקורן',
          'טירה',
          'קוסם',
          'מרגל',
          'פסקול',
        ],
      ),
      'places': const WordCategory(
        id: 'places',
        name: 'מקומות',
        description: 'מקומות שקל לדבר סביבם בלי להסגיר יותר מדי.',
        words: [
          'שדה תעופה',
          'חוף',
          'ספרייה',
          'מוזיאון',
          'מסעדה',
          'מלון',
          'אצטדיון',
          'קניון',
          'פארק',
          'בית ספר',
        ],
      ),
      'everyday': const WordCategory(
        id: 'everyday',
        name: 'יומיומי',
        description: 'חפצים וסיטואציות מוכרות מהחיים.',
        words: [
          'מטרייה',
          'תיק גב',
          'מעלית',
          'מראה',
          'כרית',
          'יום הולדת',
          'כביסה',
          'שלט',
          'אוזניות',
          'לוח שנה',
        ],
      ),
    },
  };
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

  static const _heByCategory = {
    'food': [
      'היית אוכל את זה עם קטשופ?',
      'זה עדיף חם או קר?',
      'זה יכול להיות ארוחת בוקר?',
      'היית מזמין את זה במסעדה?',
      'זה מלכלך כשאוכלים?',
      'אפשר לחלוק את זה עם חברים?',
      'היית מוצא את זה במקרר?',
      'זה משהו שמתחשק בלילה?',
    ],
    'movies': [
      'זה היה עובד טוב יותר עם המשך?',
      'ילד יכול ליהנות מזה?',
      'זה צריך פסקול גדול?',
      'היית רואה את זה בקולנוע?',
      'כנראה יש בזה נבל?',
      'זה יכול לעבוד כקומדיה?',
      'זה יכול לקרות בחלל?',
      'ההורים שלך היו מזהים את זה?',
    ],
    'places': [
      'היית נוסע לשם בחופשה?',
      'בדרך כלל רועש שם?',
      'צריך כרטיס כדי להיכנס?',
      'אפשר לבלות שם יום שלם?',
      'זה עדיף בפנים או בחוץ?',
      'היית מצלם שם תמונות?',
      'אפשר לקנות שם אוכל?',
      'היית הולך לשם לבד?',
    ],
    'everyday': [
      'משתמשים בזה כל שבוע?',
      'זה נכנס לתיק גב?',
      'זה מעצבן לאבד את זה?',
      'זה בדרך כלל יקר?',
      'אפשר למצוא את זה בחדר שינה?',
      'היית משאיל את זה לחבר?',
      'זה צריך חשמל?',
      'זה נשבר בקלות?',
    ],
  };

  static List<String> forCategory(
    String? categoryId, {
    String languageCode = GameLanguage.defaultCode,
  }) {
    final bucket = languageCode == 'he' ? _heByCategory : byCategory;
    return bucket[categoryId] ?? bucket[WordCategories.defaultCategoryId]!;
  }
}

class CodenamesWords {
  const CodenamesWords._();

  static const all = [
    'Apple',
    'Anchor',
    'Artist',
    'Balloon',
    'Bank',
    'Battery',
    'Beach',
    'Bridge',
    'Button',
    'Camera',
    'Castle',
    'Circle',
    'Cloud',
    'Compass',
    'Concert',
    'Crown',
    'Desert',
    'Diamond',
    'Doctor',
    'Dragon',
    'Engine',
    'Forest',
    'Garden',
    'Ghost',
    'Giant',
    'Glove',
    'Harbor',
    'Helmet',
    'Island',
    'Jacket',
    'Jungle',
    'Knight',
    'Ladder',
    'Lantern',
    'Library',
    'Lightning',
    'Mirror',
    'Mountain',
    'Needle',
    'Ocean',
    'Orbit',
    'Painter',
    'Piano',
    'Pilot',
    'Planet',
    'Puzzle',
    'River',
    'Rocket',
    'School',
    'Shadow',
    'Ship',
    'Signal',
    'Snow',
    'Spider',
    'Stadium',
    'Storm',
    'Suit',
    'Temple',
    'Tiger',
    'Tower',
    'Train',
    'Triangle',
    'Tunnel',
    'Umbrella',
    'Vacuum',
    'Violin',
    'Volcano',
    'Window',
    'Wizard',
    'Yard',
    'Zoo',
    'Coffee',
    'Chair',
    'Clock',
    'Crane',
    'Dress',
    'Echo',
    'Fan',
    'Fence',
    'Fire',
    'Fork',
    'Hammer',
    'Honey',
    'Key',
    'Lab',
    'Mask',
    'Moon',
    'Nurse',
    'Paper',
    'Queen',
    'Robot',
    'Root',
    'Scale',
    'Screen',
    'Shell',
    'Star',
    'Stream',
    'Tablet',
    'Torch',
    'Whale',
    'Wheel',
  ];

  static List<String> allFor({String languageCode = GameLanguage.defaultCode}) {
    if (languageCode == 'he') {
      return _heAll;
    }
    return all;
  }

  static const _heAll = [
    'תפוח',
    'עוגן',
    'אמן',
    'בלון',
    'בנק',
    'סוללה',
    'חוף',
    'גשר',
    'כפתור',
    'מצלמה',
    'טירה',
    'עיגול',
    'ענן',
    'מצפן',
    'הופעה',
    'כתר',
    'מדבר',
    'יהלום',
    'רופא',
    'דרקון',
    'מנוע',
    'יער',
    'גינה',
    'רוח',
    'ענק',
    'כפפה',
    'נמל',
    'קסדה',
    'אי',
    'מעיל',
    'ג׳ונגל',
    'אביר',
    'סולם',
    'עששית',
    'ספרייה',
    'ברק',
    'מראה',
    'הר',
    'מחט',
    'ים',
    'מסלול',
    'צייר',
    'פסנתר',
    'טייס',
    'כוכב לכת',
    'פאזל',
    'נהר',
    'טיל',
    'בית ספר',
    'צל',
    'ספינה',
    'אות',
    'שלג',
    'עכביש',
    'אצטדיון',
    'סערה',
    'חליפה',
    'מקדש',
    'נמר',
    'מגדל',
    'רכבת',
    'משולש',
    'מנהרה',
    'מטרייה',
    'שואב אבק',
    'כינור',
    'הר געש',
    'חלון',
    'קוסם',
    'חצר',
    'גן חיות',
    'קפה',
    'כיסא',
    'שעון',
    'מנוף',
    'שמלה',
    'הד',
    'מאוורר',
    'גדר',
    'אש',
    'מזלג',
    'פטיש',
    'דבש',
    'מפתח',
    'מעבדה',
    'מסכה',
    'ירח',
    'אחות',
    'נייר',
    'מלכה',
    'רובוט',
    'שורש',
    'מאזניים',
    'מסך',
    'צדפה',
    'כוכב',
    'נחל',
    'טאבלט',
    'לפיד',
    'לווייתן',
    'גלגל',
  ];
}
