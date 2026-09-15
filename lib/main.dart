import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String? savedUser = prefs.getString('current_user');

  runApp(MyApp(savedUser: savedUser));
}

class MyApp extends StatelessWidget {
  final String? savedUser;

  const MyApp({super.key, this.savedUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      home: savedUser != null
          ? HomeScreen(currentUserId: savedUser!)
          : const LoginScreen(),
    );
  }
}
