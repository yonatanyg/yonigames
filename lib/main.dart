import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _themeOption = AppTheme.options.first;

  void _setTheme(AppThemeOption option) {
    setState(() => _themeOption = option);
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      option: _themeOption,
      onThemeChanged: _setTheme,
      child: MaterialApp(
        title: 'YoniGames',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme(_themeOption),
        home: const HomeScreen(),
      ),
    );
  }
}
