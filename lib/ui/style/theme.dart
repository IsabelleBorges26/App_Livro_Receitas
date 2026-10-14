
import 'package:flutter/material.dart';
import 'colors.dart';

abstract class AppTheme {
  static ThemeData temaClaro = ThemeData.light().copyWith(
    scaffoldBackgroundColor: AppColors.c5,
    primaryColor: AppColors.c1,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.c1,
      primary: AppColors.c1,
      secondary: AppColors.c3,
      surface: AppColors.c5,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.c1,
      foregroundColor: AppColors.c5,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.c5,
        fontSize: 23,
        fontWeight: FontWeight.bold,
        fontFamily: 'PatrickHand',
      ),
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: AppColors.c1,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        fontFamily: 'PatrickHand',
      ),
      titleLarge: TextStyle(
        color: AppColors.c1,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: 'PatrickHand',
      ),
      bodyLarge: TextStyle(
        color: AppColors.c1,
        fontSize: 18,
        fontFamily: 'PatrickHand',
      ),
      bodyMedium: TextStyle(
        color: AppColors.c1,
        fontSize: 16,
        fontFamily: 'PatrickHand',
      ),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.c1,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.c1,
      foregroundColor: AppColors.c5,
    ),
  );

  static ThemeData temaEscuro = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF292019),
    primaryColor: AppColors.c4,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF292019),
      foregroundColor: AppColors.c5,
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.c4,
      secondary: AppColors.c3,
      surface: Color(0xFF382D24),
    ),
  );
}
