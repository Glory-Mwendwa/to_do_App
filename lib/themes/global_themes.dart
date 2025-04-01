import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyAppTheme {
  static ThemeData lightTheme = ThemeData(
    fontFamily: "${GoogleFonts.montserrat}",
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 18, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 40, 202, 186),
      foregroundColor: Colors.white,
      elevation: 5,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade500,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    ),
    //checkboxTheme: const CheckboxThemeData(shape: CircleBorder())
  );
}
