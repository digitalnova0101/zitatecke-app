import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quote.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/animations.dart';
import '../widgets/quote_card.dart';
import 'category_screen.dart';
import 'quote_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _heroKey = GlobalKey();
  bool _sharing = false;

  /// Subah: Guten Morgen, din mein: Motivation, shaam/raat: Gute Nacht.
  ({String greeting, String categoryId}) _timeContext(DateTime now) {
    final h = now.hour;
    if (h >= 4 && h < 11) return (greeting: 'Guten Morgen!', categoryId: 'guten_morgen');
    if (h >= 11 && h < 17) return (greeting: 'Schönen Tag!', categoryId: 'motivation');
    if (h >= 17 && h < 21) return (greeting: 'Guten Abend!', categoryId: 'gute_nacht');
    return (greeting: 'Gute Nacht!', categoryId: 'gute_nacht');
  }

  Future<void> _share(Quote quote, {required bool whatsapp}) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final r = whatsapp
          ? await ShareService.shareToWhatsApp(_heroKey, quote)
          : await ShareService.shareCardImage(_heroKey, quote);
      if (whatsapp && r == ShareResultKind.sheet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('WhatsApp wurde nicht gefunden – wähle eine andere App.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final repo = appState.repo;
    final now = DateTime.now();
    final ctx = _timeContext(now);
    final quote = repo.quoteOfTheDay(ctx.categoryId, now);
    final heroStyle = styleById(repo.category(ctx.categoryId).styles.first);
    final today = kWeekdays[now.weekday - 1];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            FadeSlideIn(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          germanDate(now),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk.withValues(alpha: 0.55)),
                        ),
                        Text(
                          ctx.greeting,
                          style: const TextStyle(
                            fontFamily: kFontScript,
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: kInk,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset('assets/brand/splash_logo.png', width: 46, height: 46),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: 60,
              child: _SearchPill(onTap: () => _open(const SearchScreen())),
            ),
            const SizedBox(height: 22),
            const FadeSlideIn(delay: 120, child: _SectionTitle('Spruch des Tages')),
            const SizedBox(height: 10),
            FadeSlideIn(
              delay: 160,
              child: GestureDetector(
                onTap: () => _open(QuoteDetailScreen(quotes: [quote])),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: kInk.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: RepaintBoundary(
                      key: _heroKey,
                      child: QuoteCard(
                        quote: quote,
                        style: heroStyle,
                        heading: repo.headingFor(quote),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: 200,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: kWhatsApp, foregroundColor: Colors.white),
                      onPressed: _sharing ? null : () => _share(quote, whatsapp: true),
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text('Per WhatsApp senden'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: _sharing ? null : () => _share(quote, whatsapp: false),
                      child: const Icon(Icons.share_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: 240,
              child: _TodayBanner(
                weekday: today,
                onTap: () => _open(CategoryScreen(categoryId: 'wochentage', initialTag: weekdayTag(now))),
              ),
            ),
            const SizedBox(height: 26),
            const FadeSlideIn(delay: 280, child: _SectionTitle('Kategorien')),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: [
                for (final (i, c) in repo.categories.indexed)
                  FadeSlideIn(
                    delay: 300 + i * 50,
                    child: _CategoryTile(
                      emoji: c.emoji,
                      title: c.title,
                      count: repo.byCategory(c.id).length,
                      style: styleById(c.styles.first),
                      onTap: () => _open(CategoryScreen(categoryId: c.id)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(Icons.search, color: kInk.withValues(alpha: 0.6)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Spruch suchen … z. B. „Geburtstag“',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontFamily: kFontQuote, fontSize: 22, fontWeight: FontWeight.w700, color: kInk),
      );
}

class _TodayBanner extends StatelessWidget {
  const _TodayBanner({required this.weekday, required this.onTap});
  final String weekday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(gradient: kBrandGradient, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Text(
                weekday.substring(0, 2),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heute ist $weekday',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kInk),
                  ),
                  Text(
                    'Passende Sprüche für heute',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kInk.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kInk),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.emoji,
    required this.title,
    required this.count,
    required this.style,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final int count;
  final CardStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPhoto = style.image != null;
    final textColor = isPhoto ? Colors.white : style.textColor;
    return PressScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isPhoto)
              Image.asset(style.image!, fit: BoxFit.cover, cacheWidth: 500)
            else
              DecoratedBox(decoration: BoxDecoration(gradient: style.gradient)),
            if (isPhoto)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.62)],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: kFontQuote, fontSize: 19, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  Text(
                    '$count Sprüche',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor.withValues(alpha: 0.85)),
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
