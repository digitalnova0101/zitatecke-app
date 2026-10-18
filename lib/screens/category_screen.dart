import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/quote_tile.dart';
import 'quote_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.categoryId, this.initialTag});

  final String categoryId;
  final String? initialTag;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String? _tag;

  @override
  void initState() {
    super.initState();
    _tag = widget.initialTag;
    // Wochentage: aaj ka din pehle se select.
    if (_tag == null && widget.categoryId == 'wochentage') {
      _tag = weekdayTag(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = appState.repo;
    final category = repo.category(widget.categoryId);
    final quotes = repo.byCategory(category.id, tag: _tag);

    return Scaffold(
      appBar: AppBar(title: Text('${category.emoji}  ${category.title}')),
      body: Column(
        children: [
          if (category.tags.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  _chip('Alle', _tag == null, () => setState(() => _tag = null)),
                  for (final t in category.tags)
                    _chip(t.label, _tag == t.id, () => setState(() => _tag = t.id)),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: quotes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => QuoteTile(
                quote: quotes[i],
                subtitle: repo.isNewToday(quotes[i]) ? '✨ NEU HEUTE' : null,
                style: styleById(repo.defaultStyleId(quotes[i], i)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuoteDetailScreen(
                      quotes: quotes,
                      initialIndex: i,
                      title: category.title,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label, style: const TextStyle(fontSize: 15)),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}
