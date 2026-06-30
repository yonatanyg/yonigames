import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const ink = Color(0xFF14213D);
  static const deepTeal = Color(0xFF0E6B63);
  static const mint = Color(0xFF56C7A6);
  static const coral = Color(0xFFFF6B5A);
  static const gold = Color(0xFFFFC857);
  static const sky = Color(0xFF7CC9E8);
  static const cream = Color(0xFFFFF8EA);
  static const paper = Color(0xFFFFFCF4);
}

enum AppThemeId { sunrise, midnight, obsidian, evergreen }

class AppThemeOption {
  const AppThemeOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.palette,
  });

  final AppThemeId id;
  final String name;
  final String description;
  final IconData icon;
  final AppPalette palette;
}

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.ink,
    required this.deepTeal,
    required this.mint,
    required this.coral,
    required this.gold,
    required this.sky,
    required this.cream,
    required this.paper,
    required this.backdropColors,
  });

  final Brightness brightness;
  final Color ink;
  final Color deepTeal;
  final Color mint;
  final Color coral;
  final Color gold;
  final Color sky;
  final Color cream;
  final Color paper;
  final List<Color> backdropColors;

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? AppTheme.sunrisePalette;
  }

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? ink,
    Color? deepTeal,
    Color? mint,
    Color? coral,
    Color? gold,
    Color? sky,
    Color? cream,
    Color? paper,
    List<Color>? backdropColors,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      ink: ink ?? this.ink,
      deepTeal: deepTeal ?? this.deepTeal,
      mint: mint ?? this.mint,
      coral: coral ?? this.coral,
      gold: gold ?? this.gold,
      sky: sky ?? this.sky,
      cream: cream ?? this.cream,
      paper: paper ?? this.paper,
      backdropColors: backdropColors ?? this.backdropColors,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }

    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      ink: Color.lerp(ink, other.ink, t)!,
      deepTeal: Color.lerp(deepTeal, other.deepTeal, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      backdropColors: [
        for (var index = 0; index < backdropColors.length; index++)
          Color.lerp(backdropColors[index], other.backdropColors[index], t)!,
      ],
    );
  }
}

class AppTheme {
  const AppTheme._();

  static const sunrisePalette = AppPalette(
    brightness: Brightness.light,
    ink: AppColors.ink,
    deepTeal: AppColors.deepTeal,
    mint: AppColors.mint,
    coral: AppColors.coral,
    gold: AppColors.gold,
    sky: AppColors.sky,
    cream: AppColors.cream,
    paper: AppColors.paper,
    backdropColors: [Color(0xFFFFF6DB), Color(0xFFE2F6EF), Color(0xFFFFE7DF)],
  );

  static const options = [
    AppThemeOption(
      id: AppThemeId.sunrise,
      name: 'Sunrise',
      description: 'Bright party table',
      icon: Icons.wb_sunny,
      palette: sunrisePalette,
    ),
    AppThemeOption(
      id: AppThemeId.midnight,
      name: 'Midnight',
      description: 'Dark blue game night',
      icon: Icons.dark_mode,
      palette: AppPalette(
        brightness: Brightness.dark,
        ink: Color(0xFFEAF2FF),
        deepTeal: Color(0xFF2DD4BF),
        mint: Color(0xFF5EEAD4),
        coral: Color(0xFFFF7A66),
        gold: Color(0xFFFACC58),
        sky: Color(0xFF7DD3FC),
        cream: Color(0xFF07111F),
        paper: Color(0xFF101C2F),
        backdropColors: [
          Color(0xFF06101D),
          Color(0xFF0B1E31),
          Color(0xFF13243E),
        ],
      ),
    ),
    AppThemeOption(
      id: AppThemeId.obsidian,
      name: 'Obsidian',
      description: 'Black room, bright buttons',
      icon: Icons.contrast,
      palette: AppPalette(
        brightness: Brightness.dark,
        ink: Color(0xFFF5F7FA),
        deepTeal: Color(0xFF22C55E),
        mint: Color(0xFF86EFAC),
        coral: Color(0xFFFF5C7A),
        gold: Color(0xFFFFD166),
        sky: Color(0xFF38BDF8),
        cream: Color(0xFF050608),
        paper: Color(0xFF111318),
        backdropColors: [
          Color(0xFF050608),
          Color(0xFF101216),
          Color(0xFF171A20),
        ],
      ),
    ),
    AppThemeOption(
      id: AppThemeId.evergreen,
      name: 'Evergreen',
      description: 'Dim green lounge',
      icon: Icons.forest,
      palette: AppPalette(
        brightness: Brightness.dark,
        ink: Color(0xFFEFFDF4),
        deepTeal: Color(0xFF34D399),
        mint: Color(0xFFA7F3D0),
        coral: Color(0xFFFF8A6B),
        gold: Color(0xFFF6C453),
        sky: Color(0xFF93C5FD),
        cream: Color(0xFF06140E),
        paper: Color(0xFF10231A),
        backdropColors: [
          Color(0xFF06140E),
          Color(0xFF0D2418),
          Color(0xFF142E20),
        ],
      ),
    ),
  ];

  static ThemeData get light => theme(options.first);

