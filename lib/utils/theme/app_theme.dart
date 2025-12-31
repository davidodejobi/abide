import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// App theme configuration
abstract final class AppTheme {
  // ============================================
  // LIGHT THEME
  // ============================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
      textTheme: _textTheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: _lightAppBarTheme,
      cardTheme: _lightCardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _lightInputDecorationTheme,
      dividerTheme: _lightDividerTheme,
      listTileTheme: _lightListTileTheme,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      bottomNavigationBarTheme: _lightBottomNavigationBarTheme,
      navigationBarTheme: _lightNavigationBarTheme,
      iconTheme: const IconThemeData(color: AppColors.primary),
      dialogTheme: _lightDialogTheme,
      snackBarTheme: _snackBarTheme,
    );
  }

  // ============================================
  // DARK THEME
  // ============================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme,
      textTheme: _textTheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: _darkAppBarTheme,
      cardTheme: _darkCardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _darkInputDecorationTheme,
      dividerTheme: _darkDividerTheme,
      listTileTheme: _darkListTileTheme,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      bottomNavigationBarTheme: _darkBottomNavigationBarTheme,
      navigationBarTheme: _darkNavigationBarTheme,
      iconTheme: const IconThemeData(color: AppColors.secondary),
      dialogTheme: _darkDialogTheme,
      snackBarTheme: _snackBarTheme,
    );
  }

  // ============================================
  // COLOR SCHEMES
  // ============================================

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.primary200,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.secondary100,
    onSecondaryContainer: AppColors.secondaryDark,
    tertiary: AppColors.primary400,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.primary300,
    onTertiaryContainer: AppColors.primaryDark,
    error: AppColors.error,
    onError: AppColors.white,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.neutral900,
    surfaceContainerHighest: AppColors.neutral200,
    onSurfaceVariant: AppColors.neutral500,
    outline: AppColors.neutral300,
    outlineVariant: AppColors.neutral200,
    shadow: AppColors.black,
    scrim: AppColors.black,
    inverseSurface: AppColors.neutral800,
    onInverseSurface: AppColors.neutral100,
    inversePrimary: AppColors.primary300,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary300,
    onPrimary: AppColors.primaryDark,
    primaryContainer: AppColors.primary,
    onPrimaryContainer: AppColors.primary200,
    secondary: AppColors.secondary,
    onSecondary: AppColors.secondaryDark,
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: AppColors.secondary100,
    tertiary: AppColors.primary400,
    onTertiary: AppColors.primaryDark,
    tertiaryContainer: AppColors.primaryLight,
    onTertiaryContainer: AppColors.primary200,
    error: AppColors.error,
    onError: AppColors.white,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.neutral100,
    surfaceContainerHighest: AppColors.neutral800,
    onSurfaceVariant: AppColors.neutral300,
    outline: AppColors.neutral500,
    outlineVariant: AppColors.neutral800,
    shadow: AppColors.black,
    scrim: AppColors.black,
    inverseSurface: AppColors.neutral100,
    onInverseSurface: AppColors.neutral800,
    inversePrimary: AppColors.primary,
  );

  // ============================================
  // TEXT THEME
  // ============================================

  static TextTheme get _textTheme => const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      );

  // ============================================
  // APP BAR THEMES
  // ============================================

  static const AppBarTheme _lightAppBarTheme = AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: true,
    backgroundColor: AppColors.surfaceLight,
    foregroundColor: AppColors.primary,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    iconTheme: IconThemeData(color: AppColors.primary),
    actionsIconTheme: IconThemeData(color: AppColors.primary),
    titleTextStyle: TextStyle(
      color: AppColors.primary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  );

  static const AppBarTheme _darkAppBarTheme = AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: true,
    backgroundColor: AppColors.surfaceDark,
    foregroundColor: AppColors.neutral100,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    iconTheme: IconThemeData(color: AppColors.secondary),
    actionsIconTheme: IconThemeData(color: AppColors.secondary),
    titleTextStyle: TextStyle(
      color: AppColors.neutral100,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  );

  // ============================================
  // CARD THEMES
  // ============================================

  static const CardThemeData _lightCardTheme = CardThemeData(
    elevation: 0,
    color: AppColors.surfaceLight,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      side: BorderSide(color: AppColors.neutral200, width: 1),
    ),
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );

  static const CardThemeData _darkCardTheme = CardThemeData(
    elevation: 0,
    color: AppColors.surfaceDark,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      side: BorderSide(color: AppColors.neutral800, width: 1),
    ),
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );

  // ============================================
  // BUTTON THEMES
  // ============================================

  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTextStyles.labelLarge,
      ),
    );
  }

  static OutlinedButtonThemeData get _outlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTextStyles.labelLarge,
      ),
    );
  }

  static TextButtonThemeData get _textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTextStyles.labelLarge,
      ),
    );
  }

  // ============================================
  // FLOATING ACTION BUTTON THEME
  // ============================================

  static const FloatingActionButtonThemeData _floatingActionButtonTheme =
      FloatingActionButtonThemeData(
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.white,
    elevation: 4,
    shape: CircleBorder(),
  );

  // ============================================
  // INPUT DECORATION THEMES
  // ============================================

  static InputDecorationTheme get _lightInputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      labelStyle:
          AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
    );
  }

  static InputDecorationTheme get _darkInputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.neutral500),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.neutral500),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary300, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      labelStyle:
          AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral300),
    );
  }

  // ============================================
  // DIVIDER THEMES
  // ============================================

  static const DividerThemeData _lightDividerTheme = DividerThemeData(
    color: AppColors.neutral200,
    thickness: 1,
    space: 1,
  );

  static const DividerThemeData _darkDividerTheme = DividerThemeData(
    color: AppColors.neutral800,
    thickness: 1,
    space: 1,
  );

  // ============================================
  // LIST TILE THEMES
  // ============================================

  static const ListTileThemeData _lightListTileTheme = ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    tileColor: Colors.transparent,
    selectedTileColor: AppColors.secondary50,
    iconColor: AppColors.primary,
    textColor: AppColors.neutral900,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  static const ListTileThemeData _darkListTileTheme = ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    tileColor: Colors.transparent,
    selectedTileColor: AppColors.primaryDark,
    iconColor: AppColors.secondary,
    textColor: AppColors.neutral100,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  // ============================================
  // BOTTOM NAVIGATION BAR THEMES
  // ============================================

  static const BottomNavigationBarThemeData _lightBottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    backgroundColor: AppColors.surfaceLight,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.neutral500,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  );

  static const BottomNavigationBarThemeData _darkBottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    backgroundColor: AppColors.surfaceDark,
    selectedItemColor: AppColors.secondary,
    unselectedItemColor: AppColors.neutral500,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  );

  // ============================================
  // NAVIGATION BAR THEMES (Material 3)
  // ============================================

  static NavigationBarThemeData get _lightNavigationBarTheme {
    return NavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      indicatorColor: AppColors.secondary100,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.labelMedium.copyWith(color: AppColors.primary);
        }
        return AppTextStyles.labelMedium.copyWith(color: AppColors.neutral500);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return const IconThemeData(color: AppColors.neutral500, size: 24);
      }),
    );
  }

  static NavigationBarThemeData get _darkNavigationBarTheme {
    return NavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      indicatorColor: AppColors.primaryDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.labelMedium.copyWith(color: AppColors.secondary);
        }
        return AppTextStyles.labelMedium.copyWith(color: AppColors.neutral500);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.secondary, size: 24);
        }
        return const IconThemeData(color: AppColors.neutral500, size: 24);
      }),
    );
  }

  // ============================================
  // DIALOG THEMES
  // ============================================

  static const DialogThemeData _lightDialogTheme = DialogThemeData(
    backgroundColor: AppColors.surfaceLight,
    surfaceTintColor: Colors.transparent,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  static const DialogThemeData _darkDialogTheme = DialogThemeData(
    backgroundColor: AppColors.surfaceDark,
    surfaceTintColor: Colors.transparent,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  // ============================================
  // SNACKBAR THEME
  // ============================================

  static const SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.neutral800,
    contentTextStyle: TextStyle(color: AppColors.white),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );
}
