import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config.dart';
import '../models/quote.dart';
import '../theme/card_styles.dart';

/// Square quote image jo share hoti hai. Saare sizes card ki width
/// ke hisaab se scale hote hain, isliye image hamesha same dikhti hai.
class QuoteCard extends StatelessWidget {
  const QuoteCard({
    super.key,
    required this.quote,
    required this.style,
    required this.heading,
    this.showWatermark = true,
  });

  final Quote quote;
  final CardStyle style;
  final String heading;
  final bool showWatermark;

  double _baseFontSize(String text) {
    final n = text.length;
    if (n <= 50) return 28;
    if (n <= 90) return 24;
    if (n <= 140) return 21;
    if (n <= 200) return 18;
    return 16;
  }

  @override
  Widget build(BuildContext context) {
    // Phone ki font-size setting card ko na bigaade.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = constraints.maxWidth / 360;
            final color = style.textColor;
            return DecoratedBox(
              decoration: BoxDecoration(gradient: style.gradient),
              child: Stack(
                children: [
                  if (style.stars)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StarsPainter(seed: quote.id.hashCode, color: color),
                      ),
                    ),
                  Positioned(
                    right: -18 * s,
                    top: -22 * s,
                    child: Opacity(
                      opacity: 0.28,
                      child: Text(style.emoji, style: TextStyle(fontSize: 110 * s)),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(28 * s, 30 * s, 28 * s, 34 * s),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          heading,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                            fontSize: 24 * s,
                            color: color,
                          ),
                        ),
                        SizedBox(height: 6 * s),
                        Container(
                          width: 44 * s,
                          height: 2 * s,
                          color: color.withValues(alpha: 0.6),
                        ),
                        SizedBox(height: 18 * s),
                        Text(
                          quote.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: _baseFontSize(quote.text) * s,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                        if (quote.author != null) ...[
                          SizedBox(height: 14 * s),
                          Text(
                            '– ${quote.author}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14 * s,
                              fontWeight: FontWeight.w600,
                              color: color.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showWatermark)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 10 * s,
                      child: Text(
                        kWatermark,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10 * s,
                          letterSpacing: 0.5,
                          color: color.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter({required this.seed, required this.color});

  final int seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final paint = Paint();
    for (var i = 0; i < 45; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = (rnd.nextDouble() * 1.6 + 0.4) * size.width / 360;
      paint.color = color.withValues(alpha: 0.25 + rnd.nextDouble() * 0.5);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) =>
      old.seed != seed || old.color != color;
}
