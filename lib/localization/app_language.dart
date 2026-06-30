import 'package:flutter/material.dart';

class GameLanguage {
  const GameLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.textDirection,
  });

  final String code;
  final String name;
  final String nativeName;
  final TextDirection textDirection;

  static const defaultCode = 'en';
  static const english = GameLanguage(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    textDirection: TextDirection.ltr,
  );
  static const hebrew = GameLanguage(
    code: 'he',
    name: 'Hebrew',
    nativeName: 'עברית',
    textDirection: TextDirection.rtl,
  );
  static const all = [english, hebrew];

  static GameLanguage byCode(String? code) {
    return all.firstWhere(
      (language) => language.code == code,
      orElse: () => english,
    );
  }
}

class AppLanguageScope extends InheritedWidget {
  const AppLanguageScope({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required super.child,
  });

  final GameLanguage language;
  final ValueChanged<GameLanguage> onLanguageChanged;

  static AppLanguageScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'No AppLanguageScope found in context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppLanguageScope oldWidget) {
    return language != oldWidget.language;
  }
}

class HomeCopy {
  const HomeCopy({
    required this.themeTooltip,
    required this.languageTooltip,
    required this.tagline,
    required this.roomPlay,
    required this.fastRounds,
    required this.liveScores,
    required this.nameLabel,
    required this.createRoom,
    required this.joinWithCode,
    required this.localPlay,
  });

  final String themeTooltip;
  final String languageTooltip;
  final String tagline;
  final String roomPlay;
  final String fastRounds;
  final String liveScores;
  final String nameLabel;
  final String createRoom;
  final String joinWithCode;
  final String localPlay;

  static HomeCopy of(BuildContext context) {
    switch (AppLanguageScope.of(context).language.code) {
      case 'he':
        return const HomeCopy(
          themeTooltip: 'ערכת צבעים',
          languageTooltip: 'שפה',
          tagline: 'משחקי סלון להרבה טלפונים וצחוק משותף אחד.',
          roomPlay: 'חדר משחק',
          fastRounds: 'סיבובים מהירים',
          liveScores: 'ניקוד חי',
          nameLabel: 'השם שלך',
          createRoom: 'יצירת חדר',
          joinWithCode: 'כניסה עם קוד',
          localPlay: 'משחק מקומי',
        );
      case 'en':
      default:
        return const HomeCopy(
          themeTooltip: 'Theme',
          languageTooltip: 'Language',
          tagline: 'Couch-party games for many phones and one shared laugh.',
          roomPlay: 'Room play',
          fastRounds: 'Fast rounds',
          liveScores: 'Live scores',
          nameLabel: 'Your name',
          createRoom: 'Create room',
          joinWithCode: 'Join with code',
          localPlay: 'Local play',
        );
    }
  }
}

class AppCopy {
  const AppCopy._({required this.languageCode});

  final String languageCode;

  static AppCopy of(BuildContext context) {
    return AppCopy._(languageCode: AppLanguageScope.of(context).language.code);
  }

  bool get isHebrew => languageCode == 'he';

  String get themeTooltip => isHebrew ? 'ערכת צבעים' : 'Theme';
  String get languageTooltip => isHebrew ? 'שפה' : 'Language';
  String get yourName => isHebrew ? 'השם שלך' : 'Your name';
  String get language => isHebrew ? 'שפה' : 'Language';
  String get game => isHebrew ? 'משחק' : 'Game';
  String get selectedGame => isHebrew ? 'משחק נבחר' : 'Selected game';
  String get gameSettings => isHebrew ? 'הגדרות משחק' : 'Game settings';
  String get lobby => isHebrew ? 'לובי' : 'Lobby';
  String get loadingLobby => isHebrew ? 'טוען לובי...' : 'Loading lobby...';
  String get startGame => isHebrew ? 'התחל משחק' : 'Start game';
  String get waitingForHost =>
      isHebrew ? 'מחכים למארח שיתחיל...' : 'Waiting for the host to start...';
  String minPlayers(int count) =>
      isHebrew ? 'צריך לפחות $count שחקנים.' : 'Need at least $count players.';
  String get addWordsBeforeStarting =>
      isHebrew ? 'הוסף מילים לפני שמתחילים.' : 'Add words before starting.';
  String get shareThisCode => isHebrew ? 'שתף את הקוד' : 'Share this code';
  String get roles => isHebrew ? 'תפקידים' : 'Roles';
  String rolesCount(int count) => isHebrew ? 'תפקידים ($count)' : 'Roles ($count)';
  String get randomizeRoles => isHebrew ? 'הגרל תפקידים' : 'Randomize roles';
  String get manualDeck => isHebrew ? 'חפיסה ידנית' : 'Manual deck';
  String manualWordCount(int count) =>
      isHebrew ? '$count מילים שמורות.' : '$count saved words.';
  String get manualWords => isHebrew ? 'מילים ידניות' : 'Manual words';
  String get saveManualDeck => isHebrew ? 'שמור חפיסה ידנית' : 'Save manual deck';
  String get deck => isHebrew ? 'חפיסה' : 'Deck';
  String get category => isHebrew ? 'קטגוריה' : 'Category';
  String get timer => isHebrew ? 'טיימר' : 'Timer';
  String get off => isHebrew ? 'כבוי' : 'Off';
  String get addAtLeastOneWord =>
      isHebrew ? 'הוסף לפחות מילה אחת.' : 'Add at least one word.';
  String get addAtLeastThreePlayers =>
      isHebrew ? 'הוסף לפחות 3 שחקנים.' : 'Add at least 3 players.';