  static ThemeData theme(AppThemeOption option) {
    final palette = option.palette;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: palette.deepTeal,
          brightness: palette.brightness,
        ).copyWith(
          primary: palette.deepTeal,
          onPrimary: palette.brightness == Brightness.dark
              ? const Color(0xFF021412)
              : Colors.white,
          primaryContainer: palette.deepTeal.withValues(alpha: 0.22),
          onPrimaryContainer: palette.ink,
          secondary: palette.coral,
          onSecondary: Colors.white,
          secondaryContainer: palette.coral.withValues(alpha: 0.2),
          onSecondaryContainer: palette.ink,
          tertiary: palette.gold,
          onTertiary: const Color(0xFF171100),
          tertiaryContainer: palette.gold.withValues(alpha: 0.2),
          onTertiaryContainer: palette.ink,
          surface: palette.paper,
          onSurface: palette.ink,
        );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.cream,
      useMaterial3: true,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: palette.ink,
        titleTextStyle: TextStyle(
          color: palette.ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.paper.withValues(alpha: 0.92),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: palette.ink.withValues(alpha: 0.1)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.gold.withValues(alpha: 0.22),
        selectedColor: palette.gold,
        side: BorderSide(color: palette.gold.withValues(alpha: 0.56)),
        labelStyle: TextStyle(color: palette.ink, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.coral,
          foregroundColor: Colors.white,
          disabledBackgroundColor: palette.ink.withValues(alpha: 0.14),
          disabledForegroundColor: palette.ink.withValues(alpha: 0.38),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: BorderSide(color: palette.deepTeal, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.paper.withValues(
          alpha: palette.brightness == Brightness.dark ? 0.72 : 0.86,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.ink.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.ink.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.deepTeal, width: 2),
        ),
        labelStyle: TextStyle(
          color: palette.ink.withValues(alpha: 0.72),
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.paper,
        contentTextStyle: TextStyle(color: palette.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: TextTheme(
        displaySmall: TextStyle(
          fontSize: 42,
          height: 1,
          fontWeight: FontWeight.w900,
          color: palette.ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 25,
          height: 1.12,
          fontWeight: FontWeight.w900,
          color: palette.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 32,
          height: 1,
          fontWeight: FontWeight.w900,
          color: palette.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: palette.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: palette.ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.35, color: palette.ink),
        bodySmall: TextStyle(fontSize: 13, height: 1.3, color: palette.ink),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: palette.ink,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: palette.ink,
        ),
      ),
    );
  }
}

class AppThemeScope extends InheritedWidget {
  const AppThemeScope({
    super.key,
    required this.option,
    required this.onThemeChanged,
    required super.child,
  });

  final AppThemeOption option;
  final ValueChanged<AppThemeOption> onThemeChanged;

  static AppThemeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'No AppThemeScope found in context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) {
    return oldWidget.option != option;
  }
}

class GameBackdrop extends StatelessWidget {
  const GameBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.backdropColors,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _BackdropPainter(palette)),
          ),
          child,
        ],
      ),
    );
  }
}

class GameShell extends StatelessWidget {
  const GameShell({
    super.key,
    this.appBar,
    required this.child,
    this.maxWidth = 560,
  });

  final PreferredSizeWidget? appBar;
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: appBar == null,
      appBar: appBar,
      body: GameBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GamePanel extends StatelessWidget {
  const GamePanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.paper.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.ink.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: palette.brightness == Brightness.dark ? 0.24 : 0.1,
            ),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AccentPill extends StatelessWidget {
  const AccentPill({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.gold,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accent = color == AppColors.gold ? palette.gold : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: palette.ink),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter(this.palette);

  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final stripePaint = Paint()
      ..color = palette.ink.withValues(alpha: 0.045)
      ..strokeWidth = 1.2;

    for (var x = -size.height; x < size.width; x += 46) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripePaint,
      );
    }

    final tealPaint = Paint()
      ..color = palette.mint.withValues(
        alpha: palette.brightness == Brightness.dark ? 0.15 : 0.35,
      );
    final coralPaint = Paint()
      ..color = palette.coral.withValues(
        alpha: palette.brightness == Brightness.dark ? 0.12 : 0.18,
      );
    final goldPaint = Paint()
      ..color = palette.gold.withValues(
        alpha: palette.brightness == Brightness.dark ? 0.13 : 0.28,
      );
    final skyPaint = Paint()
      ..color = palette.sky.withValues(
        alpha: palette.brightness == Brightness.dark ? 0.12 : 0.24,
      );

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.68, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height * 0.32)
        ..lineTo(size.width * 0.76, size.height * 0.2)
        ..close(),
      tealPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.08)
        ..lineTo(size.width * 0.22, 0)
        ..lineTo(size.width * 0.38, size.height * 0.22)
        ..lineTo(0, size.height * 0.28)
        ..close(),
      goldPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width * 0.34, size.height)
        ..lineTo(size.width * 0.22, size.height * 0.78)
        ..lineTo(0, size.height * 0.84)
        ..close(),
      coralPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height * 0.64)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width * 0.7, size.height)
        ..lineTo(size.width * 0.82, size.height * 0.72)
        ..close(),
      skyPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}
