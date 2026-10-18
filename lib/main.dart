import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'config.dart';
import 'data/quote_repository.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/quote_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'services/content_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repo = await QuoteRepository.load();
  appState = AppState(repo, prefs);
  try {
    await ContentService.instance.init(repo); // pehle se save AI quotes (offline)
  } catch (e) {
    debugPrint('Content init failed: $e');
  }

  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }
  NotificationService.instance.onTap = _openQuoteFromNotification;

  runApp(const SpruecheApp());
}

void _openQuoteFromNotification(String quoteId) {
  final quote = appState.repo.byId(quoteId);
  if (quote == null) return;
  navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => QuoteDetailScreen(quotes: [quote])),
  );
}

class SpruecheApp extends StatefulWidget {
  const SpruecheApp({super.key});

  @override
  State<SpruecheApp> createState() => _SpruecheAppState();
}

class _SpruecheAppState extends State<SpruecheApp> with WidgetsBindingObserver {
  bool? _lastDark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  bool _isDark(BuildContext context) {
    switch (appState.themeSetting) {
      case 'dark':
        return true;
      case 'light':
        return false;
      default: // auto: Handy-Einstellung oder nachts
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark || isNightHour(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final dark = _isDark(context);
        if (_lastDark != null && _lastDark != dark) {
          navigatorKey = GlobalKey<NavigatorState>(); // komplett neu aufbauen
        }
        _lastDark = dark;
        return MaterialApp(
          key: ValueKey(dark), // Farbwechsel → alles neu zeichnen
          title: kAppName,
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: buildAppTheme(dark: dark),
          locale: const Locale('de'),
          supportedLocales: const [Locale('de')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const _Root(),
        );
      },
    );
  }
}

/// Pehli baar: welcome screens, uske baad normal app.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late bool _done = appState.onboardingDone;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _done
          ? const MainShell()
          : OnboardingScreen(onDone: () => setState(() => _done = true)),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App wapas khuli (agle din) → naye quotes check.
    if (state == AppLifecycleState.resumed) appState.refreshContent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final payload = NotificationService.instance.launchPayload;
      if (payload != null) {
        NotificationService.instance.launchPayload = null;
        _openQuoteFromNotification(payload);
      }
      appState.setupNotificationsOnStart();
      appState.refreshContent(); // naye AI quotes (background)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: const [
          HomeScreen(),
          FavoritesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _FloatingNav(
        index: _tab,
        onTap: (i) {
          HapticFeedback.selectionClick();
          setState(() => _tab = i);
        },
      ),
    );
  }
}

/// Schwebende "Pille" unten, mit Blur.
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Start'),
    (Icons.favorite_border_rounded, Icons.favorite_rounded, 'Favoriten'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Einstellungen'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), boxShadow: Ui.shadow(1.3)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: kCard.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: kInk.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  for (final (i, it) in _items.indexed)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == index,
                        label: it.$3,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            decoration: BoxDecoration(
                              color: i == index ? kCoral.withValues(alpha: 0.14) : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(i == index ? it.$2 : it.$1,
                                    color: i == index ? kCoral : kInk.withValues(alpha: 0.65), size: 26),
                                if (i == index) ...[
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      it.$3,
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                      style: const TextStyle(
                                          color: kCoral, fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
