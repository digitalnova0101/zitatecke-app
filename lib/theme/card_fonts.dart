import 'package:flutter/material.dart';

/// Spruch-card ke liye fonts (sab SIL OFL, app ke andar).
class CardFont {
  const CardFont({
    required this.id,
    required this.label,
    required this.family,
    this.weight = FontWeight.w400,
    this.scale = 1.0,
    this.height = 1.4,
  });

  final String id;
  final String label;
  final String family;
  final FontWeight weight;

  /// Kuch fonts chhote dikhte hain – unhe thoda bada karo.
  final double scale;
  final double height;
}

const List<CardFont> kCardFonts = [
  CardFont(id: 'lora', label: 'Klassisch', family: 'Lora', weight: FontWeight.w500),
  CardFont(id: 'dancing', label: 'Handschrift', family: 'DancingScript', weight: FontWeight.w700, scale: 1.18, height: 1.25),
  CardFont(id: 'playfair', label: 'Elegant', family: 'PlayfairDisplay', weight: FontWeight.w500, scale: 1.02, height: 1.35),
  CardFont(id: 'greatvibes', label: 'Verspielt', family: 'GreatVibes', scale: 1.35, height: 1.2),
  CardFont(id: 'nunito', label: 'Modern', family: 'Nunito', weight: FontWeight.w700, scale: 0.98),
  CardFont(id: 'caveat', label: 'Locker', family: 'Caveat', weight: FontWeight.w600, scale: 1.3, height: 1.2),
  CardFont(id: 'pacifico', label: 'Fröhlich', family: 'Pacifico', scale: 0.9, height: 1.45),
  CardFont(id: 'merriweather', label: 'Zeitung', family: 'Merriweather', scale: 0.92, height: 1.5),
];

CardFont fontById(String? id) =>
    kCardFonts.firstWhere((f) => f.id == id, orElse: () => kCardFonts.first);
