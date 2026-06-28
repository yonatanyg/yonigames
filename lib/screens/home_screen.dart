import 'package:flutter/material.dart';

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
        builder: (_) => GameDashboardScreen(playerName: _nameController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameShell(
      maxWidth: 500,
      child: Column(
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
            'Couch-party games for many phones and one shared laugh.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              AccentPill(icon: Icons.groups, label: 'Room play'),
              AccentPill(
                icon: Icons.bolt,
                label: 'Fast rounds',
                color: AppColors.coral,
              ),
              AccentPill(
                icon: Icons.emoji_events,
                label: 'Live scores',
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
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  onSubmitted: (_) => _openGameDashboard(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _openGameDashboard,
                  icon: const Icon(Icons.dashboard_customize),
                  label: const Text('Create room'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            JoinRoomScreen(initialName: _nameController.text),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Join with code'),
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
                  label: const Text('Local play'),
                ),
              ],
            ),
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
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.coral.withValues(alpha: 0.34),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: const Icon(Icons.casino, color: AppColors.gold, size: 42),
      ),
    );
  }
}
