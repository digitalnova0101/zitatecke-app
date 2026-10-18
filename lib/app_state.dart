import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/quote_repository.dart';
import 'models/quote.dart';
import 'services/notification_service.dart';

/// Poori app ka state: favorites + notification settings.
late final AppState appState;

class AppState extends ChangeNotifier {
  AppState(this.repo, this._prefs)
      : _favorites = List<String>.of(_prefs.getStringList(_kFavorites) ?? const []);

  final QuoteRepository repo;
  final SharedPreferences _prefs;
  final List<String> _favorites;

  static const _kFavorites = 'favorites';
  static const _kMorningOn = 'morning_on';
  static const _kMorningTime = 'morning_time';
  static const _kNightOn = 'night_on';
  static const _kNightTime = 'night_time';
  static const _kAskedPermission = 'asked_notification_permission';

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

  /// App start par: pehli baar permission maango, phir notifications lagao.
  Future<void> setupNotificationsOnStart() async {
    try {
      if (!(_prefs.getBool(_kAskedPermission) ?? false)) {
        await _prefs.setBool(_kAskedPermission, true);
        await NotificationService.instance.requestPermission();
      }
      await rescheduleNotifications();
    } catch (e) {
      debugPrint('Notification setup failed: $e');
    }
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
