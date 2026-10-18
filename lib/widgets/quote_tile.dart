import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import 'animations.dart';

/// List mein ek quote (category, search aur favorites screen).
class QuoteTile extends StatelessWidget {
  const QuoteTile({
    super.key,
    required this.quote,
    required this.style,
    required this.onTap,
    this.subtitle,
  });

  final Quote quote;
  final CardStyle style;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
          child: Row(
            children: [
              _Thumb(style: style),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kCoral),
                        ),
                      ),
                    Text(
                      quote.text,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kFontQuote,
                        fontSize: 17,
                        height: 1.4,
                        color: kInk,
                      ),
                    ),
                    if (quote.author != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '– ${quote.author}',
                        style: TextStyle(
                          fontFamily: kFontQuote,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: kInk.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              FavoriteButton(quoteId: quote.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.style});
  final CardStyle style;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 58,
        height: 58,
        child: style.hasPhoto
            ? Image(image: style.thumbProvider(180)!, fit: BoxFit.cover)
            : DecoratedBox(
                decoration: BoxDecoration(gradient: style.gradient),
                child: Center(child: Text(style.emoji, style: const TextStyle(fontSize: 24))),
              ),
      ),
    );
  }
}
