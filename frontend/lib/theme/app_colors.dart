import 'package:flutter/material.dart';

/// Palette centralisée — dashboard admin SaaS industriel (dark vert / noir).
abstract final class AppColors {
  static const Color background = Color(0xFF050A08);
  static const Color surface = Color(0xFF0C1812);
  static const Color surfaceElevated = Color(0xFF122920);
  static const Color surfaceHighlight = Color(0xFF163828);
  static const Color border = Color(0xFF1F4D3A);
  static const Color borderMuted = Color(0xFF143522);

  static const Color accent = Color(0xFF76FF03);
  static const Color accentMuted = Color(0xFF4CAF50);
  static const Color accentDim = Color(0xFF2E7D32);

  /// Noms sémantiques pour verts (réutilisés par les alias legacy ci‑dessous).
  static const Color primary = accentMuted;
  static const Color primaryLight = accent;

  static const Color textPrimary = Color(0xFFE8F5E9);
  static const Color textSecondary = Color(0xFFB6D7CB);
  static const Color textMuted = Color(0xFF6B8F7E);

  static const Color chartIt = Color(0xFFA78BFA);
  static const Color chartElectricite = Color(0xFF22C55E);
  static const Color chartMecanique = Color(0xFFFBBF24);
  static const Color chartEau = Color(0xFF38BDF8);

  static const Color statBlue = Color(0xFF42A5F5);
  static const Color statGreen = Color(0xFF66BB6A);
  static const Color statOrange = Color(0xFFFFA726);
  static const Color statRed = Color(0xFFEF5350);
  static const Color statPurple = Color(0xFFAB47BC);

  static const Color barGradientStart = Color(0xFF1B5E20);
  static const Color barGradientEnd = Color(0xFF76FF03);

  static const Color sparklineLine = Color(0xFF69F0AE);
  static const Color sparklineFill = Color(0x331B5E20);

  static const Color urgentBanner = Color(0xFF1A0A0A);
  static const Color urgentBorder = Color(0x66EF5350);

  // ---------------------------------------------------------------------------
  // Compatibilité anciens écrans (Welcome, Login, fonds industriels, etc.)
  // ---------------------------------------------------------------------------
  static const Color white = Colors.white;
  static const Color gray = Color(0xFF9CA3AF);

  static const Color primaryGreen = primary;
  static const Color accentGreen = primaryLight;

  static const Color darkGreen = background;
  static const Color gradientTop = surface;

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.45),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: accent.withValues(alpha: 0.06),
      blurRadius: 40,
      offset: const Offset(0, 0),
    ),
  ];
}
