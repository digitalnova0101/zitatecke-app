import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/quote.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/animations.dart';
import '../widgets/quote_actions.dart';
import '../widgets/quote_card.dart';
import '../widgets/share_actions.dart';
import 'category_screen.dart';
import 'quote_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Ein Karussell-Eintrag: Spruch + kleines Label oben links (z. B. "📅 Sonntag").
class _Item {
  const _Item(this.quote, [this.label]);
  final Quote quote;
  final String? label;
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pc = PageController(viewportFraction: 0.92);
  final Map<int, GlobalKey> _cardKeys = {};
  int _page = 0;
  String? _listFor;

  // Wetter (Stadt wird in den Einstellungen gewählt)
  WeatherNow? _weather;
  String? _weatherFor;
  DateTime? _weatherAt;
  bool _weatherLoading = false;

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

  void _ensureWeather() {
    final city = appState.weather.city;
    if (city == null) {
      _weather = null;
      _weatherFor = null;
      return;
    }
    final key = '${city.lat},${city.lon}';
    final stale = _weatherAt == null || DateTime.now().difference(_weatherAt!) > const Duration(minutes: 30);
    if (_weatherLoading || (_weatherFor == key && !stale)) return;
    _weatherLoading = true;
    _weatherAt = DateTime.now();
    appState.weather.current().then((w) {
      if (!mounted) return;
      setState(() {
        _weather = w;
        _weatherFor = key;
        _weatherLoading = false;
      });
    });
  }

  /// Spruch des Tages: Tageszeit, Wetter, Wochentag, Feiertag, Zitat – alles automatisch.
  List<_Item> _buildItems(DateTime now, String categoryId) {
    final repo = appState.repo;
    final out = <_Item>[];
    void add(Quote? q, [String? label]) {
      if (q == null || out.any((e) => e.quote.id == q.id)) return;
      out.add(_Item(q, label));
    }

    add(repo.quoteOfTheDay(categoryId, now));
    final w = _weather;
    final city = appState.weather.city;
    if (w != null && city != null) {
      add(repo.weatherQuote(w.type, now), '${w.emoji} ${w.tempText} ${city.name}');
    }
    add(repo.weekdayQuote(now), '📅 ${kWeekdays[now.weekday - 1]}');
    final special = repo.specialFor(now);
    final specialQuotes = repo.specialQuotes(now);
    if (special != null && specialQuotes.isNotEmpty) add(specialQuotes.first, '🎉 ${special.name}');
    add(repo.quoteOfTheDay('zitate', now), '📜 Zitat des Tages');
    for (final q in repo.quotesOfTheDay(categoryId, count: 12, date: now)) {
      if (out.length >= 12) break;
      add(q);
    }
    return out;
  }

  Future<void> _share(Quote quote, {required bool whatsapp}) =>
      Sharer.shareVisible(context, key: _keyFor(_page), quote: quote, whatsapp: whatsapp);

