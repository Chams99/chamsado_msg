import 'package:flutter/material.dart';

class AppTheme {
  // Color palette from the image
  static const Color peach = Color(0xFFFF8A65);
  static const Color cream = Color(0xFFFDE5CE);
  static const Color green = Color(0xFF5E7F5E);
  static const Color darkGray = Color(0xFF393B32);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: peach,
      onPrimary: cream,
      secondary: green,
      onSecondary: cream,
      background: cream,
      onBackground: darkGray,
      surface: cream,
      onSurface: darkGray,
      error: Colors.red,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkGray,
      foregroundColor: cream,
      elevation: 2,
      iconTheme: IconThemeData(color: peach),
      titleTextStyle: TextStyle(
        color: cream,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: peach,
      foregroundColor: cream,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: peach,
        foregroundColor: cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        elevation: 2,
      ),
    ),
    cardColor: green,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkGray),
      bodyMedium: TextStyle(color: darkGray),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: green),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: peach),
      ),
      labelStyle: const TextStyle(color: darkGray),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFB26A50), // Muted peach
      onPrimary: darkGray,
      secondary: Color(0xFF3C5740), // Deep green
      onSecondary: cream,
      background: darkGray,
      onBackground: cream,
      surface: Color(0xFF23241F), // Even darker gray
      onSurface: cream,
      error: Colors.red[300]!,
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: darkGray,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF23241F),
      foregroundColor: cream,
      elevation: 2,
      iconTheme: IconThemeData(color: Color(0xFFB26A50)),
      titleTextStyle: TextStyle(
        color: cream,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFB26A50),
      foregroundColor: cream,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFB26A50),
        foregroundColor: cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        elevation: 2,
      ),
    ),
    cardColor: Color(0xFF3C5740),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: cream),
      bodyMedium: TextStyle(color: cream),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF23241F),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF3C5740)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFB26A50)),
      ),
      labelStyle: const TextStyle(color: cream),
    ),
  );
}
