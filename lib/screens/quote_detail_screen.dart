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
import '../widgets/quote_card.dart';
import '../widgets/share_actions.dart';

/// Bada card + neeche ek bar: [🎨 Gestalten] [Teilen] [WhatsApp].
/// "Gestalten" se Bild / Schrift panel khulta hai.
class QuoteDetailScreen extends StatefulWidget {
  const QuoteDetailScreen({
    super.key,
    required this.quotes,
    this.initialIndex = 0,
    this.title,
    this.startEditing = false,
  });

  final List<Quote> quotes;
  final int initialIndex;
  final String? title;
  final bool startEditing;

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  late final PageController _pageController;
  late int _index;
  late bool _editing = widget.startEditing;
  String? _styleOverride;
  bool _fontTab = false; // false = Bild, true = Schrift
  final Map<int, GlobalKey> _cardKeys = {};

  GlobalKey _keyFor(int i) => _cardKeys.putIfAbsent(i, () => GlobalKey());

  Quote get _current => widget.quotes[_index];

  CardStyle _styleFor(int i) =>
      styleById(_styleOverride ?? appState.repo.defaultStyleId(widget.quotes[i], i));

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

  Future<void> _share({required bool whatsapp}) =>
      Sharer.shareVisible(context, key: _keyFor(_index), quote: _current, whatsapp: whatsapp);

  @override
  Widget build(BuildContext context) {
    final repo = appState.repo;
    final title = widget.title ?? repo.category(_current.category).title;
    final font = appState.cardFont;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Text kopieren',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await ShareService.copyText(_current);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text kopiert ✓')));
              }
            },
          ),
          FavoriteButton(quoteId: _current.id, size: 28),
          const SizedBox(width: 4),
        ],
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
                      final side = math.max(120.0, math.min(c.maxWidth - 32, c.maxHeight - 16));
                      return Center(
                        child: GestureDetector(
                          onLongPress: () => showQuoteActions(context, quote, style: style, list: widget.quotes, index: i),
                          child: Hero(
                            tag: 'card-${quote.id}',
                            child: Container(
                              width: side,
                              height: side,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Ui.rCard),
                                boxShadow: Ui.shadow(1.4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(Ui.rCard),
                                child: RepaintBoundary(
                                  key: _keyFor(i),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 280),
                                    child: QuoteCard(
                                      key: ValueKey('${quote.id}-${style.id}-${font.id}'),
                                      quote: quote,
                                      style: style,
                                      heading: repo.headingFor(quote),
                                      font: font,
                                    ),
                                  ),
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
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${_index + 1} / ${widget.quotes.length}  ·  Wischen für mehr  ›',
                  style: TextStyle(color: kInk.withValues(alpha: 0.5), fontWeight: FontWeight.w700),
                ),
              ),
            // Gestalten-Panel (Bild / Schrift)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: _editing
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          _PickerTabs(
                            fontTab: _fontTab,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              setState(() => _fontTab = v);
                            },
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _fontTab
                                ? _FontPicker(
                                    key: const ValueKey('fonts'),
                                    selectedId: font.id,
                                    onSelected: (id) async {
                                      HapticFeedback.selectionClick();
                                      await appState.setCardFont(id);
                                      if (mounted) setState(() {});
                                    },
                                  )
                                : _StylePicker(
                                    key: const ValueKey('styles'),
                                    selectedId: _styleFor(_index).id,
                                    onSelected: (id) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _styleOverride = id);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            // Bottom bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        backgroundColor: _editing ? kCoral.withValues(alpha: 0.14) : kCard,
                        side: BorderSide(color: _editing ? kCoral : kInk.withValues(alpha: 0.15), width: _editing ? 2 : 1),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _editing = !_editing);
                      },
                      icon: Icon(_editing ? Icons.check_rounded : Icons.palette_outlined,
                          color: _editing ? kCoral : kInk),
                      label: Text(_editing ? 'Fertig' : 'Gestalten'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => _share(whatsapp: false),
                      child: const Tooltip(message: 'Andere Apps', child: Icon(Icons.ios_share_rounded)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: kWhatsApp,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () => _share(whatsapp: true),
                      icon: const Icon(Icons.chat_rounded),
                      label: const FittedBox(child: Text('WhatsApp')),
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

class _StylePicker extends StatefulWidget {
  const _StylePicker({super.key, required this.selectedId, required this.onSelected});

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  State<_StylePicker> createState() => _StylePickerState();
}

class _StylePickerState extends State<_StylePicker> {
  final _controller = ScrollController();
  final List<CardStyle> _styles = pickerStyles();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _styles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final style = _styles[i];
          final selected = style.id == widget.selectedId;
          return GestureDetector(
            onTap: () => widget.onSelected(style.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 58,
              height: 58,
              padding: EdgeInsets.all(selected ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? kCoral : kCard, width: selected ? 3 : 2),
              ),
              child: ClipOval(
                child: style.hasPhoto
                    ? Image(image: style.thumbProvider(160)!, fit: BoxFit.cover)
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

/// "🖼️ Bild | Aa Schrift"
class _PickerTabs extends StatelessWidget {
  const _PickerTabs({required this.fontTab, required this.onChanged});
  final bool fontTab;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, IconData icon, bool selected, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: selected ? kCard : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected ? Ui.shadow(0.5) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: selected ? kCoral : kInk.withValues(alpha: 0.55)),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: selected ? kInk : kInk.withValues(alpha: 0.55))),
                ],
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: kInk.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            tab('Bild', Icons.image_outlined, !fontTab, () => onChanged(false)),
            tab('Schrift', Icons.text_fields_rounded, fontTab, () => onChanged(true)),
          ],
        ),
      ),
    );
  }
}

/// Font chunna: har button pe "Aa" usi font mein.
class _FontPicker extends StatelessWidget {
  const _FontPicker({super.key, required this.selectedId, required this.onSelected});
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        itemCount: kCardFonts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = kCardFonts[i];
          final selected = f.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(f.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 76,
              decoration: BoxDecoration(
                color: selected ? kCoral.withValues(alpha: 0.14) : kCard,
                borderRadius: BorderRadius.circular(Ui.rChip),
                border: Border.all(color: selected ? kCoral : kInk.withValues(alpha: 0.12), width: selected ? 2.5 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Aa',
                      style: TextStyle(
                          fontFamily: f.family,
                          fontWeight: f.weight,
                          fontSize: 22 * f.scale.clamp(0.9, 1.25).toDouble(),
                          height: 1.1,
                          color: kInk)),
                  const SizedBox(height: 2),
                  Text(f.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kInk.withValues(alpha: 0.65))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