  String get chooseGame => isHebrew ? 'בחירת משחק' : 'Choose game';
  String get gameDashboard => isHebrew ? 'לוח משחקים' : 'Game dashboard';
  String get pickFirstGame => isHebrew ? 'בחר את המשחק הראשון' : 'Pick the first game';
  String get changeGameLater => isHebrew
      ? 'אפשר עדיין להחליף משחק אחר כך מהלובי.'
      : 'You can still change the game later from the lobby.';
  String get creatingRoom => isHebrew ? 'יוצר חדר...' : 'Creating room...';
  String get startRoom => isHebrew ? 'התחל חדר' : 'Start room';

  String get joinRoom => isHebrew ? 'הצטרפות לחדר' : 'Join room';
  String get roomCodeRequired => isHebrew ? 'צריך קוד חדר' : 'Room code required';
  String get hopIntoLobby => isHebrew ? 'היכנס ללובי' : 'Hop into the lobby';
  String get joinInstructions => isHebrew
      ? 'הזן את הקוד שעל מסך המארח ובחר את השם שהחברים יראו.'
      : 'Enter the code on the host screen and pick the name your friends will see.';
  String get roomCode => isHebrew ? 'קוד חדר' : 'Room code';
  String get joinLobby => isHebrew ? 'הצטרף ללובי' : 'Join lobby';
  String get enterRoomCode => isHebrew ? 'הזן קוד חדר.' : 'Enter a room code.';
  String get joiningRoom => isHebrew ? 'מצטרף לחדר...' : 'Joining room...';

  String get localSetup => isHebrew ? 'הגדרה מקומית' : 'Local setup';
  String get oneDevicePlay => isHebrew ? 'משחק במכשיר אחד' : 'One-device play';
  String get chooseLocalGame => isHebrew ? 'בחר משחק מקומי' : 'Choose local game';
  String get localSetupDescription => isHebrew
      ? 'משחקים ממכשיר המארח עם חשיפות בתורות, הגדרות מקומיות ובלי קוד חדר.'
      : 'Play from one host device with pass-and-play reveals, local settings, and no room code.';
  String startGameName(String name) => isHebrew ? 'התחל $name' : 'Start $name';
  String get passwordDeck => isHebrew ? 'חפיסת Password' : 'Password deck';
  String get players => isHebrew ? 'שחקנים' : 'Players';
  String get words => isHebrew ? 'מילים' : 'Words';
  String get roundTimer => isHebrew ? 'טיימר סיבוב' : 'Round timer';

