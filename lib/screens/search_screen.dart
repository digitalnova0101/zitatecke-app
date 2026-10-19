import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quote.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/quote_actions.dart';
import '../widgets/quote_tile.dart';
import 'quote_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Quote> _results = const [];

  static const _suggestions = [
    'Guten Morgen', 'Gute Nacht', 'Geburtstag', 'Freundin', 'Montag',
    'Wochenende', 'Weihnachten', 'Goethe', 'Kaffee', 'Mut',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) => setState(() => _results = appState.repo.search(q));

  void _useSuggestion(String s) {
    _controller.text = s;
    _controller.selection = TextSelection.collapsed(offset: s.length);
    _search(s);
  }

  @override
  Widget build(BuildContext context) {
    final repo = appState.repo;
    final query = _controller.text.trim();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _search,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kInk),
            decoration: InputDecoration(
              hintText: 'Spruch suchen …',
              filled: true,
              fillColor: kCard,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Löschen',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        _search('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
      body: query.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Beliebte Suchen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kInk),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _suggestions)
                      ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 15)),
                        onPressed: () => _useSuggestion(s),
                      ),
                  ],
                ),
              ],
            )
          : _results.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Nichts gefunden für „$query“.\nVersuche ein anderes Wort.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, color: kInk.withValues(alpha: 0.7)),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _results.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Text(
                        'Gefundene Sprüche',
                        style: TextStyle(fontWeight: FontWeight.w700, color: kInk.withValues(alpha: 0.6)),
                      );
                    }
                    final q = _results[i - 1];
                    return QuoteTile(
                      quote: q,
                      subtitle: repo.headingFor(q),
                      style: styleById(repo.defaultStyleId(q, i - 1)),
                      onLongPress: () => showQuoteActions(context, q, list: _results, index: i - 1),
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => QuoteDetailScreen(
                            quotes: _results,
                            initialIndex: i - 1,
                            title: 'Suche',
                          ),
                        ));
                      },
                    );
                  },
                ),
    );
  }
}
