import 'package:flutter/material.dart';

class AppColors {
  static const petalRouge = Color(0xFFE27396);
  static const pinkMist = Color(0xFFEB9AB2);
  static const petalFrost = Color(0xFFEFCFE3);
  static const beige = Color(0xFFECF2D8);
  static const lightBlue = Color(0xFFB3DEE2);
  static const darkText = Color(0xFF333333);
  static const greyText = Color(0xFF666666);
  static const white = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.beige,
    fontFamily: 'Arial',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.petalRouge,
      primary: AppColors.petalRouge,
      secondary: AppColors.lightBlue,
      background: AppColors.beige,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.beige,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      centerTitle: true,
    ),
  );
}