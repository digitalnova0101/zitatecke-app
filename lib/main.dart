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
          // Große Schrift (Handy-Einstellung) erlauben, aber Layout nicht sprengen.
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3)),
              child: child!,
            );
          },
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
      body: IndexedStack(
        index: _tab,
        children: const [
          HomeScreen(),
          FavoritesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          setState(() => _tab = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Start',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoriten',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
        ],
      ),
    );
  }
}
