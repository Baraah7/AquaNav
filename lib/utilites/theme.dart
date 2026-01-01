import 'package:flutter/material.dart';

class AppColors {
  static const Color pearl = Color(0xFFF6F2EF);
  static const Color harbor = Color(0xFFB0C0CC);
  static const Color midnight = Color(0xFF363E4F);
  static const Color santorini = Color(0xFFD9DFE3);
  static const Color seaGreen = Color(0xFF8EA39D);

  //Semantic Colors
  static const Color success = Color.fromARGB(255, 70, 154, 126);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color.fromARGB(255, 28, 88, 138);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.harbor,
      secondary: AppColors.seaGreen,
      surface: AppColors.santorini,
      background: AppColors.pearl,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.midnight,
      onBackground: AppColors.midnight,
      error: AppColors.error,
    ),

    scaffoldBackgroundColor: AppColors.pearl,

    // App Bar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.midnight,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.pearl,
      selectedItemColor: AppColors.harbor,
      unselectedItemColor: AppColors.midnight,
      elevation: 8,
    ),

    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.seaGreen,
      foregroundColor: Colors.white,
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.santorini,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.harbor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.harbor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.seaGreen, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.error),
      ),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.harbor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.midnight,
        side: const BorderSide(color: AppColors.harbor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.seaGreen,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: AppColors.santorini,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(8),
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.midnight,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.midnight,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.midnight,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.midnight,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.midnight,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.harbor,
      ),
    ),
  );
}

// Quick access text styles
class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.midnight,
  );

  static const heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.midnight,
  );

  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.midnight,
  );

  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.harbor,
  );
}
