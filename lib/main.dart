import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final String? savedUser = prefs.getString('current_user');
  final bool isAnon = prefs.getBool('is_anonymous') ?? false;
  final String themeMode = prefs.getString('theme_mode') ?? 'light';

  runApp(MyApp(savedUser: savedUser, isAnon: isAnon, initialTheme: themeMode));
}

class MyApp extends StatefulWidget {
  final String? savedUser;
  final bool isAnon;
  final String initialTheme;

  const MyApp({
    super.key,
    this.savedUser,
    required this.isAnon,
    required this.initialTheme,
  });

  static MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late String _currentTheme;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;
  }

  void changeTheme(String newTheme) async {
    setState(() => _currentTheme = newTheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', newTheme);
  }

  ThemeData _getThemeData() {
    if (_currentTheme == 'dark') {
      return ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      );
    } else if (_currentTheme == 'warm') {
      return ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBF0D9),
        cardColor: const Color(0xFFF3E5AB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE8D3A7),
          foregroundColor: Color(0xFF4A3B32),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5A2B),
          surface: const Color(0xFFFBF0D9),
        ),
      );
    } else {
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: _getThemeData(),
      home: widget.savedUser != null
          ? HomeScreen(
              currentUserId: widget.savedUser!,
              isAnonymous: widget.isAnon,
            )
          : const LoginScreen(),
    );
  }
}
