import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/quote.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/animations.dart';
import '../widgets/quote_card.dart';
import '../services/weather_service.dart';
import 'category_screen.dart';
import 'city_screen.dart';
import 'quote_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pc = PageController(viewportFraction: 0.92);
  final Map<int, GlobalKey> _cardKeys = {};
  int _page = 0;
  String? _listFor;
  bool _sharing = false;

  GlobalKey _keyFor(int i) => _cardKeys.putIfAbsent(i, () => GlobalKey());

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

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
          ? await ShareService.shareToWhatsApp(_keyFor(_page), quote)
          : await ShareService.shareCardImage(_keyFor(_page), quote);
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
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: appState, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final repo = appState.repo;
    final now = DateTime.now();
    final ctx = _timeContext(now);
    final list = repo.quotesOfTheDay(ctx.categoryId, date: now);
    final listId = '${ctx.categoryId}-${list.first.id}';
    if (_listFor != listId) {
      // Naya din / naya waqt → pehla card.
      _listFor = listId;
      _page = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pc.hasClients && (_pc.page ?? 0) != 0) _pc.jumpToPage(0);
      });
    }
    if (_page >= list.length) _page = 0;
    final quote = list[_page];
    final font = appState.cardFont;
    CardStyle styleAt(int i) {
      final q = list[i];
      if (q.isAi) return styleById(repo.defaultStyleId(q, i));
      final styles = repo.category(ctx.categoryId).styles;
      return styleById(styles[i % styles.length]);
    }
    final today = kWeekdays[now.weekday - 1];
    final special = repo.specialFor(now);
    final specialQuotes = repo.specialQuotes(now);

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
            if (special != null && specialQuotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: 90,
                child: _SpecialBanner(
                  name: special.name,
                  count: specialQuotes.length,
                  onTap: () => _open(QuoteDetailScreen(quotes: specialQuotes, title: special.name)),
                ),
              ),
            ],
            const SizedBox(height: 22),
            const FadeSlideIn(delay: 120, child: _SectionTitle('Spruch des Tages')),
            const SizedBox(height: 10),
            FadeSlideIn(
              delay: 160,
              child: LayoutBuilder(
                builder: (context, c) {
                  final side = (c.maxWidth + 32) * 0.92 - 12;
                  return SizedBox(
                    height: side + 30,
                    child: OverflowBox(
                      maxWidth: c.maxWidth + 32,
                      child: PageView.builder(
                        controller: _pc,
                        itemCount: list.length,
                        onPageChanged: (i) {
                          HapticFeedback.selectionClick();
                          setState(() => _page = i);
                        },
                        itemBuilder: (context, i) {
                          final q = list[i];
                          final st = styleAt(i);
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(6, 4, 6, 26),
                            child: GestureDetector(
                              onTap: () => _open(QuoteDetailScreen(quotes: list, initialIndex: i, title: 'Spruch des Tages')),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(color: kInk.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 8)),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: RepaintBoundary(
                                        key: _keyFor(i),
                                        child: QuoteCard(
                                          key: ValueKey('${q.id}-${st.id}-${font.id}'),
                                          quote: q,
                                          style: st,
                                          heading: repo.headingFor(q),
                                          font: font,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (repo.isNewToday(q))
                                    const Positioned(top: 12, left: 12, child: _NewBadge()),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            _Dots(count: list.length, index: _page),
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
            const SizedBox(height: 26),
            FadeSlideIn(delay: 220, child: _WeatherSection(key: ValueKey(appState.weather.city?.name))),
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
                      newCount: repo.newTodayCount(c.id),
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
    this.newCount = 0,
  });

  final String emoji;
  final String title;
  final int count;
  final int newCount;
  final CardStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPhoto = style.hasPhoto;
    final textColor = isPhoto ? Colors.white : style.textColor;
    return PressScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isPhoto)
              Image(image: style.thumbProvider(500)!, fit: BoxFit.cover)
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
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 30)),
                      const Spacer(),
                      if (newCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: kCoral, borderRadius: BorderRadius.circular(10)),
                          child: Text('+$newCount neu',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
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


class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: kBrandGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
        ),
        child: const Text('NEU ✨', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      );
}

class _SpecialBanner extends StatelessWidget {
  const _SpecialBanner({required this.name, required this.count, required this.onTap});
  final String name;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: kBrandGradient, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 34)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Heute ist $name',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('$count neue Sprüche zum Anlass',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Mausam: "Heute in Köln · 🌧️ 12°" + passender Spruch.
class _WeatherSection extends StatefulWidget {
  const _WeatherSection({super.key});

  @override
  State<_WeatherSection> createState() => _WeatherSectionState();
}

class _WeatherSectionState extends State<_WeatherSection> {
  final GlobalKey _cardKey = GlobalKey();
  Future<WeatherNow?>? _future;
  String? _forCity;
  DateTime? _at;
  bool _sharing = false;

  void _ensureFuture(City city) {
    final key = '${city.lat},${city.lon}';
    final stale = _at == null || DateTime.now().difference(_at!) > const Duration(minutes: 30);
    if (_future == null || _forCity != key || stale) {
      _forCity = key;
      _at = DateTime.now();
      _future = appState.weather.current();
    }
  }

  Future<void> _share(Quote q, {required bool whatsapp}) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final r = whatsapp
          ? await ShareService.shareToWhatsApp(_cardKey, q)
          : await ShareService.shareCardImage(_cardKey, q);
      if (whatsapp && r == ShareResultKind.sheet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('WhatsApp wurde nicht gefunden – wähle eine andere App.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _pickCity() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CityScreen()));

  @override
  Widget build(BuildContext context) {
    final city = appState.weather.city;
    if (city == null) {
      return PressScale(
        onTap: _pickCity,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kCoral.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Row(
            children: [
              const Text('🌦️', style: TextStyle(fontSize: 34)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Wetter-Sprüche', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
                    Text('Wähle deine Stadt für Sprüche passend zum Wetter',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kInk.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: kInk),
            ],
          ),
        ),
      );
    }
    _ensureFuture(city);
    return FutureBuilder<WeatherNow?>(
      future: _future,
      builder: (context, snap) {
        final w = snap.data;
        final header = Row(
          children: [
            Expanded(
              child: Text(
                w == null
                    ? (snap.connectionState == ConnectionState.waiting ? 'Wetter in ${city.name} …' : 'Wetter in ${city.name}')
                    : 'Heute in ${city.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: kFontQuote, fontSize: 22, fontWeight: FontWeight.w700, color: kInk),
              ),
            ),
            if (w != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Text('${w.emoji} ${w.tempText} · ${w.label}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kInk)),
              )
            else
              IconButton(
                tooltip: 'Stadt ändern',
                onPressed: _pickCity,
                icon: const Icon(Icons.edit_location_alt_outlined),
              ),
          ],
        );
        if (w == null) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Column(children: [header, const SizedBox(height: 12), const LinearProgressIndicator()]);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 6),
              Text('Wetter gerade nicht verfügbar (keine Internetverbindung?).',
                  style: TextStyle(fontSize: 15, color: kInk.withValues(alpha: 0.6))),
              TextButton(
                onPressed: () => setState(() => _future = appState.weather.current(force: true)),
                child: const Text('Erneut versuchen'),
              ),
            ],
          );
        }
        final repo = appState.repo;
        final q = repo.weatherQuote(w.type);
        if (q == null) return header;
        final style = styleById(repo.defaultStyleId(q, 0));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => QuoteDetailScreen(quotes: [q], title: 'Wetter-Spruch'),
              )),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: kInk.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: QuoteCard(quote: q, style: style, heading: repo.headingFor(q), font: appState.cardFont),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: kWhatsApp, foregroundColor: Colors.white),
                    onPressed: _sharing ? null : () => _share(q, whatsapp: true),
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
                    onPressed: _sharing ? null : () => _share(q, whatsapp: false),
                    child: const Icon(Icons.share_outlined),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}


/// ● ○ ○  +  "Wischen für mehr"
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == index ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == index ? kCoral : kInk.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          index == 0 ? 'Wischen für mehr Sprüche  ›' : '${index + 1} von $count',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}
