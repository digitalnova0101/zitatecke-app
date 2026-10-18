import 'package:flutter/material.dart';

const Color kCream = Color(0xFFFFF8F1);
const Color kInk = Color(0xFF3B2A35);
const Color kCoral = Color(0xFFEB5A5F);
const Color kAmber = Color(0xFFFFB24C);
const Color kWhatsApp = Color(0xFF25D366);

/// Fonts (assets/fonts, OFL license).
const String kFontUi = 'Nunito';
const String kFontQuote = 'Lora';
const String kFontScript = 'DancingScript';

const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kAmber, kCoral],
);

/// Bade buttons aur bada text – older users ke liye aasaan.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kCoral,
    brightness: Brightness.light,
    surface: kCream,
  ).copyWith(primary: kCoral, onPrimary: Colors.white);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kFontUi,
    scaffoldBackgroundColor: kCream,
    appBarTheme: const AppBarTheme(
      backgroundColor: kCream,
      surfaceTintColor: Colors.transparent,
      foregroundColor: kInk,
      titleTextStyle: TextStyle(
        fontFamily: kFontQuote,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: kInk,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        textStyle: const TextStyle(fontFamily: kFontUi, fontSize: 17, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 54),
        foregroundColor: kInk,
        side: BorderSide(color: kInk.withValues(alpha: 0.18)),
        textStyle: const TextStyle(fontFamily: kFontUi, fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    chipTheme: ChipThemeData(
      labelStyle: const TextStyle(fontFamily: kFontUi, fontWeight: FontWeight.w700, color: kInk),
      secondaryLabelStyle: const TextStyle(fontFamily: kFontUi, fontWeight: FontWeight.w800, color: kInk),
      backgroundColor: Colors.white,
      selectedColor: kCoral.withValues(alpha: 0.18),
      checkmarkColor: kCoral,
      side: BorderSide(color: kInk.withValues(alpha: 0.15)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: kCoral.withValues(alpha: 0.14),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? kCoral : kInk.withValues(alpha: 0.7),
          )),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: kFontUi, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
    }),
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
