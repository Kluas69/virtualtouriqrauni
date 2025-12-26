import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeData get theme => _isDark ? _darkTheme : _lightTheme;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

final ThemeData _lightTheme = ThemeData(
  scaffoldBackgroundColor: const Color.fromARGB(255, 220, 221, 222),
  secondaryHeaderColor: Colors.transparent,
  primaryColor: const Color(0xFF3F51B5),
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF3F51B5),
    secondary: const Color(0xFF26A69A),
    surface: const Color(0xFFFFFFFF),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.grey.shade400,
  ),
  cardColor: Colors.white,
  textTheme: TextTheme(
    bodyMedium: GoogleFonts.poppins(
      color: const Color(0xFF212121),
      fontWeight: FontWeight.w400,
      fontSize: 16.0,
    ),
    bodyLarge: GoogleFonts.poppins(
      color: const Color(0xFF212121),
      fontWeight: FontWeight.w600,
      fontSize: 18.0,
    ),
    headlineSmall: GoogleFonts.poppins(
      color: const Color(0xFF212121),
      fontWeight: FontWeight.bold,
      fontSize: 24.0,
    ),
    headlineMedium: GoogleFonts.poppins(
      color: const Color(0xFF212121),
      fontWeight: FontWeight.bold,
      fontSize: 28.0,
    ),
    titleLarge: GoogleFonts.poppins(
      color: const Color(0xFF212121),
      fontWeight: FontWeight.w700,
      fontSize: 20.0,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF3F51B5),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      shadowColor: const Color(0xFF3F51B5).withOpacity(0.3),
      textStyle: GoogleFonts.poppins(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: const Color(0xFF212121),
    elevation: 0,
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF212121),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF212121)),
  ),

  dividerTheme: DividerThemeData(
    color: Colors.grey[300],
    thickness: 1,
    space: 16,
  ),
  iconTheme: const IconThemeData(color: Color(0xFF212121), size: 24),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFF3F51B5),
    foregroundColor: Colors.white,
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withOpacity(0.8),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 2),
    ),
    hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
    labelStyle: GoogleFonts.poppins(
      color: const Color(0xFF212121),
      fontSize: 14,
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF3F51B5),
    contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    behavior: SnackBarBehavior.floating,
  ),
);

final ThemeData _darkTheme = ThemeData(
  scaffoldBackgroundColor: const Color(0xFF121212),
  secondaryHeaderColor: Colors.transparent,
  primaryColor: const Color(0xFF5C6BC0),
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFF5C6BC0),
    secondary: const Color.fromARGB(255, 255, 255, 255),
    surface: const Color(0xFF1E1E1E),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.grey.shade100,
  ),
  cardColor: const Color(0xFF1E1E1E),
  textTheme: TextTheme(
    bodyMedium: GoogleFonts.poppins(
      color: const Color(0xFFE0E0E0),
      fontWeight: FontWeight.w400,
      fontSize: 16.0,
    ),
    bodyLarge: GoogleFonts.poppins(
      color: const Color(0xFFE0E0E0),
      fontWeight: FontWeight.w600,
      fontSize: 18.0,
    ),
    headlineSmall: GoogleFonts.poppins(
      color: const Color(0xFFE0E0E0),
      fontWeight: FontWeight.bold,
      fontSize: 24.0,
    ),
    headlineMedium: GoogleFonts.poppins(
      color: const Color(0xFFE0E0E0),
      fontWeight: FontWeight.bold,
      fontSize: 28.0,
    ),
    titleLarge: GoogleFonts.poppins(
      color: const Color(0xFFE0E0E0),
      fontWeight: FontWeight.w700,
      fontSize: 20.0,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF5C6BC0),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      shadowColor: const Color(0xFF5C6BC0).withOpacity(0.3),
      textStyle: GoogleFonts.poppins(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: const Color(0xFFE0E0E0),
    elevation: 0,
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFE0E0E0),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFE0E0E0)),
  ),

  dividerTheme: DividerThemeData(
    color: Colors.grey[800],
    thickness: 1,
    space: 16,
  ),
  iconTheme: const IconThemeData(color: Color(0xFFE0E0E0), size: 24),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFF5C6BC0),
    foregroundColor: Colors.white,
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1E1E1E).withOpacity(0.8),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF5C6BC0), width: 2),
    ),
    hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
    labelStyle: GoogleFonts.poppins(
      color: const Color(0xFFE0E0E0),
      fontSize: 14,
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF5C6BC0),
    contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    behavior: SnackBarBehavior.floating,
  ),
);