  void _open(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: appState, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final repo = appState.repo;
    final now = DateTime.now();
    final ctx = _timeContext(now);
    _ensureWeather();
    final items = _buildItems(now, ctx.categoryId);
    final list = [for (final e in items) e.quote];

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkPalette ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: RefreshIndicator(
          color: kCoral,
          edgeOffset: MediaQuery.paddingOf(context).top,
          onRefresh: () async {
            _weatherAt = null;
            await appState.refreshContent(force: true);
          },
          child: ListView(
            padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _Header(now: now, greeting: ctx.greeting),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Ui.gap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    FadeSlideIn(
                      delay: 80,
                      child: Row(
                        children: [
                          const Expanded(child: _SectionTitle('Spruch des Tages')),
                          Material(
                            color: kCard,
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: 'Spruch suchen',
                              iconSize: 26,
                              onPressed: () => _open(const SearchScreen()),
                              icon: Icon(Icons.search_rounded, color: kInk),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeSlideIn(
                      delay: 140,
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final side = (c.maxWidth + 32) * 0.92 - 12;
                          return SizedBox(
                            height: side + 30,
                            child: OverflowBox(
                              maxWidth: c.maxWidth + 32,
                              child: PageView.builder(
                                controller: _pc,
                                itemCount: items.length,
                                onPageChanged: (i) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _page = i);
                                },
                                itemBuilder: (context, i) {
                                  final q = items[i].quote;
                                  final label = items[i].label;
                                  final st = styleById(repo.defaultStyleId(q, i));
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 26),
                                    child: GestureDetector(
                                      onTap: () => _open(QuoteDetailScreen(
                                          quotes: list, initialIndex: i, title: 'Spruch des Tages')),
                                      onLongPress: () =>
                                          showQuoteActions(context, q, style: st, list: list, index: i),
                                      child: Stack(
                                        children: [
                                          Hero(
                                            tag: 'card-${q.id}',
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(Ui.rCard),
                                                boxShadow: Ui.shadow(),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(Ui.rCard),
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
                                          ),
                                          Positioned(
                                            top: 12,
                                            left: 12,
                                            right: 12,
                                            child: Row(
                                              children: [
                                                if (label != null) _CardLabel(label),
                                                if (label != null && repo.isNewToday(q)) const SizedBox(width: 6),
                                                if (repo.isNewToday(q)) const _NewBadge(),
                                              ],
                                            ),
                                          ),
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
                    _Dots(count: items.length, index: _page),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      delay: 200,
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: kWhatsApp, foregroundColor: Colors.white),
                              onPressed: () => _share(quote, whatsapp: true),
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
                              onPressed: () => _share(quote, whatsapp: false),
                              child: const Icon(Icons.ios_share_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const FadeSlideIn(delay: 240, child: _SectionTitle('Kategorien')),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.08,
                      children: [
                        for (final (i, c) in repo.categories.indexed)
                          FadeSlideIn(
                            delay: 260 + i * 45,
                            child: _CategoryTile(
                              id: c.id,
                              emoji: c.emoji,
                              title: c.title,
                              count: repo.byCategory(c.id).length,
                              newCount: repo.newTodayCount(c.id),
                              onTap: () => _open(CategoryScreen(categoryId: c.id)),
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
        style: TextStyle(fontFamily: kFontQuote, fontSize: 22, fontWeight: FontWeight.w700, color: kInk),
      );
}

/// Kleines Label auf der Karte (nicht im geteilten Bild).
class _CardLabel extends StatelessWidget {
  const _CardLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
      );
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

/// Kategorie-Kachel: Pastell-Verlauf + 3D-Illustration.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.id,
    required this.emoji,
    required this.title,
    required this.count,
    required this.onTap,
    this.newCount = 0,
  });

  final String id;
  final String emoji;
  final String title;
  final int count;
  final int newCount;
  final VoidCallback onTap;

  static const Map<String, List<Color>> _pastel = {
    'guten_morgen': [Color(0xFFFFEBCF), Color(0xFFFFC8A6)],
    'gute_nacht': [Color(0xFFE0DEFF), Color(0xFFAFB9F2)],
    'motivation': [Color(0xFFD9F6E8), Color(0xFFA6E2C4)],
    'zitate': [Color(0xFFF6EAD8), Color(0xFFE4CBA6)],
    'wochentage': [Color(0xFFDFEDFF), Color(0xFFB8D3FA)],
    'wochenende': [Color(0xFFD6F5F2), Color(0xFF9FDFD8)],
    'freundschaft': [Color(0xFFFFE4EE), Color(0xFFFFBDD2)],
    'geburtstag': [Color(0xFFF5E4FF), Color(0xFFDBB6F4)],
    'feiertage': [Color(0xFFE0F4E2), Color(0xFFB3DDB8)],
  };

  @override
  Widget build(BuildContext context) {
    final dark = isDarkPalette;
    var colors = _pastel[id] ?? const [Color(0xFFFFE8DC), Color(0xFFFFC2B0)];
    if (dark) colors = colors.map((c) => Color.lerp(c, const Color(0xFF1A161C), 0.62)!).toList();
    final fg = dark ? Colors.white : const Color(0xFF3B2A35);

    return PressScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(Ui.rTile + 2), boxShadow: Ui.shadow(0.5)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Ui.rTile + 2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: Image.asset(
                    'assets/illustrations/$id.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (_, __, ___) => Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(emoji, style: const TextStyle(fontSize: 54)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        style: TextStyle(
                          fontFamily: kFontQuote,
                          fontSize: 18,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count Sprüche',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fg.withValues(alpha: 0.65)),
                      ),
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
                ),
              ],
            ),
          ),
        ),
      ),
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

/// Kopfbereich: Datum, Begrüßung und Logo.
class _Header extends StatelessWidget {
  const _Header({required this.now, required this.greeting});
  final DateTime now;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(Ui.gap, top + 12, Ui.gap, 18),
      child: FadeSlideIn(
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
                    greeting,
                    style: TextStyle(
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
    );
  }
}
