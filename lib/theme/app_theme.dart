import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Farben: hell + dunkel. kInk / kCream / kCard passen sich an (Dark Mode).
// ---------------------------------------------------------------------------

bool _dark = false;

/// MaterialApp ruft das vor dem Bauen auf.
void setDarkPalette(bool dark) => _dark = dark;
bool get isDarkPalette => _dark;

/// Haupt-Textfarbe.
Color get kInk => _dark ? const Color(0xFFF3EBEF) : const Color(0xFF3B2A35);

/// Hintergrund.
Color get kCream => _dark ? const Color(0xFF141116) : const Color(0xFFFFF8F1);

/// Karten / Flächen.
Color get kCard => _dark ? const Color(0xFF221D25) : Colors.white;

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

/// Einheitliche Abstände & Ecken (Design-System).
class Ui {
  Ui._();
  static const double gap = 16;
  static const double rCard = 24;
  static const double rTile = 20;
  static const double rButton = 18;
  static const double rChip = 14;

  static List<BoxShadow> shadow([double strength = 1]) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: (_dark ? 0.45 : 0.10) * strength),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Bade Buttons und großer Text – für ältere Nutzer einfach.
ThemeData buildAppTheme({bool dark = false}) {
  setDarkPalette(dark);
  final scheme = ColorScheme.fromSeed(
    seedColor: kCoral,
    brightness: dark ? Brightness.dark : Brightness.light,
    surface: kCream,
  ).copyWith(primary: kCoral, onPrimary: Colors.white, onSurface: kInk);

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    fontFamily: kFontUi,
    scaffoldBackgroundColor: kCream,
    canvasColor: kCream,
    textTheme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light)
        .textTheme
        .apply(fontFamily: kFontUi, bodyColor: kInk, displayColor: kInk),
    iconTheme: IconThemeData(color: kInk),
    appBarTheme: AppBarTheme(
      backgroundColor: kCream,
      surfaceTintColor: Colors.transparent,
      foregroundColor: kInk,
      elevation: 0,
      systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Ui.rButton)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 54),
        foregroundColor: kInk,
        backgroundColor: kCard,
        side: BorderSide(color: kInk.withValues(alpha: 0.15)),
        textStyle: const TextStyle(fontFamily: kFontUi, fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Ui.rButton)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kCoral),
    ),
    chipTheme: ChipThemeData(
      labelStyle: TextStyle(fontFamily: kFontUi, fontWeight: FontWeight.w700, color: kInk),
      secondaryLabelStyle: TextStyle(fontFamily: kFontUi, fontWeight: FontWeight.w800, color: kInk),
      backgroundColor: kCard,
      selectedColor: kCoral.withValues(alpha: 0.22),
      checkmarkColor: kCoral,
      side: BorderSide(color: kInk.withValues(alpha: 0.15)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Ui.rChip)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kCard,
      surfaceTintColor: Colors.transparent,
      indicatorColor: kCoral.withValues(alpha: 0.14),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? kCoral : kInk.withValues(alpha: 0.7),
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontFamily: kFontUi,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected) ? kCoral : kInk.withValues(alpha: 0.7),
          )),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: kInk.withValues(alpha: 0.75),
      textColor: kInk,
    ),
    dialogTheme: DialogThemeData(backgroundColor: kCard),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: kCard,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? kCoral : null),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
    }),
  );
}

// ---------------------------------------------------------------------------
// Tageszeit (für den Kopfbereich und den Auto-Dunkelmodus).
// ---------------------------------------------------------------------------

enum DayPart { morning, day, evening, night }

DayPart dayPartOf(DateTime t) {
  final h = t.hour;
  if (h >= 4 && h < 11) return DayPart.morning;
  if (h >= 11 && h < 17) return DayPart.day;
  if (h >= 17 && h < 21) return DayPart.evening;
  return DayPart.night;
}

/// Nachts (21–6 Uhr) automatisch dunkel.
bool isNightHour(DateTime t) => t.hour >= 21 || t.hour < 6;

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
