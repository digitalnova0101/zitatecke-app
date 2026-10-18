import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'http_util.dart';

class City {
  const City({required this.name, required this.region, required this.lat, required this.lon, this.countryCode = ''});

  final String name;
  final String region; // "Nordrhein-Westfalen, Deutschland"
  final double lat;
  final double lon;
  final String countryCode;

  Map<String, dynamic> toJson() => {'name': name, 'region': region, 'lat': lat, 'lon': lon, 'cc': countryCode};

  factory City.fromJson(Map<String, dynamic> j) => City(
        name: j['name'] as String,
        region: (j['region'] as String?) ?? '',
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        countryCode: (j['cc'] as String?) ?? '',
      );
}

class WeatherNow {
  const WeatherNow({required this.type, required this.temp, required this.code});

  /// sonne, wolken, regen, schnee, nebel, wind, hitze, kaelte
  final String type;
  final double temp;
  final int code;

  String get emoji => const {
        'sonne': '☀️', 'wolken': '☁️', 'regen': '🌧️', 'schnee': '❄️',
        'nebel': '🌫️', 'wind': '🌬️', 'hitze': '🥵', 'kaelte': '🥶',
      }[type] ?? '🌤️';

  String get label => const {
        'sonne': 'Sonnig', 'wolken': 'Bewölkt', 'regen': 'Regen', 'schnee': 'Schnee',
        'nebel': 'Nebel', 'wind': 'Windig', 'hitze': 'Heiß', 'kaelte': 'Frostig',
      }[type] ?? '';

  String get tempText => '${temp.round()}°';
}

/// Mausam: Open-Meteo (free, koi key nahi). Shehar user khud chunta hai.
class WeatherService {
  WeatherService(this._prefs);

  final SharedPreferences _prefs;
  static const _kCity = 'weather_city';

  WeatherNow? _cached;
  DateTime? _cachedAt;
  String? _cachedFor;

  City? get city {
    final raw = _prefs.getString(_kCity);
    if (raw == null) return null;
    try {
      return City.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setCity(City? c) async {
    _cached = null;
    if (c == null) {
      await _prefs.remove(_kCity);
    } else {
      await _prefs.setString(_kCity, jsonEncode(c.toJson()));
    }
  }

  /// Shehar dhoondo (DE/AT/CH pehle).
  static Future<List<City>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search',
        {'name': q, 'count': '15', 'language': 'de', 'format': 'json'});
    final j = await Http.getJson(uri) as Map<String, dynamic>;
    final results = (j['results'] as List?) ?? const [];
    final cities = <City>[
      for (final r in results.cast<Map<String, dynamic>>())
        City(
          name: r['name'] as String,
          region: [r['admin1'], r['country']].whereType<String>().join(', '),
          lat: (r['latitude'] as num).toDouble(),
          lon: (r['longitude'] as num).toDouble(),
          countryCode: (r['country_code'] as String?) ?? '',
        ),
    ];
    const pref = {'DE': 0, 'AT': 1, 'CH': 2};
    cities.sort((a, b) => (pref[a.countryCode] ?? 9).compareTo(pref[b.countryCode] ?? 9));
    return cities;
  }

  /// Abhi ka mausam (30 min cache).
  Future<WeatherNow?> current({bool force = false}) async {
    final c = city;
    if (c == null) return null;
    final key = '${c.lat},${c.lon}';
    if (!force &&
        _cached != null &&
        _cachedFor == key &&
        DateTime.now().difference(_cachedAt!) < const Duration(minutes: 30)) {
      return _cached;
    }
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${c.lat}',
        'longitude': '${c.lon}',
        'current': 'temperature_2m,weather_code,wind_speed_10m',
        'timezone': 'auto',
      });
      final j = await Http.getJson(uri) as Map<String, dynamic>;
      final cur = j['current'] as Map<String, dynamic>;
      final temp = (cur['temperature_2m'] as num).toDouble();
      final code = (cur['weather_code'] as num).toInt();
      final wind = ((cur['wind_speed_10m'] as num?) ?? 0).toDouble();
      _cached = WeatherNow(type: classify(code, temp, wind), temp: temp, code: code);
      _cachedAt = DateTime.now();
      _cachedFor = key;
      return _cached;
    } catch (e) {
      debugPrint('weather failed: $e');
      return _cachedFor == key ? _cached : null;
    }
  }

  /// WMO weather code → hamara type.
  static String classify(int code, double temp, double wind) {
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) return 'schnee';
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82) || code >= 95) return 'regen';
    if (wind >= 45) return 'wind';
    if (code == 45 || code == 48) return 'nebel';
    if (temp >= 28) return 'hitze';
    if (temp <= 0) return 'kaelte';
    if (code <= 1) return 'sonne';
    return 'wolken';
  }
}
