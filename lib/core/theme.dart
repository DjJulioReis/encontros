import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Roboto',

    scaffoldBackgroundColor: AppColors.background,

    // 🔤 TEXTO
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.white),
    ),

    // 🧾 TEXTFIELD
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundSoft,

      labelStyle: const TextStyle(color: Colors.white70),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.5),
      ),
    ),

    // 📋 LIST TILE
    listTileTheme: const ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white70,
    ),

    // 🔽 DROPDOWN (ajuda mas não resolve tudo)
    dropdownMenuTheme: const DropdownMenuThemeData(
      textStyle: TextStyle(color: Colors.white),
    ),

    // 🧭 BOTTOM NAV
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.backgroundSoft,
      selectedItemColor: AppColors.primaryPink,
      unselectedItemColor: Colors.white54,
    ),
  );
}