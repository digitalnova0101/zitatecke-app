import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config.dart';
import '../models/quote.dart';
import '../theme/app_theme.dart';
import '../theme/card_fonts.dart';
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
    this.font,
    this.thumbnail = false,
  });

  final Quote quote;
  final CardStyle style;
  final String heading;
  final bool showWatermark;

  /// Spruch ka font (user chunta hai). Null = Lora.
  final CardFont? font;

  /// Grid ke chhote cards: kam memory wali photo.
  final bool thumbnail;

  double _baseFontSize(String text) {
    final n = text.length;
    if (n <= 50) return 27;
    if (n <= 90) return 23;
    if (n <= 140) return 20;
    if (n <= 200) return 17.5;
    return 16;
  }

  @override
  Widget build(BuildContext context) {
    final isPhoto = style.hasPhoto;
    final f = font ?? kCardFonts.first;
    // Phone ki font-size setting card ko na bigaade.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = constraints.maxWidth / 360;
            final color = style.textColor;
            final shadows = isPhoto
                ? [Shadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 10 * s, offset: Offset(0, 1.5 * s))]
                : null;
            return DecoratedBox(
              decoration: BoxDecoration(gradient: style.gradient),
              child: Stack(
                children: [
                  if (isPhoto) ...[
                    Positioned.fill(
                      child: Image(image: thumbnail ? style.thumbProvider(420)! : style.imageProvider!, fit: BoxFit.cover, gaplessPlayback: true),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.18 + style.dim * 0.5),
                              Colors.black.withValues(alpha: 0.30 + style.dim),
                              Colors.black.withValues(alpha: 0.22 + style.dim * 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (style.stars)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StarsPainter(seed: quote.id.hashCode, color: color),
                      ),
                    ),
                  if (!isPhoto)
                    Positioned(
                      right: -18 * s,
                      top: -22 * s,
                      child: Opacity(
                        opacity: 0.28,
                        child: Text(style.emoji, style: TextStyle(fontSize: 110 * s)),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(28 * s, 28 * s, 28 * s, 34 * s),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          heading,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: kFontScript,
                            fontWeight: FontWeight.w700,
                            fontSize: 34 * s,
                            height: 1.1,
                            color: color,
                            shadows: shadows,
                          ),
                        ),
                        SizedBox(height: 8 * s),
                        _Ornament(color: color, scale: s),
                        SizedBox(height: 16 * s),
                        // Lamba text + bada font → apne aap chhota ho jata hai (kabhi bahar nahi jata).
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: constraints.maxWidth - 56 * s,
                              child: Text(
                                quote.text,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: f.family,
                                  fontSize: _baseFontSize(quote.text) * f.scale * s,
                                  height: f.height,
                                  fontWeight: f.weight,
                                  color: color,
                                  shadows: shadows,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (quote.author != null) ...[
                          SizedBox(height: 14 * s),
                          Text(
                            '– ${quote.author}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: kFontQuote,
                              fontStyle: FontStyle.italic,
                              fontSize: 14 * s,
                              fontWeight: FontWeight.w500,
                              color: color.withValues(alpha: 0.9),
                              shadows: shadows,
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
                      bottom: 11 * s,
                      child: Text(
                        kWatermark,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: kFontUi,
                          fontWeight: FontWeight.w700,
                          fontSize: 10 * s,
                          letterSpacing: 1.2,
                          color: color.withValues(alpha: 0.75),
                          shadows: shadows,
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

/// Chhoti si sajawat: ── ✦ ──
class _Ornament extends StatelessWidget {
  const _Ornament({required this.color, required this.scale});
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final line = Container(width: 26 * scale, height: 1.4 * scale, color: color.withValues(alpha: 0.7));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line,
        SizedBox(width: 6 * scale),
        Text('✦', style: TextStyle(fontSize: 10 * scale, color: color.withValues(alpha: 0.85))),
        SizedBox(width: 6 * scale),
        line,
      ],
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
