import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quote.dart';
import '../theme/app_theme.dart';
import '../widgets/quote_grid.dart';
import 'reels_screen.dart';

/// Kategorie: 2-Spalten Foto-Grid. Tippen → Vollbild (Reels).
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
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text('${category.emoji}  ${category.title}'),
        actions: [
          if (quotes.isNotEmpty)
            IconButton(
              tooltip: 'Vollbild',
              icon: const Icon(Icons.play_circle_outline_rounded, size: 28),
              onPressed: () => _openReels(quotes, 0, category.title),
            ),
        ],
      ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Row(
              children: [
                Text('${quotes.length} Sprüche',
                    style: TextStyle(fontWeight: FontWeight.w800, color: kInk.withValues(alpha: 0.55))),
                const Spacer(),
                Text('Gedrückt halten für mehr',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk.withValues(alpha: 0.45))),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: appState,
              builder: (context, _) => QuoteGrid(
                quotes: quotes,
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 24),
                onTap: (i) => _openReels(quotes, i, category.title),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openReels(List<Quote> quotes, int i, String title) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReelsScreen(quotes: quotes, initialIndex: i, title: title),
    ));
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