  String get localGame => isHebrew ? 'משחק מקומי' : 'Local game';
  String get localPassword => isHebrew ? 'Password מקומי' : 'Local Password';
  String get localOutOfTheLoop =>
      isHebrew ? 'מחוץ לעניינים מקומי' : 'Local Out of the Loop';
  String get noWords => isHebrew ? 'אין מילים' : 'No words';
  String get noPasswords => isHebrew ? 'אין סיסמאות' : 'No passwords';
  String get playAgain => isHebrew ? 'שחק שוב' : 'Play again';
  String get editDeck => isHebrew ? 'ערוך חפיסה' : 'Edit deck';
  String get success => isHebrew ? 'הצלחה' : 'Success';
  String get pass => isHebrew ? 'עבור' : 'Pass';
  String get skip => isHebrew ? 'דלג' : 'Skip';
  String get resetScore => isHebrew ? 'אפס ניקוד' : 'Reset score';
  String get roundComplete => isHebrew ? 'הסיבוב הסתיים' : 'Round complete';
  String get localRound => isHebrew ? 'סיבוב מקומי' : 'Local round';
  String get oneDeviceRound =>
      isHebrew ? 'סיבוב במכשיר אחד' : 'One-device round';
  String get time => isHebrew ? 'זמן' : 'Time';
  String get score => isHebrew ? 'ניקוד' : 'Score';
  String get passes => isHebrew ? 'דילוגים' : 'Passes';
  String get finalScore => isHebrew ? 'ניקוד סופי' : 'Final score';
  String get currentWord => isHebrew ? 'המילה הנוכחית' : 'Current word';
  String get timeIsUp => isHebrew ? 'הזמן נגמר' : 'Time is up';
  String get password => isHebrew ? 'סיסמה' : 'Password';

  String get stopGameAndLobby =>
      isHebrew ? 'עצור משחק וחזור ללובי' : 'Stop game and go to lobby';
  String get playAnotherRound =>
      isHebrew ? 'שחק סיבוב נוסף' : 'Play another round';
  String get backToLobby => isHebrew ? 'חזרה ללובי' : 'Back to lobby';
  String get backToSetup => isHebrew ? 'חזרה להגדרות' : 'Back to setup';
  String get newBoard => isHebrew ? 'לוח חדש' : 'New board';
  String get endTurn => isHebrew ? 'סיים תור' : 'End turn';
  String get giveClue => isHebrew ? 'תן רמז' : 'Give clue';
  String get oneWordClue => isHebrew ? 'רמז במילה אחת' : 'One-word clue';
  String get number => isHebrew ? 'מספר' : 'Number';
  String get votes => isHebrew ? 'הצבעות' : 'Votes';
  String voteCount(int count) => isHebrew ? '$count הצבעות' : '$count votes';

  String get startQuestions => isHebrew ? 'התחל שאלות' : 'Start questions';
  String get nextQuestion => isHebrew ? 'השאלה הבאה' : 'Next question';
  String get startVote => isHebrew ? 'התחל הצבעה' : 'Start vote';
  String get revealOutPlayer =>
      isHebrew ? 'חשוף את השחקן שמחוץ לעניינים' : 'Reveal out-of-loop player';
  String get startFinalGuess => isHebrew ? 'התחל ניחוש סופי' : 'Start final guess';
  String get startDiscussion => isHebrew ? 'התחל דיון' : 'Start discussion';
  String get discussion => isHebrew ? 'דיון' : 'Discussion';
  String get discussionPrompt => isHebrew
      ? 'דברו, אתגרו תשובות מוזרות ונסו להבין מי מחוץ לעניינים.'
      : 'Talk it out, challenge weird answers, and decide who sounds out of the loop.';
  String passTo(String player) => isHebrew ? 'העבר ל-$player' : 'Pass to $player';
  String get showCard => isHebrew ? 'הצג קלף' : 'Show card';
  String get hideAndContinue => isHebrew ? 'הסתר והמשך' : 'Hide and continue';
  String get private => isHebrew ? 'פרטי' : 'Private';
  String get secretReveal => isHebrew ? 'חשיפת סוד' : 'Secret reveal';
  String get questionPhase => isHebrew ? 'שלב שאלות' : 'Question phase';
  String questionNumber(int index, int total) =>
      isHebrew ? 'שאלה $index מתוך $total' : 'Question $index of $total';
  String get vote => isHebrew ? 'הצבעה' : 'Vote';
  String get reveal => isHebrew ? 'חשיפה' : 'Reveal';
  String get finalGuess => isHebrew ? 'ניחוש סופי' : 'Final guess';
  String get result => isHebrew ? 'תוצאה' : 'Result';
  String playerVotes(String player) => isHebrew ? '$player מצביע' : '$player votes';
  String get votePrompt => isHebrew
      ? 'בחר שחקן אחד. השם שלך מוסתר מהקלפי.'
      : 'Choose one player. Your own name is hidden from the ballot.';
  String outPlayer(String player) =>
      isHebrew ? 'מחוץ לעניינים: $player' : 'Out of the loop: $player';
  String outPlayerGuesses(String player) =>
      isHebrew ? '$player מנחש את המילה' : '$player guesses the word';
  String get pickRealWord =>
      isHebrew ? 'בחר את המילה האמיתית מהרשימה.' : 'Pick the real word from the category list.';
  String get theyGotIt => isHebrew ? 'הוא הצליח' : 'They got it';
  String get theyMissedIt => isHebrew ? 'הוא פספס' : 'They missed it';
  String get correctWord => isHebrew ? 'המילה הנכונה' : 'Correct word';
  String guess(String value) => isHebrew ? 'ניחוש: $value' : 'Guess: $value';
  String get realWord => isHebrew ? 'המילה האמיתית' : 'Real word';
  String get secretWord => isHebrew ? 'המילה הסודית' : 'Secret word';
  String get youAreOut => isHebrew ? 'אתה מחוץ לעניינים' : 'You are out of the loop';
  String get blendIn => isHebrew ? 'נסה להשתלב' : 'Blend in';

