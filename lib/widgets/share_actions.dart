import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/quote.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import 'quote_card.dart';

/// Teilen + "Gesendet ✓" Animation + Danke-Meilensteine.
class Sharer {
  Sharer._();

  static bool _busy = false;

  /// Card jo screen pe dikh raha hai (RepaintBoundary [key]).
  static Future<void> shareVisible(
    BuildContext context, {
    required GlobalKey key,
    required Quote quote,
    required bool whatsapp,
  }) async {
    if (_busy) return;
    _busy = true;
    try {
      final r = whatsapp
          ? await ShareService.shareToWhatsApp(key, quote)
          : await ShareService.shareCardImage(key, quote);
      if (context.mounted) await _after(context, r, whatsapp);
    } catch (_) {
      if (context.mounted) _snack(context, 'Teilen hat leider nicht geklappt.');
    } finally {
      _busy = false;
    }
  }

  /// Card jo screen pe nahi hai (grid, long-press, reels): chupke se bana ke share.
  static Future<void> shareQuote(
    BuildContext context, {
    required Quote quote,
    required CardStyle style,
    required bool whatsapp,
  }) async {
    if (_busy) return;
    _busy = true;
    final overlay = Overlay.of(context, rootOverlay: true);
    final key = GlobalKey();
    final repo = appState.repo;
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -3000,
        top: 0,
        child: IgnorePointer(
          child: RepaintBoundary(
            key: key,
            child: Material(
              type: MaterialType.transparency,
              child: SizedBox(
              width: 360,
              height: 360,
              child: QuoteCard(
                quote: quote,
                style: style,
                heading: repo.headingFor(quote),
                font: appState.cardFont,
              ),
            ),
            ),
          ),
        ),
      ),
    );
    try {
      final img = style.imageProvider;
      if (img != null) await precacheImage(img, context);
      overlay.insert(entry);
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      final r = whatsapp
          ? await ShareService.shareToWhatsApp(key, quote)
          : await ShareService.shareCardImage(key, quote);
      if (context.mounted) await _after(context, r, whatsapp);
    } catch (_) {
      if (context.mounted) _snack(context, 'Teilen hat leider nicht geklappt.');
    } finally {
      entry.remove();
      _busy = false;
    }
  }

  static Future<void> _after(BuildContext context, ShareResultKind r, bool whatsapp) async {
    switch (r) {
      case ShareResultKind.failed:
        _snack(context, 'Teilen hat leider nicht geklappt.');
        return;
      case ShareResultKind.dismissed:
        return;
      case ShareResultKind.sheet:
        if (whatsapp) _snack(context, 'WhatsApp wurde nicht gefunden – andere App gewählt.');
        break;
      case ShareResultKind.whatsapp:
        break;
    }
    final n = await appState.countShare();
    if (!context.mounted) return;
    SentToast.show(context);
    if (const {10, 25, 50, 100, 250, 500}.contains(n)) {
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (context.mounted) _thanks(context, n);
    }
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  static void _thanks(BuildContext context, int n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Text('💛', style: TextStyle(fontSize: 48)),
        title: Text('Danke!', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontQuote, color: kInk)),
        content: Text(
          'Du hast schon $n liebe Grüße verschickt.\nDamit machst du anderen eine Freude!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, height: 1.4, color: kInk),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Gern geschehen')),
        ],
      ),
    );
  }
}

/// Kurze "Gesendet ✓" Animation in der Mitte.
class SentToast {
  SentToast._();

  static void show(BuildContext context) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    HapticFeedback.lightImpact();
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _SentToastView(onDone: () => entry.remove()));
    overlay.insert(entry);
  }
}

class _SentToastView extends StatefulWidget {
  const _SentToastView({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_SentToastView> createState() => _SentToastViewState();
}

class _SentToastViewState extends State<_SentToastView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _c.value;
            final scale = t < 0.25 ? Curves.easeOutBack.transform(t / 0.25) : 1.0;
            final opacity = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25);
            return Opacity(opacity: opacity.clamp(0, 1).toDouble(), child: Transform.scale(scale: scale, child: child));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: kWhatsApp,
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 36),
                ),
                SizedBox(height: 12),
                Text(
                  'Gesendet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.none,
                    fontFamily: kFontUi,
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
