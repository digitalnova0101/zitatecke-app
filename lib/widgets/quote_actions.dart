import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/quote.dart';
import '../screens/quote_detail_screen.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import 'share_actions.dart';

/// Long-press menu: Teilen, Merken, Kopieren, Gestalten.
Future<void> showQuoteActions(
  BuildContext context,
  Quote quote, {
  CardStyle? style,
  List<Quote>? list,
  int index = 0,
}) async {
  HapticFeedback.mediumImpact();
  final repo = appState.repo;
  final st = style ?? styleById(repo.defaultStyleId(quote, index));
  final action = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    builder: (context) {
      final fav = appState.isFavorite(quote.id);
      Widget item(String id, IconData icon, String label, {Color? color}) => ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (color ?? kInk).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color ?? kInk),
            ),
            title: Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
            onTap: () => Navigator.of(context).pop(id),
          );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  quote.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: kFontQuote, fontSize: 16, height: 1.35, color: kInk.withValues(alpha: 0.75)),
                ),
              ),
              item('whatsapp', Icons.chat_rounded, 'Per WhatsApp senden', color: kWhatsApp),
              item('share', Icons.ios_share_rounded, 'Als Bild teilen'),
              item('fav', fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  fav ? 'Aus Favoriten entfernen' : 'Merken', color: kCoral),
              item('copy', Icons.copy_rounded, 'Text kopieren'),
              item('edit', Icons.palette_outlined, 'Bild & Schrift gestalten'),
            ],
          ),
        ),
      );
    },
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case 'whatsapp':
      await Sharer.shareQuote(context, quote: quote, style: st, whatsapp: true);
    case 'share':
      await Sharer.shareQuote(context, quote: quote, style: st, whatsapp: false);
    case 'fav':
      HapticFeedback.lightImpact();
      await appState.toggleFavorite(quote.id);
    case 'copy':
      await ShareService.copyText(quote);
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Text kopiert ✓')));
      }
    case 'edit':
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => QuoteDetailScreen(quotes: list ?? [quote], initialIndex: list == null ? 0 : index, startEditing: true),
      ));
  }
}
