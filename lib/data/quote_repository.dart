import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/quote.dart';
import '../services/photo_library.dart';

/// Mausam type → card heading / photo mood (offline quotes ke liye).
const Map<String, String> kWeatherHeadings = {
  'sonne': 'Sonnige Grüße', 'wolken': 'Grauer Tag? Kopf hoch!', 'regen': 'Regenwetter-Gruß',
  'schnee': 'Winterzauber', 'nebel': 'Nebliger Gruß', 'wind': 'Stürmische Grüße',
  'hitze': 'Heiße Grüße', 'kaelte': 'Warme Grüße',
};
const Map<String, String> kWeatherMoods = {
  'sonne': 'himmel', 'wolken': 'himmel', 'regen': 'regen', 'schnee': 'schnee',
  'nebel': 'nebel', 'wind': 'meer', 'hitze': 'sommer', 'kaelte': 'winter',
};

/// Special din (Muttertag, Advent …) – feed se.
class SpecialDay {
  const SpecialDay({required this.name, required this.heading});
  final String name;
  final String heading;
}

/// Quotes: app ke andar wale (assets/quotes.json) + roz ke AI quotes (online feed).
class QuoteRepository {
  QuoteRepository._(this.categories, this._local) {
    _rebuild();
  }

  final List<QuoteCategory> categories;
  final List<Quote> _local;
  List<Quote> _remote = const [];
  Map<String, SpecialDay> _specials = const {};
  Map<String, List<Quote>> _weatherRemote = const {};
  List<Quote> _weatherLocal = const [];

  late List<Quote> quotes;
  late Map<String, Quote> _byId;

  /// Feed ke "heute" (festival) quotes ki category – grid mein nahi dikhti.
  static const QuoteCategory specialCategory = QuoteCategory(
    id: 'heute',
    title: 'Besondere Tage',
    emoji: '🎉',
    subtitle: 'Feiertage und besondere Anlässe',
    heading: 'Für dich',
    styles: ['p_bokeh', 'p_wunderkerze', 'p_rose'],
  );

