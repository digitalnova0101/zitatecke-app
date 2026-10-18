import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guten_morgen_app/models/quote.dart';

void main() {
  test('shareText adds author', () {
    const q = Quote(id: 'a', category: 'c', text: 'Hallo', author: 'Goethe');
    expect(q.shareText, 'Hallo\n– Goethe');
  });

  test('quotes.json is valid', () {
    final data = jsonDecode(File('assets/quotes.json').readAsStringSync())
        as Map<String, dynamic>;
    final categories = (data['categories'] as List)
        .map((e) => QuoteCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    final quotes = (data['quotes'] as List)
        .map((e) => Quote.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(categories, isNotEmpty);
    for (final c in categories) {
      expect(quotes.where((q) => q.category == c.id), isNotEmpty, reason: c.id);
    }
    final ids = quotes.map((q) => q.id).toSet();
    expect(ids.length, quotes.length, reason: 'duplicate ids');
  });
}
