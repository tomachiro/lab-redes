import 'widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/app_strings.dart';
import 'utils/app_theme.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

final prefs = await SharedPreferences.getInstance();
final String? savedUser = prefs.getString('current_user');
final bool isAnon = prefs.getBool('is_anonymous') ?? false;
String themeMode = prefs.getString('theme_mode') ?? 'light';

// Respaldo desde Firestore por si Flutter Web cambia de puerto al recargar
if (savedUser != null && !isAnon) {
try {
final doc = await FirebaseFirestore.instance
.collection('users')
.doc(savedUser)
.get();
final remoteTheme = doc.data()?['themeMode'] as String?;
if (remoteTheme != null && remoteTheme.isNotEmpty) {
themeMode = remoteTheme;
await prefs.setString('theme_mode', themeMode);
}
} catch (_) {}
}

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

Future<void> changeTheme(String newTheme) async {
setState(() => _currentTheme = newTheme);
final prefs = await SharedPreferences.getInstance();
await prefs.setString('theme_mode', newTheme);

final currentUser = prefs.getString('current_user');
final isAnon = prefs.getBool('is_anonymous') ?? false;
if (currentUser != null && !isAnon) {
await FirebaseFirestore.instance
.collection('users')
.doc(currentUser)
.set({'themeMode': newTheme}, SetOptions(merge: true));
}
}

@override
Widget build(BuildContext context) {
return MaterialApp(
title: AppStrings.appName,
debugShowCheckedModeBanner: false,
theme: AppTheme.buildTheme(_currentTheme),
builder: (context, child) {
return Container(
color: Theme.of(context).scaffoldBackgroundColor,
child: ResponsiveCenter(
child: child ?? const SizedBox.shrink(),
),
);
},
home: widget.savedUser != null
? HomeScreen(
currentUserId: widget.savedUser!,
isAnonymous: widget.isAnon,
)
: const LoginScreen(),
);
}
}
