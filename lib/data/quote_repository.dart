import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/quote.dart';

/// Saare quotes assets/quotes.json se load hote hain (offline).
class QuoteRepository {
  QuoteRepository._(this.categories, this.quotes)
      : _byId = {for (final q in quotes) q.id: q};

  final List<QuoteCategory> categories;
  final List<Quote> quotes;
  final Map<String, Quote> _byId;

  static Future<QuoteRepository> load() async {
    final raw = await rootBundle.loadString('assets/quotes.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final categories = (data['categories'] as List)
        .map((e) => QuoteCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    final quotes = (data['quotes'] as List)
        .map((e) => Quote.fromJson(e as Map<String, dynamic>))
        .toList();
    return QuoteRepository._(categories, quotes);
  }

  Quote? byId(String id) => _byId[id];

  QuoteCategory category(String id) =>
      categories.firstWhere((c) => c.id == id, orElse: () => categories.first);

  List<Quote> byCategory(String categoryId, {String? tag}) => quotes
      .where((q) => q.category == categoryId && (tag == null || q.tag == tag))
      .toList();

  /// Har din ek naya quote – sab users ko same din same quote.
  Quote quoteOfTheDay(String categoryId, [DateTime? date]) {
    final list = byCategory(categoryId);
    final d = date ?? DateTime.now();
    final days = DateTime.utc(d.year, d.month, d.day)
        .difference(DateTime.utc(2024, 1, 1))
        .inDays;
    return list[days % list.length];
  }

  /// Category ke designs baari-baari se, taaki har card alag dikhe.
  String defaultStyleId(Quote q, int index) {
    final styles = category(q.category).styles;
    return styles[index % styles.length];
  }

  /// Card ke upar wali line, jaise "Guten Morgen" ya "Schönen Montag".
  String headingFor(Quote q) {
    final cat = category(q.category);
    if (q.tag != null) {
      for (final t in cat.tags) {
        if (t.id == q.tag) return t.heading;
      }
    }
    return cat.heading;
  }
}
