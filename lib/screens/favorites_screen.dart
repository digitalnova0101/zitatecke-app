import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/quote_grid.dart';
import 'reels_screen.dart';

/// Favoriten als Foto-Galerie.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(title: const Text('Meine Favoriten')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final quotes = appState.favorites;
          if (quotes.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(32, 32, 32, bottom + 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: kBrandGradient,
                        shape: BoxShape.circle,
                        boxShadow: Ui.shadow(),
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 54),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Noch keine Favoriten',
                      style: TextStyle(fontFamily: kFontQuote, fontSize: 24, fontWeight: FontWeight.w700, color: kInk),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tippe auf das Herz bei einem Spruch – so findest du ihn hier jederzeit wieder.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, height: 1.4, color: kInk.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Row(
                  children: [
                    Text('Deine Lieblingssprüche',
                        style: TextStyle(fontWeight: FontWeight.w800, color: kInk.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              Expanded(
                child: QuoteGrid(
                  quotes: quotes,
                  showNewBadge: false,
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 24),
                  onTap: (i) => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ReelsScreen(quotes: quotes, initialIndex: i, title: 'Favoriten'),
                  )),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
