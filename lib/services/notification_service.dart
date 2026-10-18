import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../config.dart';
import '../data/quote_repository.dart';

/// Roz subah aur raat ko ek quote ki notification.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Quote id agar app notification tap karke khuli.
  String? launchPayload;

  /// Notification tap hone par (app khuli ho tab) call hota hai.
  void Function(String quoteId)? onTap;

  static const int _morningBaseId = 1000;
  static const int _nightBaseId = 2000;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    _setLocalLocation();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) onTap?.call(payload);
      },
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch != null && launch.didNotificationLaunchApp) {
      launchPayload = launch.notificationResponse?.payload;
    }
  }

  /// Phone ka time zone dhoondo (Germany ho to Europe/Berlin).
  void _setLocalLocation() {
    final offset = DateTime.now().timeZoneOffset.inMinutes;
    const preferred = [
      'Europe/Berlin', 'Europe/Vienna', 'Europe/Zurich', 'Europe/London', 'Asia/Kolkata',
    ];
    for (final name in preferred) {
      final loc = tz.getLocation(name);
      if (tz.TZDateTime.now(loc).timeZoneOffset.inMinutes == offset) {
        tz.setLocalLocation(loc);
        return;
      }
    }
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (tz.TZDateTime.now(loc).timeZoneOffset.inMinutes == offset) {
        tz.setLocalLocation(loc);
        return;
      }
    }
  }

  /// Android 13+ par permission popup.
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  /// Purani notifications hata ke agle [kNotificationDays] din ki nayi lagao.
  /// Har din ka quote wahi hota hai jo app mein "Spruch des Tages" hai.
  Future<void> scheduleAll({
    required QuoteRepository repo,
    required bool morningOn,
    required TimeOfDay morningTime,
    required bool nightOn,
    required TimeOfDay nightTime,
  }) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      await _plugin.cancel(p.id);
    }

    if (morningOn) {
      await _scheduleSeries(
        repo: repo,
        baseId: _morningBaseId,
        categoryId: 'guten_morgen',
        time: morningTime,
        title: 'Guten Morgen ☀️',
        channelId: 'morgengruss',
        channelName: 'Morgengruß',
      );
    }
    if (nightOn) {
      await _scheduleSeries(
        repo: repo,
        baseId: _nightBaseId,
        categoryId: 'gute_nacht',
        time: nightTime,
        title: 'Gute Nacht 🌙',
        channelId: 'nachtgruss',
        channelName: 'Gute-Nacht-Gruß',
      );
    }
  }

  Future<void> _scheduleSeries({
    required QuoteRepository repo,
    required int baseId,
    required String categoryId,
    required TimeOfDay time,
    required String title,
    required String channelId,
    required String channelName,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    for (var i = 0; i <= kNotificationDays; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      final when = tz.TZDateTime(
          tz.local, day.year, day.month, day.day, time.hour, time.minute);
      if (!when.isAfter(now)) continue;

      final quote = repo.quoteOfTheDay(categoryId, day);
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Täglicher Spruch',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(quote.text),
        ),
      );
      await _plugin.zonedSchedule(
        baseId + i,
        title,
        quote.text,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: quote.id,
      );
    }
  }
}
