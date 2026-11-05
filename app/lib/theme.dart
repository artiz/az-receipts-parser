/// The artiz.github.io look: Inter, near-black surfaces with a hot-pink
/// accent in the dark theme, cool grey with a deep pink in the light theme.
library;

import 'package:flutter/material.dart';

class AzColors {
  static const pink = Color(0xFFFF2E7E);
  static const pinkHover = Color(0xFFFF5797);
  static const pinkText = Color(0xFFFF6AA3);
  static const pinkDeep = Color(0xFFD6105E);
  static const pinkInk = Color(0xFFC00D55);
  static const pinkSoft = Color(0xFFF1B8CF);

  static const bgDark = Color(0xFF08080B);
  static const surfaceDark = Color(0xFF15151A);
  static const surface2Dark = Color(0xFF1C1C25);
  static const textDark = Color(0xFFF5F5F7);
  static const text2Dark = Color(0xFFCFCFD8);
  static const mutedDark = Color(0xFF8F8F9C);

  static const bgLight = Color(0xFFE8EAEE);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surface2Light = Color(0xFFF4F4F6);
  static const textLight = Color(0xFF15151A);
  static const text2Light = Color(0xFF3B3B40);
  static const mutedLight = Color(0xFF6F6F7A);

  static const green = Color(0xFF4E7A5A);
  static const greenBright = Color(0xFF6FCF97);
}

ThemeData azTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? AzColors.pink : AzColors.pinkDeep,
    onPrimary: Colors.white,
    primaryContainer: dark ? const Color(0xFF3A1226) : AzColors.pinkSoft,
    onPrimaryContainer: dark ? AzColors.pinkText : AzColors.pinkInk,
    secondary: dark ? AzColors.text2Dark : AzColors.text2Light,
    onSecondary: dark ? AzColors.bgDark : Colors.white,
    secondaryContainer: dark ? AzColors.surface2Dark : AzColors.surface2Light,
    onSecondaryContainer: dark ? AzColors.textDark : AzColors.textLight,
    tertiary: dark ? AzColors.greenBright : AzColors.green,
    onTertiary: Colors.white,
    error: dark ? const Color(0xFFFF6B6B) : const Color(0xFFB3261E),
    onError: Colors.white,
    surface: dark ? AzColors.surfaceDark : AzColors.surfaceLight,
    onSurface: dark ? AzColors.textDark : AzColors.textLight,
    onSurfaceVariant: dark ? AzColors.mutedDark : AzColors.mutedLight,
    surfaceContainerHighest: dark ? AzColors.surface2Dark : AzColors.surface2Light,
    surfaceContainerLow: dark ? const Color(0xFF101014) : const Color(0xFFF7F7F9),
    outline: dark ? const Color(0xFF2A2A33) : const Color(0xFFD6D9E0),
    outlineVariant: dark ? const Color(0xFF1F1F27) : const Color(0xFFE3E5EA),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: dark ? AzColors.textDark : AzColors.textLight,
    onInverseSurface: dark ? AzColors.bgDark : Colors.white,
    inversePrimary: dark ? AzColors.pinkDeep : AzColors.pink,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: 'Inter');
  return base.copyWith(
    scaffoldBackgroundColor: dark ? AzColors.bgDark : AzColors.bgLight,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? AzColors.bgDark : AzColors.bgLight,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.outline)),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surface,
      side: BorderSide(color: scheme.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: TextStyle(fontFamily: 'Inter', color: scheme.onSurface, fontWeight: FontWeight.w500),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.primary, width: 1.5)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
    dialogTheme: DialogThemeData(backgroundColor: scheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    textTheme: base.textTheme.apply(fontFamily: 'Inter', bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
  );
}
