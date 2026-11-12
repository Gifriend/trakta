import 'package:flutter/material.dart';
import '../../features/settings/presentations/preferences_state.dart';

const themeLabels = <AppTheme, String>{
  AppTheme.classic: 'Trakta',
  AppTheme.neo: 'Neobrutalism',
  AppTheme.glass: 'Glassmorphism',
  AppTheme.clay: 'Claymorphism',
  AppTheme.swiss: 'Swiss Minimalist',
  AppTheme.deco: 'Art Deco',
  AppTheme.studio: 'Studio Pop',
  AppTheme.lagoon: 'Lagoon',
  AppTheme.liquid: 'Liquid Glass',
};

class TraktaPalette extends ThemeExtension<TraktaPalette> {
  const TraktaPalette({
    required this.forest,
    required this.lime,
    required this.radius,
    required this.style,
  });
  final Color forest, lime;
  final double radius;
  final AppTheme style;
  @override
  TraktaPalette copyWith({
    Color? forest,
    Color? lime,
    double? radius,
    AppTheme? style,
  }) => TraktaPalette(
    forest: forest ?? this.forest,
    lime: lime ?? this.lime,
    radius: radius ?? this.radius,
    style: style ?? this.style,
  );
  @override
  TraktaPalette lerp(covariant TraktaPalette? other, double t) => other == null
      ? this
      : TraktaPalette(
          forest: Color.lerp(forest, other.forest, t)!,
          lime: Color.lerp(lime, other.lime, t)!,
          radius: radius + (other.radius - radius) * t,
          style: other.style,
        );
}

abstract final class TraktaTheme {
  // primary, background, surface, ink, muted, border, forest, lime; from web CSS.
  static const _light = [
    [
      0x176b54,
      0xf7f8fa,
      0xffffff,
      0x1f302a,
      0x65736c,
      0xe8ece9,
      0x124e43,
      0xd5ed9c,
    ],
    [
      0x2838bc,
      0xeef0ff,
      0xfffefa,
      0x1b2037,
      0x4d5673,
      0x1b2037,
      0x252d60,
      0xdcf768,
    ],
    [
      0x3445a6,
      0xe5ecff,
      0xf8faff,
      0x172342,
      0x44547c,
      0xbdc9e6,
      0x273766,
      0xc9dbff,
    ],
    [
      0x963b56,
      0xf6e9ec,
      0xfff8f5,
      0x352538,
      0x655065,
      0xe6c6cf,
      0x664059,
      0xffdfbd,
    ],
    [
      0xba281b,
      0xf6f6f3,
      0xffffff,
      0x171717,
      0x50504c,
      0xc6c6c0,
      0x202020,
      0xf4eee5,
    ],
    [
      0x75521f,
      0xefe8d8,
      0xfffbef,
      0x32281b,
      0x64523b,
      0xb89962,
      0x28231d,
      0xe8c67c,
    ],
    [
      0x96294c,
      0xfff0ed,
      0xfffaf8,
      0x37242e,
      0x71515e,
      0xebbdc7,
      0x682545,
      0xffdc9f,
    ],
    [
      0x13606a,
      0xe8f4f5,
      0xf8fefe,
      0x183437,
      0x476366,
      0xbedbdd,
      0x164952,
      0xa3eee1,
    ],
  ];
  static const _dark = [
    [
      0x87dab8,
      0x111d19,
      0x1b2b25,
      0xe8f2ed,
      0xa4b7ad,
      0x354a41,
      0x193d34,
      0xd5ed9c,
    ],
    [
      0xbbc4ff,
      0x181c31,
      0x232943,
      0xeef0ff,
      0xbac1da,
      0x677097,
      0x303866,
      0xdcf768,
    ],
    [
      0xb8c4ff,
      0x10162d,
      0x212b4b,
      0xedf1ff,
      0xb6c1e4,
      0x6375a0,
      0x293660,
      0xc9dbff,
    ],
    [
      0xffabc5,
      0x211925,
      0x352738,
      0xf5e9f3,
      0xcdb9cc,
      0x674d63,
      0x51334d,
      0xffdfbd,
    ],
    [
      0xff927e,
      0x141414,
      0x1e1e1e,
      0xf4f4f1,
      0xbcbcb6,
      0x51514e,
      0x272727,
      0xf4eee5,
    ],
    [
      0xe8c67c,
      0x161513,
      0x25211b,
      0xf6e9ce,
      0xc8b799,
      0x8a7046,
      0x2e281e,
      0xe8c67c,
    ],
    [
      0xffaec0,
      0x261822,
      0x362432,
      0xfff0f1,
      0xdfb6c3,
      0x684156,
      0x57263e,
      0xffdc9f,
    ],
    [
      0x93e0d5,
      0x112429,
      0x1b3339,
      0xe4f6f4,
      0xaac9c9,
      0x3e6067,
      0x193b43,
      0xa3eee1,
    ],
  ];
  static ThemeData build(AppTheme style, bool dark) {
    final index = style == AppTheme.liquid ? 0 : style.index;
    final c = (dark ? _dark : _light)[index]
        .map((hex) => Color(0xff000000 | hex))
        .toList();
    final radius = switch (style) {
      AppTheme.neo || AppTheme.deco => 3.0,
      AppTheme.swiss => 0.0,
      AppTheme.clay || AppTheme.studio || AppTheme.liquid => 24.0,
      AppTheme.glass => 19.0,
      _ => 12.0,
    };
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c[0],
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: c[0],
          onPrimary: dark ? c[1] : Colors.white,
          surface: c[2],
          onSurface: c[3],
          onSurfaceVariant: c[4],
          outline: c[5],
          outlineVariant: c[5],
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: c[1],
      fontFamily: 'Inter',
      visualDensity: VisualDensity.standard,
    );
    return base.copyWith(
      extensions: [
        TraktaPalette(forest: c[6], lime: c[7], radius: radius, style: style),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: c[1],
        foregroundColor: c[3],
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          color: c[3],
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -.6,
          color: c[3],
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: c[3],
        ),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: c[3]),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: c[3]),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c[2],
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.clamp(0, 16)),
          borderSide: BorderSide(color: c[5]),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.clamp(0, 16)),
          borderSide: BorderSide(color: c[5]),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.clamp(0, 28)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.clamp(0, 16)),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c[2],
        indicatorColor: c[0].withValues(alpha: .12),
      ),
    );
  }
}
