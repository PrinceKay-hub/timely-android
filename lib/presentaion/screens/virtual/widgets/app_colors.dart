import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color text;
  final Color textSecondary;
  final Color card;
  final Color surface;
  final Color border;
  final Color primary; // "berry"
  final Color primaryLight;
  final Color secondary; // "gold"
  final Color secondaryLight;
  final Color shadow;

  const AppColors({
    required this.background,
    required this.text,
    required this.textSecondary,
    required this.card,
    required this.surface,
    required this.border,
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.secondaryLight,
    required this.shadow,
  });

  static const light = AppColors(
    background: Color(0xFFFBF7F2),
    text: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF6C757D),
    card: Color(0xFFFFFFFF),
    surface: Color(0xFFF3EFE9),
    border: Color(0xFFEFEAE3),
    primary: Color(0xFFA6295E),
    primaryLight: Color(0xFFF6E9EE),
    secondary: Color(0xFFB8860B),
    secondaryLight: Color(0xFFF7F0DE),
    shadow: Color(0xFF000000),
  );

  static const dark = AppColors(
    background: Color(0xFF15151F),
    text: Color(0xFFF5F3F0),
    textSecondary: Color(0xFFA0A4AB),
    card: Color(0xFF1E1E2C),
    surface: Color(0xFF23232F),
    border: Color(0xFF2E2E3A),
    primary: Color(0xFFD64C82),
    primaryLight: Color(0xFF3A2430),
    secondary: Color(0xFFE0AC3F),
    secondaryLight: Color(0xFF3A331F),
    shadow: Color(0xFF000000),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? text,
    Color? textSecondary,
    Color? card,
    Color? surface,
    Color? border,
    Color? primary,
    Color? primaryLight,
    Color? secondary,
    Color? secondaryLight,
    Color? shadow,
  }) {
    return AppColors(
      background: background ?? this.background,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      card: card ?? this.card,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      secondary: secondary ?? this.secondary,
      secondaryLight: secondaryLight ?? this.secondaryLight,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      card: Color.lerp(card, other.card, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryLight: Color.lerp(secondaryLight, other.secondaryLight, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

ThemeData buildLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.light.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.light.primary,
      brightness: Brightness.light,
    ),
    extensions: const [AppColors.light],
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.dark.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.dark.primary,
      brightness: Brightness.dark,
    ),
    extensions: const [AppColors.dark],
  );
}

extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}