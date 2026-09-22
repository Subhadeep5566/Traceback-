import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TRACEBACK DESIGN SYSTEM
// Single source of truth for every color, spacing, radius, and typography
// value in the app. Import this file everywhere; never hardcode colors.
// ─────────────────────────────────────────────────────────────────────────────

class Tb {
  Tb._();

  // ── Colors ─────────────────────────────────────────────────────────────────

  /// True background (near-black)
  static const Color bg = Color(0xFF0A0A0B);

  /// Primary surface (dark charcoal)
  static const Color surface = Color(0xFF111114);

  /// Elevated surface (cards, dialogs)
  static const Color surface2 = Color(0xFF1A1A1F);

  /// Highest surface (selected states, tooltips)
  static const Color surface3 = Color(0xFF222228);

  /// Subtle 1px border
  static const Color border = Color(0x14FFFFFF); // ~8% white

  /// Stronger border (focused fields, dividers)
  static const Color borderStrong = Color(0x26FFFFFF); // ~15% white

  /// Traceback accent — orange-red
  static const Color accent = Color(0xFFFF4500);

  /// Accent dimmed background tint
  static const Color accentDim = Color(0x1AFF4500); // ~10% accent

  /// Primary text — white
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text — 60% white
  static const Color textSecondary = Color(0x99FFFFFF);

  /// Muted / placeholder text — 35% white
  static const Color textMuted = Color(0x59FFFFFF);

  /// Disabled text — 20% white
  static const Color textDisabled = Color(0x33FFFFFF);

  /// Success green
  static const Color success = Color(0xFF22C55E);

  /// Success dim background
  static const Color successDim = Color(0x1A22C55E);

  /// Warning amber
  static const Color warning = Color(0xFFF59E0B);

  /// Warning dim background
  static const Color warningDim = Color(0x1AF59E0B);

  /// Error / lost red
  static const Color error = Color(0xFFEF4444);

  /// Error dim background
  static const Color errorDim = Color(0x1AEF4444);

  /// Recovery blue
  static const Color recovery = Color(0xFF3B82F6);

  /// Recovery dim background
  static const Color recoveryDim = Color(0x1A3B82F6);

  // ── Spacing ─────────────────────────────────────────────────────────────────
  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s28 = 28.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;

  // ── Radius ──────────────────────────────────────────────────────────────────
  static const double r6 = 6.0;
  static const double r8 = 8.0;
  static const double r10 = 10.0;
  static const double r12 = 12.0;
  static const double r14 = 14.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double r999 = 999.0;

  // ── Typography ──────────────────────────────────────────────────────────────

  /// Display — hero numbers and names
  static const TextStyle display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    letterSpacing: -1.2,
    height: 1.1,
  );

  /// Headline — section titles, screen names
  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    letterSpacing: -0.6,
    height: 1.2,
  );

  /// Title — card headers
  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  /// Body — regular content
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.5,
  );

  /// Body small
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.4,
  );

  /// Label — ALL CAPS metadata labels
  static const TextStyle label = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: textMuted,
    letterSpacing: 1.2,
    height: 1.2,
  );

  /// Caption — timestamps, secondary metadata
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textMuted,
    height: 1.3,
  );

  // ── Status helpers ──────────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lost':
      case 'stolen':
        return error;
      case 'found':
        return warning;
      case 'recovered':
        return recovery;
      case 'safe':
      case 'secure':
        return success;
      default:
        return textMuted;
    }
  }

  static Color statusDim(String status) {
    switch (status.toLowerCase()) {
      case 'lost':
      case 'stolen':
        return errorDim;
      case 'found':
        return warningDim;
      case 'recovered':
        return recoveryDim;
      case 'safe':
      case 'secure':
        return successDim;
      default:
        return surface2;
    }
  }

  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'stolen':
        return 'LOST';
      case 'safe':
        return 'SAFE';
      case 'found':
        return 'FOUND';
      case 'recovered':
        return 'RECOVERED';
      default:
        return status.toUpperCase();
    }
  }

  // ── Flutter ThemeData ────────────────────────────────────────────────────────
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary, size: 20),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: bg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: display,
        headlineMedium: headline,
        titleLarge: title,
        bodyLarge: body,
        bodyMedium: bodySmall,
        labelSmall: label,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r12),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: s16, vertical: s14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderStrong),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r20)),
        titleTextStyle: title.copyWith(color: textPrimary),
        contentTextStyle: bodySmall.copyWith(color: textSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(r24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface3,
        contentTextStyle: body.copyWith(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(r16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        selectedColor: accentDim,
        side: const BorderSide(color: border),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r999)),
        padding: const EdgeInsets.symmetric(horizontal: s8, vertical: s4),
      ),
      iconTheme: const IconThemeData(color: textSecondary, size: 20),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SystemUI helper — call once in main()
// ─────────────────────────────────────────────────────────────────────────────
void applyTracebackSystemUI() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Tb.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
}
