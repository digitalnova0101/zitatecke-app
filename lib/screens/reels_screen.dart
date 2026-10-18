import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/quote.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../theme/card_fonts.dart';
import '../theme/card_styles.dart';
import '../widgets/animations.dart';
import '../widgets/quote_actions.dart';
import '../widgets/share_actions.dart';
import 'quote_detail_screen.dart';

/// Reels jaisa: upar swipe karo, har Spruch full screen.
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key, required this.quotes, this.initialIndex = 0, this.title});

  final List<Quote> quotes;
  final int initialIndex;
  final String? title;

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late final PageController _pc;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = math.max(0, math.min(widget.initialIndex, widget.quotes.length - 1));
    _pc = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  CardStyle _styleAt(int i) => styleById(appState.repo.defaultStyleId(widget.quotes[i], i));

  Future<void> _share(bool whatsapp) => Sharer.shareQuote(
        context,
        quote: widget.quotes[_index],
        style: _styleAt(_index),
        whatsapp: whatsapp,
      );

  @override
  Widget build(BuildContext context) {
    final q = widget.quotes[_index];
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pc,
              scrollDirection: Axis.vertical,
              itemCount: widget.quotes.length,
              onPageChanged: (i) {
                HapticFeedback.selectionClick();
                setState(() => _index = i);
              },
              itemBuilder: (context, i) => _ReelPage(
                quote: widget.quotes[i],
                style: _styleAt(i),
                font: appState.cardFont,
                onLongPress: () => showQuoteActions(context, widget.quotes[i], style: _styleAt(i), list: widget.quotes, index: i),
              ),
            ),
            // Top bar
            Positioned(
              top: top + 6,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  _Round(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                    ),
                  ),
                  Text(
                    '${_index + 1}/${widget.quotes.length}',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            // Right action column
            Positioned(
              right: 10,
              bottom: bottom + 96,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                    child: FavoriteButton(quoteId: q.id, size: 30, idleColor: Colors.white),
                  ),
                  const _Label('Merken'),
                  const SizedBox(height: 14),
                  _Round(icon: Icons.ios_share_rounded, onTap: () => _share(false)),
                  const _Label('Teilen'),
                  const SizedBox(height: 14),
                  _Round(
                    icon: Icons.copy_rounded,
                    onTap: () async {
                      await ShareService.copyText(q);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text kopiert ✓')));
                      }
                    },
                  ),
                  const _Label('Kopieren'),
                  const SizedBox(height: 14),
                  _Round(
                    icon: Icons.palette_outlined,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => QuoteDetailScreen(
                        quotes: widget.quotes,
                        initialIndex: _index,
                        title: widget.title,
                        startEditing: true,
                      ),
                    )),
                  ),
                  const _Label('Gestalten'),
                ],
              ),
            ),
            // Bottom: WhatsApp + hint
            Positioned(
              left: 16,
              right: 16,
              bottom: bottom + 16,
              child: Column(
                children: [
                  if (_index == 0 && widget.quotes.length > 1)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        '↑  Nach oben wischen für mehr',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: kWhatsApp, foregroundColor: Colors.white),
                      onPressed: () => _share(true),
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text('Per WhatsApp senden'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelPage extends StatelessWidget {
  const _ReelPage({required this.quote, required this.style, required this.font, required this.onLongPress});

  final Quote quote;
  final CardStyle style;
  final CardFont font;
  final VoidCallback onLongPress;

  double _size(String t) {
    final n = t.length;
    if (n <= 50) return 34;
    if (n <= 90) return 29;
    if (n <= 140) return 25;
    return 22;
  }

  @override
  Widget build(BuildContext context) {
    final repo = appState.repo;
    final color = style.hasPhoto ? Colors.white : style.textColor;
    final shadows = [Shadow(color: Colors.black.withValues(alpha: style.hasPhoto ? 0.6 : 0.0), blurRadius: 12)];
    return GestureDetector(
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (style.hasPhoto)
            Image(image: style.imageProvider!, fit: BoxFit.cover, gaplessPlayback: true)
          else
            DecoratedBox(decoration: BoxDecoration(gradient: style.gradient)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: style.hasPhoto ? 0.35 : 0.1),
                  Colors.black.withValues(alpha: style.hasPhoto ? 0.25 + style.dim : 0.0),
                  Colors.black.withValues(alpha: style.hasPhoto ? 0.55 : 0.15),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 70, 76, 120),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width - 104,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          repo.headingFor(quote),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: kFontScript,
                            fontWeight: FontWeight.w700,
                            fontSize: 40,
                            color: color,
                            shadows: shadows,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          quote.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: font.family,
                            fontWeight: font.weight,
                            fontSize: _size(quote.text) * font.scale,
                            height: font.height,
                            color: color,
                            shadows: shadows,
                          ),
                        ),
                        if (quote.author != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            '– ${quote.author}',
                            style: TextStyle(
                              fontFamily: kFontQuote,
                              fontStyle: FontStyle.italic,
                              fontSize: 17,
                              color: color.withValues(alpha: 0.9),
                              shadows: shadows,
                            ),
                          ),
                        ],
                      ],
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
}

class _Round extends StatelessWidget {
  const _Round({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)])),
      );
}