  static Future<QuoteRepository> load() async {
    final data = jsonDecode(await rootBundle.loadString('assets/quotes.json')) as Map<String, dynamic>;
    final categories = (data['categories'] as List)
        .map((e) => QuoteCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    final quotes = (data['quotes'] as List)
        .map((e) => Quote.fromJson(e as Map<String, dynamic>))
        .toList();
    final repo = QuoteRepository._(categories, quotes);
    try {
      final w = jsonDecode(await rootBundle.loadString('assets/weather_quotes.json')) as Map<String, dynamic>;
      repo._weatherLocal = [
        for (final entry in w.entries)
          for (final (i, t) in (entry.value as List).indexed)
            Quote(
              id: 'w_${entry.key}_$i',
              category: 'wetter_${entry.key}',
              text: t as String,
              heading: kWeatherHeadings[entry.key],
              mood: kWeatherMoods[entry.key],
            ),
      ];
      repo._rebuild();
    } catch (_) {}
    return repo;
  }

  void _rebuild() {
    // AI quotes: naye pehle; phir app ke andar wale.
    final remote = [..._remote]..sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));
    quotes = [...remote, ..._local];
    _byId = {
      for (final q in quotes) q.id: q,
      for (final list in _weatherRemote.values)
        for (final q in list) q.id: q,
      for (final q in _weatherLocal) q.id: q,
    };
  }

  /// Online feed aane par.
  void setRemote({
    required List<Quote> quotes,
    required Map<String, SpecialDay> specials,
    required Map<String, List<Quote>> weather,
  }) {
    _remote = quotes;
    _specials = specials;
    _weatherRemote = weather;
    _rebuild();
  }

  bool get hasRemote => _remote.isNotEmpty;

  Quote? byId(String id) => _byId[id];

  QuoteCategory category(String id) {
    if (id == specialCategory.id) return specialCategory;
    return categories.firstWhere((c) => c.id == id, orElse: () => categories.first);
  }

  List<Quote> byCategory(String categoryId, {String? tag}) => quotes
      .where((q) => q.category == categoryId && (tag == null || q.tag == tag))
      .toList();

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Is din ke AI quotes (category ke).
  List<Quote> aiForDay(String categoryId, DateTime d) {
    final key = dayKey(d);
    return _remote.where((q) => q.category == categoryId && q.date == key).toList();
  }

  bool isNewToday(Quote q) => q.date == dayKey(DateTime.now());

  int newTodayCount(String categoryId) => aiForDay(categoryId, DateTime.now()).length;

  /// Spruch des Tages: AI quote us din ka; warna app ke andar wale baari-baari.
  Quote quoteOfTheDay(String categoryId, [DateTime? date]) {
    final d = date ?? DateTime.now();
    final ai = aiForDay(categoryId, d);
    if (ai.isNotEmpty) return ai.first;
    var list = _local.where((q) => q.category == categoryId).toList();
    if (list.isEmpty) list = _local;
    final days = DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2024, 1, 1)).inDays;
    return list[days % list.length];
  }

  /// Home ka swipe: Spruch des Tages + aur [count-1] Sprüche (aaj ke AI pehle).
  List<Quote> quotesOfTheDay(String categoryId, {int count = 10, DateTime? date}) {
    final d = date ?? DateTime.now();
    final first = quoteOfTheDay(categoryId, d);
    final out = <Quote>[first];
    for (final q in aiForDay(categoryId, d)) {
      if (out.length >= count) break;
      if (!out.contains(q)) out.add(q);
    }
    final local = _local.where((q) => q.category == categoryId).toList();
    if (local.isNotEmpty) {
      final start = DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2024, 1, 1)).inDays;
      for (var i = 0; i < local.length && out.length < count; i++) {
        final q = local[(start + i) % local.length];
        if (!out.contains(q)) out.add(q);
      }
    }
    return out;
  }

  /// Aaj ke din (Montag … Sonntag) ka Spruch.
  Quote? weekdayQuote(DateTime d) {
    const tags = ['montag', 'dienstag', 'mittwoch', 'donnerstag', 'freitag', 'samstag', 'sonntag'];
    final tag = tags[d.weekday - 1];
    final ai = aiForDay('wochentage', d).where((q) => q.tag == tag).toList();
    if (ai.isNotEmpty) return ai.first;
    final local = _local.where((q) => q.category == 'wochentage' && q.tag == tag).toList();
    if (local.isEmpty) return null;
    final weeks = DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2024, 1, 1)).inDays ~/ 7;
    return local[weeks % local.length];
  }

  /// Aaj koi festival / khaas din?
  SpecialDay? specialFor(DateTime d) => _specials[dayKey(d)];

  List<Quote> specialQuotes(DateTime d) => aiForDay(specialCategory.id, d);

  /// Mausam ke hisaab se quote (type: sonne, regen, …).
  Quote? weatherQuote(String type, [DateTime? date]) {
    final d = date ?? DateTime.now();
    final remote = _weatherRemote[type] ?? const [];
    final today = remote.where((q) => q.date == dayKey(d)).toList();
    final pool = today.isNotEmpty
        ? today
        : [...remote, ..._weatherLocal.where((q) => q.category == 'wetter_$type')];
    if (pool.isEmpty) return null;
    final idx = DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2024, 1, 1)).inDays;
    return pool[idx % pool.length];
  }

  /// "Geburtstag Oma" → saare shabd hone chahiye. Umlaut ke bina bhi chalta hai
  /// (z.B. "gluckwunsch" ya "glueckwunsch" findet "Glückwunsch").
  List<Quote> search(String query) {
    final terms = _norm(query).split(' ').where((t) => t.isNotEmpty).toList();
    if (terms.isEmpty) return const [];
    final results = <Quote>[];
    for (final q in quotes) {
      final cat = category(q.category);
      String tagLabel = '';
      for (final t in cat.tags) {
        if (t.id == q.tag) tagLabel = '${t.label} ${t.heading}';
      }
      final hay = _norm('${q.text} ${q.author ?? ''} ${q.heading ?? ''} ${cat.title} ${cat.heading} $tagLabel');
      if (terms.every(hay.contains)) results.add(q);
    }
    return results;
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll('ß', 'ss')
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ae', 'a')
      .replaceAll('oe', 'o')
      .replaceAll('ue', 'u')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Card ka design: AI quote ho to uske mood wali photo; warna category ke designs.
  String defaultStyleId(Quote q, int index) {
    if (q.mood != null) {
      final id = PhotoLibrary.instance.styleIdForMood(q.mood!, seed: q.id);
      if (id != null) return id;
    }
    final styles = category(q.category).styles;
    return styles[index % styles.length];
  }

  /// Card ke upar wali line, jaise "Guten Morgen" ya "Schönen Montag".
  String headingFor(Quote q) {
    if (q.heading != null && q.heading!.isNotEmpty) return q.heading!;
    final cat = category(q.category);
    if (q.tag != null) {
      for (final t in cat.tags) {
        if (t.id == q.tag) return t.heading;
      }
    }
    return cat.heading;
  }
}
