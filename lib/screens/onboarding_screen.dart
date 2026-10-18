import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/quote_card.dart';

/// Pehli baar app khulne par 3 chhoti screens.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;
  bool _busy = false;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    _pc.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  Future<void> _finish({required bool notifications}) async {
    if (_busy) return;
    setState(() => _busy = true);
    await appState.completeOnboarding(notifications: notifications);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final sample = appState.repo.quoteOfTheDay('guten_morgen');
    final pages = [
      _Page(
        visual: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Image.asset('assets/brand/splash_logo.png', width: 150, height: 150),
        ),
        title: 'Willkommen bei Zitatecke',
        text: 'Schöne Sprüche und liebe Grüße für jeden Tag – für Familie, Freunde und dich.',
      ),
      _Page(
        visual: SizedBox(
          width: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: QuoteCard(
              quote: sample,
              style: styleById(appState.repo.category('guten_morgen').styles.first),
              heading: 'Guten Morgen',
            ),
          ),
        ),
        title: 'Mit einem Tipp teilen',
        text: 'Wähle einen Spruch, such dir ein schönes Bild aus und schick ihn direkt per WhatsApp.',
      ),
      const _Page(
        visual: _BellVisual(),
        title: 'Jeden Tag ein lieber Gruß',
        text: 'Möchtest du morgens und abends einen neuen Spruch aufs Handy bekommen?',
      ),
    ];
    final last = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: last ? null : () => _pc.animateToPage(pages.length - 1,
                      duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic),
                  child: Text('Überspringen',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk.withValues(alpha: 0.6))),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (i) => setState(() => _page = i),
                children: pages,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? kCoral : kInk.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: last
                    ? Column(
                        key: const ValueKey('last'),
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : () => _finish(notifications: true),
                              child: const Text('Ja, gerne! 🔔'),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: _busy ? null : () => _finish(notifications: false),
                            child: Text('Vielleicht später',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk.withValues(alpha: 0.6))),
                          ),
                        ],
                      )
                    : SizedBox(
                        key: const ValueKey('next'),
                        width: double.infinity,
                        child: FilledButton(onPressed: _next, child: const Text('Weiter')),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.visual, required this.title, required this.text});

  final Widget visual;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: visual)),
          const SizedBox(height: 34),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: kFontQuote, fontSize: 28, fontWeight: FontWeight.w700, color: kInk, height: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.45, color: kInk.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _BellVisual extends StatelessWidget {
  const _BellVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: const BoxDecoration(gradient: kBrandGradient, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Icons.notifications_active_rounded, size: 70, color: Colors.white),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TimeChip(emoji: '☀️', text: '07:30'),
            const SizedBox(width: 10),
            _TimeChip(emoji: '🌙', text: '21:30'),
          ],
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.emoji, required this.text});
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Text('$emoji  $text Uhr', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kInk)),
      );
}
