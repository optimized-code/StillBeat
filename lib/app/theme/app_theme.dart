import 'package:flutter/material.dart';

/// Spacing scale (logical pixels).
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class Radii {
  static const double card = 20;
  static const double control = 14;
  static const double pill = 999;
}

/// Max content width for tablet/desktop so lines stay readable.
const double kMaxContentWidth = 720;

/// Semantic colours not covered by [ColorScheme].
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.good,
    required this.acceptable,
    required this.poor,
    required this.neutral,
    required this.onStatus,
  });

  final Color good;
  final Color acceptable;
  final Color poor;
  final Color neutral;

  /// Foreground used on top of the status colours (contrast-checked).
  final Color onStatus;

  static const light = StatusColors(
    good: Color(0xFF1E6B4E),
    acceptable: Color(0xFF8A5A00),
    poor: Color(0xFFA3312A),
    neutral: Color(0xFF5B6770),
    onStatus: Colors.white,
  );

  static const dark = StatusColors(
    good: Color(0xFF7FD6B0),
    acceptable: Color(0xFFF2C46B),
    poor: Color(0xFFFFA59E),
    neutral: Color(0xFFB5C0C8),
    onStatus: Color(0xFF10181D),
  );

  @override
  StatusColors copyWith({
    Color? good,
    Color? acceptable,
    Color? poor,
    Color? neutral,
    Color? onStatus,
  }) =>
      StatusColors(
        good: good ?? this.good,
        acceptable: acceptable ?? this.acceptable,
        poor: poor ?? this.poor,
        neutral: neutral ?? this.neutral,
        onStatus: onStatus ?? this.onStatus,
      );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      good: Color.lerp(good, other.good, t)!,
      acceptable: Color.lerp(acceptable, other.acceptable, t)!,
      poor: Color.lerp(poor, other.poor, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      onStatus: Color.lerp(onStatus, other.onStatus, t)!,
    );
  }
}

abstract final class AppTheme {
  static const Color _seed = Color(0xFF16707A);

  static ThemeData light() => _build(
        ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light)
            .copyWith(surface: const Color(0xFFF7F9F9)),
        StatusColors.light,
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark)
            .copyWith(surface: const Color(0xFF0F1517)),
        StatusColors.dark,
      );

  static ThemeData _build(ColorScheme scheme, StatusColors status) {
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
    final text = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [status],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
          textStyle: text.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: Space.lg),
      ),
    );
  }
}

extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  StatusColors get status => Theme.of(this).extension<StatusColors>()!;

  /// Honour the OS "reduce motion" setting.
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;
}
