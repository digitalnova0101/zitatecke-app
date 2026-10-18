import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../services/content_service.dart';
import 'city_screen.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Uhrzeit wählen',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) => ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.paddingOf(context).bottom + 24),
          children: [
            const _Header('Erscheinungsbild'),
            _Box(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: kCoral.withValues(alpha: 0.16),
                      selectedForegroundColor: kCoral,
                      foregroundColor: kInk,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    segments: const [
                      ButtonSegment(value: 'auto', icon: Icon(Icons.brightness_auto_rounded), label: Text('Auto')),
                      ButtonSegment(value: 'light', icon: Icon(Icons.light_mode_rounded), label: Text('Hell')),
                      ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode_rounded), label: Text('Dunkel')),
                    ],
                    selected: {appState.themeSetting},
                    onSelectionChanged: (v) => appState.setThemeSetting(v.first),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 14),
                child: Text(
                  'Auto: dunkel, wenn dein Handy auf dunkel steht – und abends ab 21 Uhr.',
                  style: TextStyle(fontSize: 13.5, height: 1.35, color: kInk.withValues(alpha: 0.6)),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            const _Header('Tägliche Erinnerung'),
            _Box(children: [
              SwitchListTile(
                secondary: const Text('☀️', style: TextStyle(fontSize: 26)),
                title: const Text('Morgengruß', style: TextStyle(fontSize: 17)),
                subtitle: Text('Jeden Morgen um ${formatTime(appState.morningTime)}'),
                value: appState.morningOn,
                onChanged: (v) => appState.setMorning(on: v),
              ),
              ListTile(
                enabled: appState.morningOn,
                leading: const Icon(Icons.schedule),
                title: const Text('Uhrzeit ändern'),
                trailing: Text(formatTime(appState.morningTime)),
                onTap: () async {
                  final t = await _pickTime(context, appState.morningTime);
                  if (t != null) await appState.setMorning(time: t);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Text('🌙', style: TextStyle(fontSize: 26)),
                title: const Text('Gute-Nacht-Gruß', style: TextStyle(fontSize: 17)),
                subtitle: Text('Jeden Abend um ${formatTime(appState.nightTime)}'),
                value: appState.nightOn,
                onChanged: (v) => appState.setNight(on: v),
              ),
              ListTile(
                enabled: appState.nightOn,
                leading: const Icon(Icons.schedule),
                title: const Text('Uhrzeit ändern'),
                trailing: Text(formatTime(appState.nightTime)),
                onTap: () async {
                  final t = await _pickTime(context, appState.nightTime);
                  if (t != null) await appState.setNight(time: t);
                },
              ),
            ]),
            const SizedBox(height: 24),
            const _Header('Wetter'),
            _Box(children: [
              ListTile(
                leading: const Text('🌦️', style: TextStyle(fontSize: 26)),
                title: const Text('Meine Stadt', style: TextStyle(fontSize: 17)),
                subtitle: Text(appState.weather.city == null
                    ? 'Nicht gewählt – für Wetter-Sprüche antippen'
                    : '${appState.weather.city!.name} · ${appState.weather.city!.region}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CityScreen())),
              ),
            ]),
            const SizedBox(height: 24),
            const _Header('Neue Sprüche'),
            _Box(children: [
              ListTile(
                leading: const Text('✨', style: TextStyle(fontSize: 26)),
                title: const Text('Täglich neue Sprüche', style: TextStyle(fontSize: 17)),
                subtitle: Text(_lastUpdateText()),
              ),
              ListTile(
                leading: appState.refreshing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded),
                title: const Text('Jetzt aktualisieren'),
                enabled: !appState.refreshing,
                onTap: () async {
                  final changed = await appState.refreshContent(force: true);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(changed
                        ? 'Neue Sprüche geladen ✓'
                        : 'Keine Verbindung – bitte später erneut versuchen.'),
                  ));
                },
              ),
            ]),
            const SizedBox(height: 24),
            const _Header('Info'),
            _Box(children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Datenschutz'),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Datenschutz'),
                    content: const Text(
                      'Diese App sammelt keine persönlichen Daten und nutzt kein Tracking.\n\n'
                      '• Favoriten und Einstellungen werden nur auf deinem Gerät gespeichert.\n'
                      '• Neue Sprüche und Bilder werden von $kWebsite geladen.\n'
                      '• Für Wetter-Sprüche wird nur die von dir gewählte Stadt (Koordinaten) an Open-Meteo '
                      '(open-meteo.com) gesendet. Dein Standort wird nicht abgefragt.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Über die App'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: kStoreTitle,
                  applicationVersion: '1.0.0',
                  applicationIcon: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/brand/splash_logo.png', width: 48, height: 48),
                  ),
                  applicationLegalese:
                      'Sprüche zum Teilen für jeden Tag.\nMehr Sprüche auf $kWebsite\n\n'
                      'Fotos: gemeinfrei (CC0 / Public Domain)\nSchriften: SIL Open Font License\nIllustrationen: Microsoft Fluent Emoji (MIT)',
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

String _lastUpdateText() {
  final t = ContentService.instance.lastFetch;
  if (t == null) return 'Noch nicht geladen';
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  final now = DateTime.now();
  final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
  return sameDay ? 'Zuletzt aktualisiert: heute, $hh:$mm Uhr' : 'Zuletzt aktualisiert: ${t.day}.${t.month}., $hh:$mm Uhr';
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: TextStyle(fontFamily: kFontQuote, fontSize: 19, fontWeight: FontWeight.w700, color: kInk),
        ),
      );
}

class _Box extends StatelessWidget {
  const _Box({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );
}
