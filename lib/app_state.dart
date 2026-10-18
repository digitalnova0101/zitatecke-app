import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/quote_repository.dart';
import 'models/quote.dart';
import 'services/content_service.dart';
import 'services/notification_service.dart';
import 'services/weather_service.dart';
import 'theme/card_fonts.dart';

/// Poori app ka state: favorites + notification settings.
late final AppState appState;

class AppState extends ChangeNotifier {
  AppState(this.repo, this._prefs)
      : _favorites = List<String>.of(_prefs.getStringList(_kFavorites) ?? const []),
        weather = WeatherService(_prefs);

  final QuoteRepository repo;
  final SharedPreferences _prefs;
  final List<String> _favorites;
  final WeatherService weather;

  // ---------- Online content ----------

  bool _refreshing = false;
  bool get refreshing => _refreshing;

  /// Naye AI quotes + photos laao. [force] = settings ka "Jetzt aktualisieren".
  Future<bool> refreshContent({bool force = false}) async {
    if (_refreshing) return false;
    _refreshing = true;
    notifyListeners();
    var changed = false;
    try {
      changed = await ContentService.instance.refresh(repo, force: force);
    } finally {
      _refreshing = false;
      notifyListeners();
    }
    if (changed) await rescheduleNotifications();
    return changed;
  }

  // ---------- Erscheinungsbild (hell / dunkel) ----------

  /// 'auto' = Handy-Einstellung oder nachts; 'light'; 'dark'.
  String get themeSetting => _prefs.getString('theme_mode') ?? 'auto';

  Future<void> setThemeSetting(String v) async {
    await _prefs.setString('theme_mode', v);
    notifyListeners();
  }

  // ---------- Geteilt-Zähler ----------

  int get shareCount => _prefs.getInt('share_count') ?? 0;

  Future<int> countShare() async {
    final n = shareCount + 1;
    await _prefs.setInt('share_count', n);
    return n;
  }

  // ---------- Schrift (font) ----------

  /// User ka chuna hua font – home aur share images mein bhi.
  CardFont get cardFont => fontById(_prefs.getString('card_font'));

  Future<void> setCardFont(String id) async {
    await _prefs.setString('card_font', id);
    notifyListeners();
  }

  Future<void> setCity(City? c) async {
    await weather.setCity(c);
    notifyListeners();
  }

  static const _kFavorites = 'favorites';
  static const _kMorningOn = 'morning_on';
  static const _kMorningTime = 'morning_time';
  static const _kNightOn = 'night_on';
  static const _kNightTime = 'night_time';
  static const _kOnboardingDone = 'onboarding_done';

  // ---------- Favoriten ----------

  /// Naye favorites sabse upar.
  List<Quote> get favorites =>
      _favorites.reversed.map(repo.byId).whereType<Quote>().toList();

  bool isFavorite(String id) => _favorites.contains(id);

  Future<void> toggleFavorite(String id) async {
    if (!_favorites.remove(id)) _favorites.add(id);
    notifyListeners();
    await _prefs.setStringList(_kFavorites, _favorites);
  }

  // ---------- Benachrichtigungen ----------

  bool get morningOn => _prefs.getBool(_kMorningOn) ?? true;
  bool get nightOn => _prefs.getBool(_kNightOn) ?? true;
  TimeOfDay get morningTime =>
      _readTime(_kMorningTime, const TimeOfDay(hour: 7, minute: 30));
  TimeOfDay get nightTime =>
      _readTime(_kNightTime, const TimeOfDay(hour: 21, minute: 30));

  TimeOfDay _readTime(String key, TimeOfDay fallback) {
    final v = _prefs.getString(key);
    if (v == null) return fallback;
    final parts = v.split(':');
    if (parts.length != 2) return fallback;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return fallback;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _writeTime(String key, TimeOfDay t) =>
      _prefs.setString(key, '${t.hour}:${t.minute}');

  Future<void> setMorning({bool? on, TimeOfDay? time}) async {
    if (on != null) await _prefs.setBool(_kMorningOn, on);
    if (time != null) await _writeTime(_kMorningTime, time);
    if (on == true) await NotificationService.instance.requestPermission();
    notifyListeners();
    await rescheduleNotifications();
  }

  Future<void> setNight({bool? on, TimeOfDay? time}) async {
    if (on != null) await _prefs.setBool(_kNightOn, on);
    if (time != null) await _writeTime(_kNightTime, time);
    if (on == true) await NotificationService.instance.requestPermission();
    notifyListeners();
    await rescheduleNotifications();
  }

  // ---------- Welcome screens ----------

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;

  /// Welcome ke last page par "Ja, gerne!" / "Vielleicht später".
  Future<void> completeOnboarding({required bool notifications}) async {
    await _prefs.setBool(_kOnboardingDone, true);
    await _prefs.setBool(_kMorningOn, notifications);
    await _prefs.setBool(_kNightOn, notifications);
    if (notifications) {
      try {
        await NotificationService.instance.requestPermission();
      } catch (e) {
        debugPrint('Permission request failed: $e');
      }
    }
    notifyListeners();
    await rescheduleNotifications();
  }

  /// App start par notifications agle dinon ke liye dobara lagao.
  Future<void> setupNotificationsOnStart() async {
    if (!onboardingDone) return;
    await rescheduleNotifications();
  }

  Future<void> rescheduleNotifications() async {
    try {
      await NotificationService.instance.scheduleAll(
        repo: repo,
        morningOn: morningOn,
        morningTime: morningTime,
        nightOn: nightOn,
        nightTime: nightTime,
      );
    } catch (e) {
      debugPrint('Scheduling failed: $e');
    }
  }
}