  String gameName(String id) {
    if (!isHebrew) {
      return switch (id) {
        'build_a_question' => 'Build a Question',
        'out_of_the_loop' => 'Out of the Loop',
        'password' => 'Password',
        'codenames' => 'Codenames',
        _ => id,
      };
    }
    return switch (id) {
      'build_a_question' => 'בנה שאלה',
      'out_of_the_loop' => 'מחוץ לעניינים',
      'password' => 'Password',
      'codenames' => 'שמות קוד',
      _ => id,
    };
  }

  String gameShortDescription(String id) {
    if (!isHebrew) {
      return switch (id) {
        'build_a_question' => 'One guesser. Everyone else can only ask hints.',
        'out_of_the_loop' => 'Everyone knows the secret except one player.',
        'password' => 'Give one-word clues to unlock the password.',
        'codenames' => 'Two teams race through a secret word grid.',
        _ => '',
      };
    }
    return switch (id) {
      'build_a_question' => 'מנחש אחד. כל השאר נותנים רמזים בלבד.',
      'out_of_the_loop' => 'כולם יודעים את הסוד חוץ משחקן אחד.',
      'password' => 'נותנים רמזים במילה אחת כדי לפצח את הסיסמה.',
      'codenames' => 'שתי קבוצות מתחרות על רשת מילים סודית.',
      _ => '',
    };
  }

  String gameLobbyDescription(String id) {
    if (!isHebrew) {
      return switch (id) {
        'build_a_question' =>
          'The guesser tries to find the word while the room builds clues out loud.',
        'out_of_the_loop' =>
          'Talk around the secret. The out-of-loop player tries to blend in.',
        'password' =>
          'Clue-givers see the password. The guesser tries to say it before time runs out.',
        'codenames' => 'Hinters see the key. Guessers reveal cards from one-word clues.',
        _ => '',
      };
    }
    return switch (id) {
      'build_a_question' =>
        'המנחש מנסה למצוא את המילה בזמן שהחדר בונה רמזים בקול.',
      'out_of_the_loop' =>
        'מדברים סביב הסוד. השחקן שמחוץ לעניינים מנסה להשתלב.',
      'password' =>
        'נותני הרמזים רואים את הסיסמה. המנחש מנסה לומר אותה.',
      'codenames' => 'נותני הרמזים רואים את המפתח. המנחשים חושפים קלפים.',
      _ => '',
    };
  }

  String wordRoleLabel(String gameId) {
    if (!isHebrew) {
      return switch (gameId) {
        'password' => 'Password',
        'codenames' => 'Board key',
        'out_of_the_loop' => 'Secret word',
        _ => 'Hint this word',
      };
    }
    return switch (gameId) {
      'password' => 'סיסמה',
      'codenames' => 'מפתח הלוח',
      'out_of_the_loop' => 'המילה הסודית',
      _ => 'תן רמז למילה',
    };
  }

  String hiddenRoleLabel(String gameId) {
    if (!isHebrew) {
      return switch (gameId) {
        'out_of_the_loop' => 'You are out of the loop',
        'codenames' => 'Guess from clues',
        _ => 'You are guessing',
      };
    }
    return switch (gameId) {
      'out_of_the_loop' => 'אתה מחוץ לעניינים',
      'codenames' => 'נחש מהרמזים',
      _ => 'אתה מנחש',
    };
  }

