import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/quote.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/animations.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Photos pehle se load – picker aur share fast rahe.
    for (final s in kCardStyles) {
      if (s.image != null) precacheImage(AssetImage(s.image!), context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _share({required bool whatsapp}) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final result = whatsapp
          ? await ShareService.shareToWhatsApp(_keyFor(_index), _current)
          : await ShareService.shareCardImage(_keyFor(_index), _current);
      if (whatsapp && result == ShareResultKind.sheet) {
        _toast('WhatsApp wurde nicht gefunden – wähle eine andere App.');
      } else if (result == ShareResultKind.failed) {
        _toast('Teilen hat leider nicht geklappt.');
      }
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
      appBar: AppBar(
        title: Text(title),
        actions: [FavoriteButton(quoteId: _current.id, size: 30)],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.quotes.length,
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _index = i);
                },
                itemBuilder: (context, i) {
                  final quote = widget.quotes[i];
                  final style = _styleFor(i);
                  return LayoutBuilder(
                    builder: (context, c) {
                      final side = math.max(
                          120.0, math.min(c.maxWidth - 32, c.maxHeight - 16));
                      return Center(
                        child: Container(
                          width: side,
                          height: side,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: kInk.withValues(alpha: 0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: RepaintBoundary(
                              key: _keyFor(i),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                child: QuoteCard(
                                  key: ValueKey('${quote.id}-${style.id}'),
                                  quote: quote,
                                  style: style,
                                  heading: repo.headingFor(quote),
                                ),
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
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(
                  '${_index + 1} / ${widget.quotes.length}  ·  Wischen für mehr  ›',
                  style: TextStyle(color: kInk.withValues(alpha: 0.55), fontWeight: FontWeight.w600),
                ),
              ),
            _StylePicker(
              selectedId: _styleFor(_index).id,
              onSelected: (id) {
                HapticFeedback.selectionClick();
                setState(() => _styleOverride = id);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: kWhatsApp,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _sharing ? null : () => _share(whatsapp: true),
                      icon: _sharing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.chat_rounded),
                      label: const Text('Per WhatsApp senden'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _sharing ? null : () => _share(whatsapp: false),
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Andere Apps'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await ShareService.copyText(_current);
                            _toast('Text kopiert ✓');
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Kopieren'),
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

class _StylePicker extends StatefulWidget {
  const _StylePicker({required this.selectedId, required this.onSelected});

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  State<_StylePicker> createState() => _StylePickerState();
}

class _StylePickerState extends State<_StylePicker> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: kCardStyles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final style = kCardStyles[i];
          final selected = style.id == widget.selectedId;
          return GestureDetector(
            onTap: () => widget.onSelected(style.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
              height: 56,
              padding: EdgeInsets.all(selected ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? kCoral : Colors.white, width: selected ? 3 : 2),
              ),
              child: ClipOval(
                child: style.image != null
                    ? Image.asset(style.image!, fit: BoxFit.cover, cacheWidth: 160)
                    : DecoratedBox(
                        decoration: BoxDecoration(gradient: style.gradient),
                        child: Center(child: Text(style.emoji, style: const TextStyle(fontSize: 18))),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
