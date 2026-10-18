import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guten_morgen_app/data/quote_repository.dart';
import 'package:guten_morgen_app/services/content_service.dart';
import 'package:guten_morgen_app/services/weather_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('online feed: Spruch des Tages, Feiertag, Wetter', () async {
    final repo = await QuoteRepository.load();
    final offlineMorning = repo.quoteOfTheDay('guten_morgen', DateTime(2026, 10, 19));
    expect(offlineMorning.isAi, isFalse);

    final feed = jsonDecode(File('test/sample_feed.json').readAsStringSync()) as Map<String, dynamic>;
    ContentService.instance.applyForTest(repo, feed);

    final ai = repo.quoteOfTheDay('guten_morgen', DateTime(2026, 10, 19));
    expect(ai.isAi, isTrue);
    expect(ai.date, '2026-10-19');
    expect(repo.headingFor(ai), isNotEmpty);
    expect(repo.byCategory('guten_morgen').first.isAi, isTrue); // AI quotes zuerst

    // Wochentage-Tag gesetzt
    expect(repo.byCategory('wochentage', tag: 'montag').any((q) => q.isAi), isTrue);

    // Nikolaus / 2. Advent
    final sp = repo.specialFor(DateTime(2026, 12, 6));
    expect(sp, isNotNull);
    expect(repo.specialQuotes(DateTime(2026, 12, 6)), isNotEmpty);
    expect(repo.category('heute').id, 'heute');

    // Wetter
    for (final t in ['sonne', 'wolken', 'regen', 'schnee', 'nebel', 'wind', 'hitze', 'kaelte']) {
      expect(repo.weatherQuote(t, DateTime(2026, 10, 19)), isNotNull, reason: t);
    }
    expect(repo.defaultStyleId(ai, 0), isNotEmpty);
    expect(repo.search('Kaffee'), isA<List>());
  });

  test('offline weather quotes exist', () async {
    final repo = await QuoteRepository.load();
    for (final t in ['sonne', 'regen', 'kaelte']) {
      final q = repo.weatherQuote(t);
      expect(q, isNotNull);
      expect(q!.heading, isNotEmpty);
    }
  });

  test('weather classification', () {
    expect(WeatherService.classify(61, 10, 5), 'regen');
    expect(WeatherService.classify(73, -2, 5), 'schnee');
    expect(WeatherService.classify(0, 31, 5), 'hitze');
    expect(WeatherService.classify(0, -4, 5), 'kaelte');
    expect(WeatherService.classify(1, 18, 5), 'sonne');
    expect(WeatherService.classify(3, 12, 5), 'wolken');
    expect(WeatherService.classify(45, 8, 5), 'nebel');
    expect(WeatherService.classify(3, 12, 60), 'wind');
  });
}