  String hiddenWordMessage(String gameId) {
    if (!isHebrew) {
      return switch (gameId) {
        'out_of_the_loop' => 'Blend in, listen closely, and guess the secret.',
        'password' => 'Listen for one-word clues and guess the password.',
        'codenames' => 'Wait for your hinter to give a clue.',
        _ => 'Listen to the hints and make the call.',
      };
    }
    return switch (gameId) {
      'out_of_the_loop' => 'נסה להשתלב, הקשב טוב ונחש את הסוד.',
      'password' => 'הקשב לרמזים במילה אחת ונחש את הסיסמה.',
      'codenames' => 'חכה שנותן הרמזים שלך ייתן רמז.',
      _ => 'הקשב לרמזים וקבל החלטה.',
    };
  }

  String actionLabel(String gameId) {
    if (!isHebrew) {
      return switch (gameId) {
        'password' => 'Give short clues. The guesser controls success and pass.',
        'out_of_the_loop' => 'Discuss the secret without making it too obvious.',
        'codenames' => 'Give one-word clues and avoid the black card.',
        _ => 'Give hints out loud. The guesser controls success and skip.',
      };
    }
    return switch (gameId) {
      'password' => 'תנו רמזים קצרים. המנחש שולט בהצלחה ובמעבר.',
      'out_of_the_loop' => 'דברו על הסוד בלי להפוך אותו לברור מדי.',
      'codenames' => 'תנו רמזים במילה אחת והימנעו מהקלף השחור.',
      _ => 'תנו רמזים בקול. המנחש שולט בהצלחה ובדילוג.',
    };
  }

  String roleName(String id) {
    if (!isHebrew) {
      return switch (id) {
        'hinter' => 'Hinter',
        'guesser' => 'Guesser',
        'player' => 'Player',
        'team_one' => 'Team 1',
        'team_two' => 'Team 2',
        'red_hinter' => 'Red Hinter',
        'red_guesser' => 'Red Guesser',
        'blue_hinter' => 'Blue Hinter',
        'blue_guesser' => 'Blue Guesser',
        _ => id,
      };
    }
    return switch (id) {
      'hinter' => 'נותן רמזים',
      'guesser' => 'מנחש',
      'player' => 'שחקן',
      'team_one' => 'קבוצה 1',
      'team_two' => 'קבוצה 2',
      'red_hinter' => 'נותן רמזים אדום',
      'red_guesser' => 'מנחש אדום',
      'blue_hinter' => 'נותן רמזים כחול',
      'blue_guesser' => 'מנחש כחול',
      _ => id,
    };
  }

  String roleDescription(String id) {
    if (!isHebrew) {
      return switch (id) {
        'hinter' => 'Sees the word and gives clues.',
        'guesser' => 'Does not see the word and guesses out loud.',
        'player' => 'The game secretly chooses who is out of the loop.',
        'team_one' => 'Plays for the first team.',
        'team_two' => 'Plays for the second team.',
        'red_hinter' => 'Sees the board key and gives clues for red.',
        'red_guesser' => 'Reveals cards for the red team.',
        'blue_hinter' => 'Sees the board key and gives clues for blue.',
        'blue_guesser' => 'Reveals cards for the blue team.',
        _ => '',
      };
    }
    return switch (id) {
      'hinter' => 'רואה את המילה ונותן רמזים.',
      'guesser' => 'לא רואה את המילה ומנחש בקול.',
      'player' => 'המשחק בוחר בסוד מי מחוץ לעניינים.',
      'team_one' => 'משחק בקבוצה הראשונה.',
      'team_two' => 'משחק בקבוצה השנייה.',
      'red_hinter' => 'רואה את מפתח הלוח ונותן רמזים לאדום.',
      'red_guesser' => 'חושף קלפים לקבוצה האדומה.',
      'blue_hinter' => 'רואה את מפתח הלוח ונותן רמזים לכחול.',
      'blue_guesser' => 'חושף קלפים לקבוצה הכחולה.',
      _ => '',
    };
  }

  String settingLabel(String key) {
    if (!isHebrew) {
      return switch (key) {
        'deckId' => 'Deck',
        'categoryId' => 'Category',
        'durationSeconds' => 'Round timer',
        'codenamesHinterSeconds' => 'Hinter timer',
        'codenamesGuesserSeconds' => 'Guesser timer',
        _ => key,
      };
    }
    return switch (key) {
      'deckId' => 'חפיסה',
      'categoryId' => 'קטגוריה',
      'durationSeconds' => 'טיימר סיבוב',
      'codenamesHinterSeconds' => 'טיימר נותן רמזים',
      'codenamesGuesserSeconds' => 'טיימר מנחש',
      _ => key,
    };
  }
}
