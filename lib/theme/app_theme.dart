import 'package:flutter/material.dart';

const Color kCream = Color(0xFFFFF8F1);
const Color kInk = Color(0xFF3B2A35);
const Color kAccent = Color(0xFFE07A3F);

/// Bade buttons aur bada text – older users ke liye aasaan.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kAccent,
    brightness: Brightness.light,
    surface: kCream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kCream,
    appBarTheme: const AppBarTheme(
      backgroundColor: kCream,
      surfaceTintColor: Colors.transparent,
      foregroundColor: kInk,
      titleTextStyle: TextStyle(
        fontFamily: 'serif',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: kInk,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 54),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

const List<String> kWeekdays = [
  'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag',
];

const List<String> kMonths = [
  'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
  'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
];

/// "Sonntag, 18. Oktober"
String germanDate(DateTime d) =>
    '${kWeekdays[d.weekday - 1]}, ${d.day}. ${kMonths[d.month - 1]}';

/// Tag-id for today, e.g. "montag".
String weekdayTag(DateTime d) => kWeekdays[d.weekday - 1].toLowerCase();

String formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} Uhr';
