import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quote.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/quote_card.dart';

/// Bada card, design badlo, swipe karke agla quote, aur share.
class QuoteDetailScreen extends StatefulWidget {
  const QuoteDetailScreen({
    super.key,
    required this.quotes,
    this.initialIndex = 0,
    this.title,
  });

  final List<Quote> quotes;
  final int initialIndex;
  final String? title;

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  late final PageController _pageController;
  late int _index;
  String? _styleOverride;
  bool _sharing = false;
  final Map<int, GlobalKey> _cardKeys = {};

  GlobalKey _keyFor(int i) => _cardKeys.putIfAbsent(i, () => GlobalKey());

  Quote get _current => widget.quotes[_index];

  CardStyle _styleFor(int i) => styleById(
      _styleOverride ?? appState.repo.defaultStyleId(widget.quotes[i], i));

  @override
  void initState() {
    super.initState();
    _index = math.max(0, math.min(widget.initialIndex, widget.quotes.length - 1));
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await ShareService.shareCardImage(_keyFor(_index), _current);
    } catch (e) {
      _toast('Teilen hat leider nicht geklappt.');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final repo = appState.repo;
    final title = widget.title ?? repo.category(_current.category).title;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.quotes.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final quote = widget.quotes[i];
                  return LayoutBuilder(
                    builder: (context, c) {
                      final side = math.max(
                          120.0, math.min(c.maxWidth - 32, c.maxHeight - 24));
                      return Center(
                        child: SizedBox(
                          width: side,
                          height: side,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: RepaintBoundary(
                              key: _keyFor(i),
                              child: QuoteCard(
                                quote: quote,
                                style: _styleFor(i),
                                heading: repo.headingFor(quote),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (widget.quotes.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 6),
                child: Text(
                  '${_index + 1} / ${widget.quotes.length}  ·  Wischen für mehr',
                  style: TextStyle(color: kInk.withValues(alpha: 0.6)),
                ),
              ),
            _StylePicker(
              selectedId: _styleFor(_index).id,
              onSelected: (id) => setState(() => _styleOverride = id),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _sharing ? null : _shareImage,
                      icon: _sharing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.share),
                      label: const Text('Bild teilen (WhatsApp & Co.)'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ListenableBuilder(
                          listenable: appState,
                          builder: (context, _) {
                            final fav = appState.isFavorite(_current.id);
                            return OutlinedButton.icon(
                              onPressed: () => appState.toggleFavorite(_current.id),
                              icon: Icon(
                                fav ? Icons.favorite : Icons.favorite_border,
                                color: fav ? Colors.redAccent : null,
                              ),
                              label: Text(fav ? 'Gespeichert' : 'Merken'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await ShareService.copyText(_current);
                            _toast('Text kopiert ✓');
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Kopieren'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () => ShareService.shareText(_current),
                          child: const Tooltip(
                            message: 'Nur Text teilen',
                            child: Icon(Icons.text_fields),
                          ),
                        ),
                      ),
                    ],
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

class _StylePicker extends StatelessWidget {
  const _StylePicker({required this.selectedId, required this.onSelected});

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: kCardStyles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final style = kCardStyles[i];
          final selected = style.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(style.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: style.gradient,
                border: Border.all(
                  color: selected ? kInk : Colors.white,
                  width: selected ? 3 : 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(style.emoji, style: const TextStyle(fontSize: 18)),
            ),
          );
        },
      ),
    );
  }
}
