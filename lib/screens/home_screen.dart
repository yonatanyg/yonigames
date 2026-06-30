import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../theme/app_theme.dart';
import 'game_dashboard_screen.dart';
import 'join_room_screen.dart';
import 'local_lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _openGameDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameDashboardScreen(
          playerName: _nameController.text,
          initialLanguageCode: AppLanguageScope.of(context).language.code,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = HomeCopy.of(context);
    return GameShell(
      maxWidth: 500,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(top: 0, right: 0, child: _ThemeMenuButton()),
          const Positioned(top: 0, left: 0, child: _LanguageMenuButton()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const IconBadge(),
              const SizedBox(height: 18),
              Text(
                'YoniGames',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                copy.tagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  AccentPill(icon: Icons.groups, label: copy.roomPlay),
                  AccentPill(
                    icon: Icons.bolt,
                    label: copy.fastRounds,
                    color: AppColors.coral,
                  ),
                  AccentPill(
                    icon: Icons.emoji_events,
                    label: copy.liveScores,
                    color: AppColors.sky,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              GamePanel(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: copy.nameLabel,
                        prefixIcon: const Icon(Icons.person),
                      ),
                      onSubmitted: (_) => _openGameDashboard(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _openGameDashboard,
                      icon: const Icon(Icons.dashboard_customize),
                      label: Text(copy.createRoom),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JoinRoomScreen(
                              initialName: _nameController.text,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: Text(copy.joinWithCode),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LocalLobbyScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone_android),
                      label: Text(copy.localPlay),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: palette.paper,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: palette.coral.withValues(alpha: 0.34),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Icon(Icons.casino, color: palette.gold, size: 42),
      ),
    );
  }
}

class _ThemeMenuButton extends StatelessWidget {
  const _ThemeMenuButton();

  @override
  Widget build(BuildContext context) {
    final themeScope = AppThemeScope.of(context);
    final palette = AppPalette.of(context);
    final copy = HomeCopy.of(context);

    return PopupMenuButton<AppThemeOption>(
      tooltip: copy.themeTooltip,
      icon: Icon(Icons.palette, color: palette.ink),
      color: palette.paper,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: themeScope.onThemeChanged,
      itemBuilder: (context) => [
        for (final option in AppTheme.options)
          PopupMenuItem(
            value: option,
            child: _ThemeMenuRow(
              option: option,
              selected: option == themeScope.option,
            ),
          ),
      ],
    );
  }
}

class _LanguageMenuButton extends StatelessWidget {
  const _LanguageMenuButton();

  @override
  Widget build(BuildContext context) {
    final languageScope = AppLanguageScope.of(context);
    final palette = AppPalette.of(context);
    final copy = HomeCopy.of(context);

    return PopupMenuButton<GameLanguage>(
      tooltip: copy.languageTooltip,
      icon: Icon(Icons.language, color: palette.ink),
      color: palette.paper,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: languageScope.onLanguageChanged,
      itemBuilder: (context) => [
        for (final language in GameLanguage.all)
          PopupMenuItem(
            value: language,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language.nativeName,
                    style: TextStyle(
                      color: palette.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (language.code == languageScope.language.code)
                  Icon(Icons.check_circle, color: palette.coral, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}

class _ThemeMenuRow extends StatelessWidget {
  const _ThemeMenuRow({required this.option, required this.selected});

  final AppThemeOption option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final optionPalette = option.palette;
    final menuPalette = AppPalette.of(context);

    return SizedBox(
      width: 210,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: optionPalette.cream,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: optionPalette.ink.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(option.icon, color: optionPalette.gold, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: menuPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _ThemeDot(color: optionPalette.deepTeal),
                    _ThemeDot(color: optionPalette.coral),
                    _ThemeDot(color: optionPalette.gold),
                  ],
                ),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle, color: menuPalette.coral, size: 18),
        ],
      ),
    );
  }
}

class _ThemeDot extends StatelessWidget {
  const _ThemeDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
