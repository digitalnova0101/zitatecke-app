import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';

/// Dil wala button – dabane par "pop" animation + vibration.
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({super.key, required this.quoteId, this.size = 28, this.idleColor});

  final String quoteId;
  final double size;
  final Color? idleColor;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
  ]).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    appState.toggleFavorite(widget.quoteId);
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final fav = appState.isFavorite(widget.quoteId);
        return IconButton(
          tooltip: fav ? 'Aus Favoriten entfernen' : 'Merken',
          onPressed: _toggle,
          icon: ScaleTransition(
            scale: _scale,
            child: Icon(
              fav ? Icons.favorite : Icons.favorite_border,
              size: widget.size,
              color: fav ? kCoral : (widget.idleColor ?? kInk.withValues(alpha: 0.45)),
            ),
          ),
        );
      },
    );
  }
}

/// Screen khulne par halka sa fade + upar slide.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = 0});

  final Widget child;

  /// Milliseconds.
  final int delay;

  @override
  Widget build(BuildContext context) {
    final total = 450 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: child),
      ),
      child: child,
    );
  }
}

/// Dabane par thoda chhota hone wala wrapper (tiles ke liye).
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
