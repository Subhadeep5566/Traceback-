import 'package:flutter/material.dart';

class PremiumColors {
  static const Color bgDark = Color(0xFF050810);
  static const Color bgSurface = Color(0xFF0C101C);
  static const Color bgElevated = Color(0xFF111725);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassWhiteStrong = Color(0x26FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBorderStrong = Color(0x4DFFFFFF);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentMagenta = Color(0xFFFF00AA);
  static const Color accentGold = Color(0xFFFFD600);
  static const Color accentEmerald = Color(0xFF00FF88);
  static const Color accentCoral = Color(0xFFFF4D6A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textMuted = Color(0x66FFFFFF);
  static const Color textDisabled = Color(0x33FFFFFF);
  static const Color success = Color(0xFF00FF88);
  static const Color warning = Color(0xFFFFD600);
  static const Color error = Color(0xFFFF4D6A);
  static const Color overlayDark = Color(0xCC000000);
}

class PremiumGradients {
  static const LinearGradient holographic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00E5FF),
      Color(0xFF7C4DFF),
      Color(0xFFFF00AA),
      Color(0xFF00FF88),
    ],
    stops: [0.0, 0.3, 0.6, 1.0],
  );

  static const LinearGradient glassSubtle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x26FFFFFF),
      Color(0x14FFFFFF),
      Color(0x0AFFFFFF),
      Color(0x00FFFFFF),
    ],
  );

  static const LinearGradient bgAmbient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF050810),
      Color(0xFF0A1220),
      Color(0xFF0C101C),
      Color(0xFF050810),
    ],
  );

  static const LinearGradient accentCyanGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x4D00E5FF),
      Color(0x1A00E5FF),
      Color(0x0000E5FF),
    ],
  );

  static const LinearGradient accentMagentaGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x4DFF00AA),
      Color(0x1AFF00AA),
      Color(0x00FF00AA),
    ],
  );

  static const LinearGradient buttonPrimary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF00E5FF),
      Color(0xFF7C4DFF),
    ],
  );

  static const LinearGradient buttonDanger = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFF4D6A),
      Color(0xFFFF00AA),
    ],
  );

  static const LinearGradient buttonSuccess = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF00FF88),
      Color(0xFF00E5FF),
    ],
  );
}

class PremiumSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

class PremiumRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double round = 999.0;
}

class PremiumShadows {
  static List<BoxShadow> get glass => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: PremiumColors.accentCyan.withOpacity(0.05),
      blurRadius: 40,
      offset: const Offset(0, 0),
    ),
  ];

  static List<BoxShadow> get glassHover => [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: PremiumColors.accentCyan.withOpacity(0.1),
      blurRadius: 60,
      offset: const Offset(0, 0),
    ),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(
      color: PremiumColors.accentCyan.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get buttonPressed => [
    BoxShadow(
      color: PremiumColors.accentCyan.withOpacity(0.15),
      blurRadius: 8,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get glowCyan => [
    BoxShadow(
      color: PremiumColors.accentCyan.withOpacity(0.4),
      blurRadius: 30,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get glowMagenta => [
    BoxShadow(
      color: PremiumColors.accentMagenta.withOpacity(0.4),
      blurRadius: 30,
      spreadRadius: 2,
    ),
  ];
}

class PremiumDurations {
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 600);
  static const Duration ambient = Duration(milliseconds: 3000);
}

class PremiumCurves {
  static const Curve smooth = Curves.easeOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve sharp = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.decelerate;
}