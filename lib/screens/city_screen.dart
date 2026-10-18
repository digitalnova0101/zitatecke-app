import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

/// Shehar chunna (mausam wale Sprüche ke liye). Koi GPS nahi.
class CityScreen extends StatefulWidget {
  const CityScreen({super.key});

  @override
  State<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<City> _results = const [];
  bool _loading = false;
  String? _error;

  static const _popular = ['Berlin', 'Hamburg', 'München', 'Köln', 'Frankfurt am Main', 'Stuttgart',
    'Düsseldorf', 'Leipzig', 'Dresden', 'Hannover', 'Nürnberg', 'Wien', 'Zürich'];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
    setState(() {});
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await WeatherService.search(q);
      if (!mounted || _controller.text != q) return;
      setState(() => _results = r);
    } catch (_) {
      if (mounted) setState(() => _error = 'Keine Internetverbindung. Bitte später erneut versuchen.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _choose(City c) async {
    HapticFeedback.selectionClick();
    await appState.setCity(c);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final current = appState.weather.city;
    final q = _controller.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Deine Stadt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            'Wähle deine Stadt – dann zeigen wir dir Sprüche passend zum Wetter. '
            'Dein Standort wird nicht abgefragt.',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4, color: kInk.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: current == null,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kInk),
            decoration: InputDecoration(
              hintText: 'Stadt suchen … z. B. Köln',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.location_city_rounded),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),
          if (current != null && q.isEmpty) ...[
            _Tile(
              icon: Icons.check_circle_rounded,
              title: current.name,
              subtitle: 'Aktuell gewählt · ${current.region}',
              highlight: true,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                await appState.setCity(null);
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close),
              label: const Text('Stadt entfernen (keine Wetter-Sprüche)'),
            ),
            const SizedBox(height: 8),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: kCoral, fontWeight: FontWeight.w700)),
            ),
          if (q.isEmpty) ...[
            const Text('Beliebte Städte', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _popular)
                  ActionChip(
                    label: Text(c, style: const TextStyle(fontSize: 15)),
                    onPressed: () {
                      _controller.text = c;
                      _search(c);
                      setState(() {});
                    },
                  ),
              ],
            ),
          ] else if (!_loading && _results.isEmpty && _error == null && q.length >= 2)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Keine Stadt gefunden.', style: TextStyle(fontSize: 16, color: kInk.withValues(alpha: 0.6))),
            )
          else
            for (final c in _results)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Tile(
                  icon: Icons.place_outlined,
                  title: c.name,
                  subtitle: c.region,
                  onTap: () => _choose(c),
                ),
              ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.highlight = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: highlight ? kCoral : kInk.withValues(alpha: 0.6)),
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
