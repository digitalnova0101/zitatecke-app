import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
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
                      'Diese App sammelt keine persönlichen Daten. '
                      'Deine Favoriten und Einstellungen werden nur auf deinem Gerät gespeichert.',
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
                  applicationLegalese:
                      'Sprüche zum Teilen für jeden Tag.\nMehr Sprüche auf $kWebsite',
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk),
        ),
      );
}

class _Box extends StatelessWidget {
  const _Box({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );
}
