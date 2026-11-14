import 'package:flutter/material.dart';

class AppTheme {
static const Color workoutAccent = Color(0xFFFF5722); // Naranja fuego
static const Color dietAccent = Color(0xFF10B981);    // Verde esmeralda

static ThemeData buildTheme(String mode) {
if (mode == 'dark') {
final base = ColorScheme.fromSeed(
seedColor: const Color(0xFF6366F1),
brightness: Brightness.dark,
surface: const Color(0xFF12141D),
);
return _decorate(
ThemeData(
useMaterial3: true,
brightness: Brightness.dark,
colorScheme: base,
scaffoldBackgroundColor: const Color(0xFF0B0D13),
cardColor: const Color(0xFF171A26),
),
cardBg: const Color(0xFF171A26),
inputFill: const Color(0xFF1E2230),
appBarBg: const Color(0xFF12141D),
appBarFg: Colors.white,
);
} else if (mode == 'warm') {
final base = ColorScheme.fromSeed(
seedColor: const Color(0xFFB45309),
brightness: Brightness.light,
surface: const Color(0xFFFAF1DF),
);
return _decorate(
ThemeData(
useMaterial3: true,
brightness: Brightness.light,
colorScheme: base,
scaffoldBackgroundColor: const Color(0xFFF6EAD2),
cardColor: const Color(0xFFFFF8EC),
),
cardBg: const Color(0xFFFFF8EC),
inputFill: const Color(0xFFF1E0C1),
appBarBg: const Color(0xFFEDD6AE),
appBarFg: const Color(0xFF3E2C1C),
);
} else {
final base = ColorScheme.fromSeed(
seedColor: const Color(0xFF2563EB),
brightness: Brightness.light,
surface: const Color(0xFFF8FAFC),
);
return _decorate(
ThemeData(
useMaterial3: true,
brightness: Brightness.light,
colorScheme: base,
scaffoldBackgroundColor: const Color(0xFFF1F5F9),
cardColor: Colors.white,
),
cardBg: Colors.white,
inputFill: const Color(0xFFE2E8F0).withValues(alpha: 0.55),
appBarBg: Colors.white,
appBarFg: const Color(0xFF0F172A),
);
}
}

static ThemeData _decorate(
ThemeData theme, {
required Color cardBg,
required Color inputFill,
required Color appBarBg,
required Color appBarFg,
}) {
final cs = theme.colorScheme;
return theme.copyWith(
appBarTheme: AppBarTheme(
backgroundColor: appBarBg,
foregroundColor: appBarFg,
elevation: 0,
scrolledUnderElevation: 1,
centerTitle: false,
titleTextStyle: TextStyle(
color: appBarFg,
fontSize: 20,
fontWeight: FontWeight.w800,
letterSpacing: -0.3,
),
),
cardTheme: CardThemeData(
color: cardBg,
elevation: 0,
margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
side: BorderSide(
color: cs.outlineVariant.withValues(alpha: 0.45),
width: 1,
),
),
),
inputDecorationTheme: InputDecorationTheme(
filled: true,
fillColor: inputFill,
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide.none,
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide(
color: cs.outlineVariant.withValues(alpha: 0.35),
),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide(color: cs.primary, width: 1.8),
),
),
elevatedButtonTheme: ElevatedButtonThemeData(
style: ElevatedButton.styleFrom(
backgroundColor: cs.primary,
foregroundColor: cs.onPrimary,
elevation: 0,
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
textStyle: const TextStyle(
fontWeight: FontWeight.w700,
fontSize: 15,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
),
outlinedButtonTheme: OutlinedButtonThemeData(
style: OutlinedButton.styleFrom(
padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
side: BorderSide(color: cs.outlineVariant),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
),
navigationBarTheme: NavigationBarThemeData(
backgroundColor: appBarBg,
indicatorColor: cs.primaryContainer,
labelTextStyle: WidgetStateProperty.all(
const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
),
),
bottomNavigationBarTheme: BottomNavigationBarThemeData(
backgroundColor: appBarBg,
selectedItemColor: cs.primary,
unselectedItemColor: cs.onSurfaceVariant,
type: BottomNavigationBarType.fixed,
elevation: 8,
),
dialogTheme: DialogThemeData(
backgroundColor: cardBg,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
),
bottomSheetTheme: BottomSheetThemeData(
backgroundColor: cardBg,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
),
),
);
}
}
