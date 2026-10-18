import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import '../data/quote_repository.dart';
import '../models/quote.dart';
import 'http_util.dart';
import 'photo_library.dart';

/// Roz ke AI quotes (zitatecke.moezzadigital.com/feed.json) laana, phone mein save karna.
class ContentService {
  ContentService._();
  static final ContentService instance = ContentService._();

  File? _cache;
  DateTime? lastFetch;
  String? lastError;
  bool _busy = false;

  /// App start: pehle se save feed turant load (offline bhi chalega).
  Future<void> init(QuoteRepository repo) async {
    final docs = await getApplicationDocumentsDirectory();
    await Directory('${docs.path}/content').create(recursive: true);
    _cache = File('${docs.path}/content/feed.json');
    await PhotoLibrary.instance.init();
    if (await _cache!.exists()) {
      try {
        _apply(repo, jsonDecode(await _cache!.readAsString()) as Map<String, dynamic>);
        lastFetch = await _cache!.lastModified();
      } catch (e) {
        debugPrint('cached feed broken: $e');
      }
    }
  }

  /// Online se naya feed. true = kuch naya aaya.
  Future<bool> refresh(QuoteRepository repo, {bool force = false}) async {
    if (_busy || _cache == null) return false;
    if (!force && lastFetch != null && DateTime.now().difference(lastFetch!) < kFeedRefreshEvery) {
      // Feed taaza hai – sirf missing photos.
      await _syncPhotos(repo);
      return false;
    }
    _busy = true;
    try {
      final text = await Http.getText(Uri.parse(kFeedUrl), timeout: const Duration(seconds: 20));
      final json = jsonDecode(text) as Map<String, dynamic>;
      if (json['version'] != 1) throw const FormatException('unknown feed version');
      _apply(repo, json);
      await _cache!.writeAsString(text, flush: true);
      lastFetch = DateTime.now();
      lastError = null;
      await _syncPhotos(repo);
      return true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('feed refresh failed: $e');
      return false;
    } finally {
      _busy = false;
    }
  }

  Future<void> _syncPhotos(QuoteRepository repo) async {
    final now = DateTime.now();
    final moods = <String>{
      for (final c in repo.categories) ...repo.aiForDay(c.id, now).map((q) => q.mood ?? ''),
      ...repo.specialQuotes(now).map((q) => q.mood ?? ''),
      ...kWeatherMoods.values,
    }..remove('');
    try {
      await PhotoLibrary.instance.sync(neededMoods: moods);
    } catch (e) {
      debugPrint('photo sync failed: $e');
    }
  }

  /// Tests ke liye public.
  @visibleForTesting
  void applyForTest(QuoteRepository repo, Map<String, dynamic> j) => _apply(repo, j);

  void _apply(QuoteRepository repo, Map<String, dynamic> j) {
    final quotes = <Quote>[];
    final specials = <String, SpecialDay>{};
    final days = (j['days'] as Map?) ?? const {};
    for (final entry in days.entries) {
      final day = entry.value as Map<String, dynamic>;
      final sp = day['special'] as Map<String, dynamic>?;
      if (sp != null) {
        specials[entry.key as String] =
            SpecialDay(name: sp['name'] as String, heading: (sp['heading'] as String?) ?? sp['name'] as String);
      }
      for (final q in (day['quotes'] as List? ?? const [])) {
        try {
          quotes.add(Quote.fromJson(q as Map<String, dynamic>));
        } catch (_) {}
      }
    }
    final weather = <String, List<Quote>>{};
    final w = (j['weather'] as Map?) ?? const {};
    for (final entry in w.entries) {
      final type = entry.key as String;
      weather[type] = [
        for (final q in (entry.value as List? ?? const []))
          Quote.fromJson(q as Map<String, dynamic>, category: 'wetter_$type'),
      ];
    }
    final photos = [
      for (final p in (j['photos'] as List? ?? const [])) RemotePhoto.fromJson(p as Map<String, dynamic>),
    ];
    PhotoLibrary.instance.setCatalog(photos);
    repo.setRemote(quotes: quotes, specials: specials, weather: weather);
  }
}
