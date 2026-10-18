import 'dart:io';

import 'package:flutter/material.dart';

/// Ek background design for quote card.
class CardStyle {
  const CardStyle({
    required this.id,
    required this.colors,
    required this.textColor,
    required this.emoji,
    this.stars = false,
    this.image,
    this.file,
    this.dim = 0.0,
    this.tags = const [],
  });

  final String id;
  final List<Color> colors;
  final Color textColor;
  final String emoji;
  final bool stars;

  /// Photo background (assets/backgrounds/...). Null = sirf gradient.
  final String? image;

  /// Online se download hui photo (phone ki file).
  final String? file;

  /// Photo kitni dark ho (text padhne ke liye). 0.0 – 0.3
  final double dim;

  /// Photo ke mood tags ("kaffee", "regen" …) – quote se match karne ke liye.
  final List<String> tags;

  bool get hasPhoto => image != null || file != null;

  ImageProvider? get imageProvider {
    if (file != null) return FileImage(File(file!));
    if (image != null) return AssetImage(image!);
    return null;
  }

  /// Chhoti thumbnail ke liye (kam memory).
  ImageProvider? thumbProvider(int width) {
    final p = imageProvider;
    return p == null ? null : ResizeImage(p, width: width);
  }

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      );
}

const List<CardStyle> kCardStyles = [
  // --- Fotos (CC0 / Public Domain) ---
  CardStyle(id: 'p_morgenwiese', image: 'assets/backgrounds/morgenwiese.jpg', tags: ['sonnenaufgang', 'natur', 'fruehling'], dim: 0.05, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🌅'),
  CardStyle(id: 'p_sonnenblumen', image: 'assets/backgrounds/sonnenblumen.jpg', tags: ['blumen', 'sommer', 'sonnenaufgang'], dim: 0.08, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🌻'),
  CardStyle(id: 'p_seegold', image: 'assets/backgrounds/seegold.jpg', tags: ['sonnenaufgang', 'meer', 'himmel'], dim: 0.0, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🌄'),
  CardStyle(id: 'p_tau', image: 'assets/backgrounds/tau.jpg', tags: ['natur', 'fruehling'], dim: 0.08, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🌿'),
  CardStyle(id: 'p_sternenhimmel', image: 'assets/backgrounds/sternenhimmel.jpg', tags: ['nacht', 'sterne'], dim: 0.0, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '✨'),
  CardStyle(id: 'p_mondpalmen', image: 'assets/backgrounds/mondpalmen.jpg', tags: ['nacht', 'mond'], dim: 0.0, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🌙'),
  CardStyle(id: 'p_bergsee', image: 'assets/backgrounds/bergsee.jpg', tags: ['berge', 'natur'], dim: 0.05, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '⛰️'),
  CardStyle(id: 'p_ozean', image: 'assets/backgrounds/ozean.jpg', tags: ['meer', 'himmel'], dim: 0.05, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🌊'),
  CardStyle(id: 'p_bergrosa', image: 'assets/backgrounds/bergrosa.jpg', tags: ['berge', 'himmel', 'sonnenaufgang'], dim: 0.05, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🏔️'),
  CardStyle(id: 'p_horizont', image: 'assets/backgrounds/horizont.jpg', tags: ['himmel', 'meer'], dim: 0.18, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '☁️'),
  CardStyle(id: 'p_rose', image: 'assets/backgrounds/rose.jpg', tags: ['rosen', 'herz', 'blumen'], dim: 0.08, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🌹'),
  CardStyle(id: 'p_lavendel', image: 'assets/backgrounds/lavendel.jpg', tags: ['blumen', 'sommer'], dim: 0.08, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '💜'),
  CardStyle(id: 'p_lavendel2', image: 'assets/backgrounds/lavendel2.jpg', tags: ['blumen', 'natur'], dim: 0.08, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🪻'),
  CardStyle(id: 'p_tulpen', image: 'assets/backgrounds/tulpen.jpg', tags: ['blumen', 'fruehling', 'herz'], dim: 0.25, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🌷'),
  CardStyle(id: 'p_wunderkerze', image: 'assets/backgrounds/wunderkerze.jpg', tags: ['feier', 'nacht'], dim: 0.0, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🎇'),
  CardStyle(id: 'p_bokeh', image: 'assets/backgrounds/bokeh.jpg', tags: ['feier', 'kerzen', 'winter'], dim: 0.05, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '✨'),
  CardStyle(id: 'p_schneewald', image: 'assets/backgrounds/schneewald.jpg', tags: ['schnee', 'winter'], dim: 0.15, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '❄️'),
  CardStyle(id: 'p_huette', image: 'assets/backgrounds/huette.jpg', tags: ['winter', 'schnee'], dim: 0.12, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🏡'),
  CardStyle(id: 'p_bluete', image: 'assets/backgrounds/bluete.jpg', tags: ['fruehling', 'blumen'], dim: 0.2, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🌸'),
  CardStyle(id: 'p_bluete2', image: 'assets/backgrounds/bluete2.jpg', tags: ['fruehling', 'blumen'], dim: 0.2, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🌸'),
  CardStyle(id: 'p_strand', image: 'assets/backgrounds/strand.jpg', tags: ['meer', 'sommer'], dim: 0.1, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🏖️'),
  CardStyle(id: 'p_sonnenuntergang', image: 'assets/backgrounds/sonnenuntergang.jpg', tags: ['himmel', 'meer'], dim: 0.0, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🌇'),
  CardStyle(id: 'p_kueste', image: 'assets/backgrounds/kueste.jpg', tags: ['meer', 'natur', 'herbst'], dim: 0.08, colors: [Color(0xFF3B2A35), Color(0xFF6B4A5A)], textColor: Colors.white, emoji: '🌳'),
  // --- Farbverläufe ---
  CardStyle(id: 'sonnenaufgang', colors: [Color(0xFFFFC371), Color(0xFFFF5F6D)], textColor: Colors.white, emoji: '☀️'),
  CardStyle(id: 'pfirsich', colors: [Color(0xFFFFE5D0), Color(0xFFFFB199)], textColor: Color(0xFF4A2C2A), emoji: '🌼'),
  CardStyle(id: 'morgenrot', colors: [Color(0xFFFBD786), Color(0xFFF7797D)], textColor: Color(0xFF4A2330), emoji: '☕'),
  CardStyle(id: 'zitrone', colors: [Color(0xFFFFF6B7), Color(0xFFF6D365)], textColor: Color(0xFF4A3B10), emoji: '🌻'),
  CardStyle(id: 'nachthimmel', colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], textColor: Colors.white, emoji: '🌙', stars: true),
  CardStyle(id: 'mitternacht', colors: [Color(0xFF141E30), Color(0xFF243B55)], textColor: Colors.white, emoji: '✨', stars: true),
  CardStyle(id: 'lavendelnacht', colors: [Color(0xFF2E1A47), Color(0xFF5B3A8C)], textColor: Colors.white, emoji: '🌙', stars: true),
  CardStyle(id: 'meer', colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)], textColor: Colors.white, emoji: '🌊'),
  CardStyle(id: 'wald', colors: [Color(0xFF134E5E), Color(0xFF71B280)], textColor: Colors.white, emoji: '🌿'),
  CardStyle(id: 'energie', colors: [Color(0xFFF12711), Color(0xFFF5AF19)], textColor: Colors.white, emoji: '⚡'),
  CardStyle(id: 'lavendel', colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)], textColor: Color(0xFF2D2350), emoji: '💜'),
  CardStyle(id: 'sommer', colors: [Color(0xFF43CEA2), Color(0xFF185A9D)], textColor: Colors.white, emoji: '🌴'),
  CardStyle(id: 'rose', colors: [Color(0xFFFFDDE1), Color(0xFFEE9CA7)], textColor: Color(0xFF4A1F2B), emoji: '🌸'),
  CardStyle(id: 'konfetti', colors: [Color(0xFFDA22FF), Color(0xFF9733EE)], textColor: Colors.white, emoji: '🎉'),
  CardStyle(id: 'weihnacht', colors: [Color(0xFF8E0E00), Color(0xFF1F1C18)], textColor: Colors.white, emoji: '🎄', stars: true),
  CardStyle(id: 'winter', colors: [Color(0xFFE6F0FA), Color(0xFFB6CEE8)], textColor: Color(0xFF1E3550), emoji: '❄️'),
  CardStyle(id: 'fruehling', colors: [Color(0xFFD4FC79), Color(0xFF96E6A1)], textColor: Color(0xFF1F3D1A), emoji: '🐣'),
];

/// Online photos ke styles (PhotoLibrary bharti hai).
final Map<String, CardStyle> dynamicStyles = {};

CardStyle styleById(String id) =>
    dynamicStyles[id] ??
    kCardStyles.firstWhere((s) => s.id == id, orElse: () => kCardStyles.first);

/// Design picker: pehle nayi online photos (max 30), phir app ki photos aur rang.
List<CardStyle> pickerStyles() => [...dynamicStyles.values.take(30), ...kCardStyles];
