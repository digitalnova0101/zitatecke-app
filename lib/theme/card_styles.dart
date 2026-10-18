import 'package:flutter/material.dart';

/// Ek background design for quote card.
class CardStyle {
  const CardStyle({
    required this.id,
    required this.colors,
    required this.textColor,
    required this.emoji,
    this.stars = false,
  });

  final String id;
  final List<Color> colors;
  final Color textColor;
  final String emoji;
  final bool stars;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      );
}

const List<CardStyle> kCardStyles = [
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

CardStyle styleById(String id) =>
    kCardStyles.firstWhere((s) => s.id == id, orElse: () => kCardStyles.first);
