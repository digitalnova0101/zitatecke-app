import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quote.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import 'animations.dart';
import 'quote_actions.dart';
import 'quote_card.dart';

/// 2 Spalten Foto-Karten (Kategorie, Favoriten).
class QuoteGrid extends StatelessWidget {
  const QuoteGrid({
    super.key,
    required this.quotes,
    required this.onTap,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
    this.showNewBadge = true,
  });

  final List<Quote> quotes;
  final void Function(int index) onTap;
  final EdgeInsets padding;
  final bool showNewBadge;

  @override
  Widget build(BuildContext context) {
    final repo = appState.repo;
    final font = appState.cardFont;
    return GridView.builder(
      padding: padding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: quotes.length,
      itemBuilder: (context, i) {
        final q = quotes[i];
        final st = styleById(repo.defaultStyleId(q, i));
        return PressScale(
          onTap: () => onTap(i),
          child: GestureDetector(
            onLongPress: () => showQuoteActions(context, q, style: st, list: quotes, index: i),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: Ui.shadow(0.6)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    QuoteCard(
                      quote: q,
                      style: st,
                      heading: repo.headingFor(q),
                      font: font,
                      showWatermark: false,
                      thumbnail: true,
                    ),
                    if (showNewBadge && repo.isNewToday(q))
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(gradient: kBrandGradient, borderRadius: BorderRadius.circular(8)),
                          child: const Text('NEU',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: FavoriteButton(quoteId: q.id, size: 24, idleColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
