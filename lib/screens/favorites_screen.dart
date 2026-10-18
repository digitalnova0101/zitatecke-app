import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/quote_tile.dart';
import 'quote_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meine Favoriten')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final quotes = appState.favorites;
          if (quotes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💛', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    const Text(
                      'Noch keine Favoriten',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kInk),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tippe auf das Herz bei einem Spruch, um ihn hier zu speichern.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: kInk.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: quotes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => QuoteTile(
              quote: quotes[i],
              style: styleById(appState.repo.defaultStyleId(quotes[i], i)),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuoteDetailScreen(
                    quotes: quotes,
                    initialIndex: i,
                    title: 'Favoriten',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
