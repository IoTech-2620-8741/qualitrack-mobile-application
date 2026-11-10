import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Material 3 theme for QualiTrack Mobile.
abstract final class AppTheme {
  static const Size _minTouch = Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget);

  /// M3 buttons are 40dp tall; `MaterialTapTargetSize.padded` grows the touch
  /// area to 48×48dp around them.
  static const Size _buttonSize = Size(64, 40);

  /// M3 Expressive shape morph for buttons: a full pill at rest that squares
  /// off (8dp corners) while pressed. `Material` animates between both shapes.
  static final WidgetStateProperty<OutlinedBorder> buttonShape = WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.pressed)
        ? const RoundedRectangleBorder(borderRadius: AppRadius.mdAll)
        : const StadiumBorder(),
  );

  /// Icon buttons: circular; a selected toggle icon button becomes a rounded
  /// square (12dp) and pressing squares it a bit more.
  static final WidgetStateProperty<OutlinedBorder> iconButtonShape = WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.pressed)) return const RoundedRectangleBorder(borderRadius: AppRadius.mdAll);
    if (states.contains(WidgetState.selected)) return const RoundedRectangleBorder(borderRadius: AppRadius.lgAll);
    return const CircleBorder();
  });

  static const TextStyle _buttonLabel = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.xl);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.navy,
      error: AppColors.critical,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textMuted,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        // Title (and subtitle) aligned to the start, next to the back arrow.
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        // Mobile cards: rounded white surfaces on the gray background, no border.
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
        ),
      ),
      // (1) Buttons: pill at rest, squared while pressed (see buttonShape).
      // FilledButton is the main action; FilledButton.tonal a secondary one on
      // the brand container; OutlinedButton a neutral secondary; TextButton
      // the lowest emphasis (links, "View all").
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          overlayColor: AppColors.primaryHover,
          minimumSize: _buttonSize,
          padding: _buttonPadding,
          textStyle: _buttonLabel,
        ).copyWith(shape: buttonShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          minimumSize: _buttonSize,
          padding: _buttonPadding,
          textStyle: _buttonLabel,
          side: const BorderSide(color: AppColors.border),
        ).copyWith(shape: buttonShape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          minimumSize: _buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          textStyle: _buttonLabel,
        ).copyWith(shape: buttonShape),
      ),
      // (3)/(4) Icon buttons: 48dp, circular; selected toggles get the tonal
      // brand container and a rounded-square shape.
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: _minTouch).copyWith(
          shape: iconButtonShape,
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppColors.primaryContainer : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.textMuted.withValues(alpha: 0.38);
            return states.contains(WidgetState.selected) ? AppColors.primaryDark : null;
          }),
        ),
      ),
      // (8)/(9) FAB and extended FAB: rounded square (16dp), brand filled.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        splashColor: AppColors.primaryHover,
        elevation: 3,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        extendedTextStyle: _buttonLabel,
        extendedPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg + AppSpacing.xs),
      ),
      // (7) Connected button group: segments joined in one pill; the selected
      // one is brand filled with no check mark.
      // Use it with `showSelectedIcon: false`.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(_buttonSize),
          textStyle: const WidgetStatePropertyAll(_buttonLabel),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppColors.primaryDark : AppColors.neutralContainer,
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.textMuted;
            return states.contains(WidgetState.selected) ? Colors.white : AppColors.textPrimary;
          }),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        side: const BorderSide(color: AppColors.border),
        selectedColor: AppColors.primaryContainer,
      ),
      // M3 bottom navigation: outlined icons when idle; the active item sits in
      // a tinted tonal container with the dark primary icon and a bold label,
      // so the selection never depends on the pale container alone.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: Colors.black26,
        height: 72,
        indicatorColor: AppColors.primaryContainer,
        indicatorShape: const StadiumBorder(side: BorderSide(color: Color(0x330F766E))),
        overlayColor: WidgetStateProperty.all(const Color(0x140F766E)),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? AppColors.primaryDark : AppColors.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primaryDark : AppColors.textMuted,
          );
        }),
      ),
      // Tabs. Primary tabs (`TabBar`) go right under the app bar for the main
      // views of a screen, with icon + label and a short rounded indicator
      // under the content. Secondary tabs (`TabBar.secondary`) switch
      // sub-sections inside the content, text only, full-width underline.
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primaryDark,
        dividerColor: AppColors.border,
        dividerHeight: 1,
        labelStyle: _buttonLabel.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: _buttonLabel,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return const Color(0x1F0F766E);
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return const Color(0x0A0F766E);
          }
          return null;
        }),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
