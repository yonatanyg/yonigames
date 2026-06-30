import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'localization/app_language.dart';
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
  var _language = GameLanguage.english;

  void _setTheme(AppThemeOption option) {
    setState(() => _themeOption = option);
  }

  void _setLanguage(GameLanguage language) {
    setState(() => _language = language);
  }

  @override
  Widget build(BuildContext context) {
    return AppLanguageScope(
      language: _language,
      onLanguageChanged: _setLanguage,
      child: AppThemeScope(
        option: _themeOption,
        onThemeChanged: _setTheme,
        child: MaterialApp(
          title: 'YoniGames',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme(_themeOption),
          locale: Locale(_language.code),
          supportedLocales: const [Locale('en'), Locale('he')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: _language.textDirection,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
