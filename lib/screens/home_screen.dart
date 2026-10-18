import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quote.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/quote_card.dart';
import 'category_screen.dart';
import 'quote_detail_screen.dart';

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
    if (h >= 11 && h < 17) return (greeting: 'Hallo!', categoryId: 'motivation');
    if (h >= 17 && h < 21) return (greeting: 'Guten Abend!', categoryId: 'gute_nacht');
    return (greeting: 'Gute Nacht!', categoryId: 'gute_nacht');
  }

  Future<void> _share(Quote quote) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await ShareService.shareCardImage(_heroKey, quote);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _openCategory(String id, {String? tag}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CategoryScreen(categoryId: id, initialTag: tag),
    ));
  }

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              germanDate(now),
              style: TextStyle(fontSize: 15, color: kInk.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 2),
            Text(
              ctx.greeting,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: kInk,
              ),
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Spruch des Tages'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => QuoteDetailScreen(quotes: [quote]),
              )),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
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
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _sharing ? null : () => _share(quote),
              icon: const Icon(Icons.share),
              label: const Text('Jetzt teilen'),
            ),
            const SizedBox(height: 16),
            _TodayBanner(
              weekday: today,
              onTap: () => _openCategory('wochentage', tag: weekdayTag(now)),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Kategorien'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                for (final c in repo.categories)
                  _CategoryTile(
                    emoji: c.emoji,
                    title: c.title,
                    count: repo.byCategory(c.id).length,
                    style: styleById(c.styles.first),
                    onTap: () => _openCategory(c.id),
                  ),
              ],
            ),
          ],
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
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kInk),
      );
}

class _TodayBanner extends StatelessWidget {
  const _TodayBanner({required this.weekday, required this.onTap});
  final String weekday;
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heute ist $weekday',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kInk),
                    ),
                    Text(
                      'Sprüche für $weekday ansehen',
                      style: TextStyle(fontSize: 15, color: kInk.withValues(alpha: 0.65)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: kInk),
            ],
          ),
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
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(gradient: style.gradient),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 34)),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: style.textColor,
                  ),
                ),
                Text(
                  '$count Sprüche',
                  style: TextStyle(
                    fontSize: 14,
                    color: style.textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
