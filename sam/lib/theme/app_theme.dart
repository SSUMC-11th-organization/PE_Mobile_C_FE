// 테마 및 간격 설정
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppSpacing {
  static const unit = 8.0;
  static const xs = unit / 2;
  static const sm = unit;
  static const md = unit * 2;
  static const lg = unit * 3;
  static const xl = unit * 4;
  static const xxl = unit * 6;
  static const radius = unit;

  static const mobileMargin = md;
  static const wideMargin = xl;
  static const wideBreakpoint = 600.0;

  static double screenMargin(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= wideBreakpoint ? wideMargin : mobileMargin;
  }
}

abstract final class AppTheme {
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: AppColors.violet,
    onPrimary: AppColors.white,
    surface: AppColors.warmWhite,
    onSurface: AppColors.black,
    secondary: AppColors.violet,
    onSecondary: AppColors.white,
    error: Color(0xFFB3261E),
    onError: AppColors.white,
    outline: AppColors.gray,
  );

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: AppColors.warmWhite,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.warmWhite,
      foregroundColor: AppColors.black,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.warmWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
    ),
  );
}
