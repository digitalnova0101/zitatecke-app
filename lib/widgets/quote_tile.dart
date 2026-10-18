import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quote.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';

/// List mein ek quote (category aur favorites screen).
class QuoteTile extends StatelessWidget {
  const QuoteTile({
    super.key,
    required this.quote,
    required this.style,
    required this.onTap,
  });

  final Quote quote;
  final CardStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 10,
                decoration: BoxDecoration(gradient: style.gradient),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        quote.text,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 17,
                          height: 1.35,
                          color: kInk,
                        ),
                      ),
                      if (quote.author != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '– ${quote.author}',
                          style: TextStyle(
                            fontSize: 14,
                            color: kInk.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: appState,
                builder: (context, _) {
                  final fav = appState.isFavorite(quote.id);
                  return IconButton(
                    tooltip: fav ? 'Aus Favoriten entfernen' : 'Zu Favoriten',
                    iconSize: 28,
                    onPressed: () => appState.toggleFavorite(quote.id),
                    icon: Icon(
                      fav ? Icons.favorite : Icons.favorite_border,
                      color: fav ? Colors.redAccent : kInk.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
