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

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.deepTeal,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.deepTeal,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFDDF6E8),
          onPrimaryContainer: AppColors.ink,
          secondary: AppColors.coral,
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFFFE0D8),
          onSecondaryContainer: AppColors.ink,
          tertiary: AppColors.gold,
          onTertiary: AppColors.ink,
          tertiaryContainer: const Color(0xFFFFEDB5),
          onTertiaryContainer: AppColors.ink,
          surface: AppColors.paper,
          onSurface: AppColors.ink,
        );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.paper.withValues(alpha: 0.92),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gold.withValues(alpha: 0.26),
        selectedColor: AppColors.gold,
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.6)),
        labelStyle: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.12),
          disabledForegroundColor: AppColors.ink.withValues(alpha: 0.36),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: AppColors.deepTeal, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.86),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.deepTeal, width: 2),
        ),
        labelStyle: TextStyle(
          color: AppColors.ink.withValues(alpha: 0.68),
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 42,
          height: 1,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 25,
          height: 1.12,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 32,
          height: 1,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: AppColors.ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.35, color: AppColors.ink),
        bodySmall: TextStyle(fontSize: 13, height: 1.3, color: AppColors.ink),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class GameBackdrop extends StatelessWidget {
  const GameBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF6DB), Color(0xFFE2F6EF), Color(0xFFFFE7DF)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _BackdropPainter()),
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
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.1),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.ink),
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
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stripePaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.045)
      ..strokeWidth = 1.2;

    for (var x = -size.height; x < size.width; x += 46) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripePaint,
      );
    }

    final tealPaint = Paint()..color = AppColors.mint.withValues(alpha: 0.35);
    final coralPaint = Paint()..color = AppColors.coral.withValues(alpha: 0.18);
    final goldPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.28);
    final skyPaint = Paint()..color = AppColors.sky.withValues(alpha: 0.24);

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
