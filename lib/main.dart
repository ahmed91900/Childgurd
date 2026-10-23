import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/access/presentation/launcher_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: KidSafeApp()));
}

class KidSafeApp extends StatefulWidget {
  const KidSafeApp({super.key});
  @override
  State<KidSafeApp> createState() => _KidSafeAppState();
}

class _KidSafeAppState extends State<KidSafeApp> {
  Locale? _locale;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'KidSafe Launcher',
    debugShowCheckedModeBanner: false,
    locale: _locale,
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff174d73)),
      scaffoldBackgroundColor: const Color(0xfff5f7fb),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 56)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ),
    home: LauncherShell(onLocale: (locale) => setState(() => _locale = locale)),
  );
}
