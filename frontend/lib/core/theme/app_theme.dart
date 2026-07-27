import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFFBCC2FF);
  static const onPrimaryColor = Color(0xFF152284);
  static const backgroundColor = Color(0xFF131313);
  static const surfaceColor = Color(0xFF131313);
  static const surfaceContainerHigh = Color(0xFF2A2A2A);
  static const onSurfaceColor = Color(0xFFE5E2E1);
  static const onSurfaceVariantColor = Color(0xFFC6C5D4);

  static final colorScheme = ColorScheme.dark(
    primary: primaryColor,
    onPrimary: onPrimaryColor,
    surface: surfaceColor,
    onSurface: onSurfaceColor,
    onSurfaceVariant: onSurfaceVariantColor,
    surfaceContainerHigh: surfaceContainerHigh,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: colorScheme,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.28,
        letterSpacing: -0.28,
        color: primaryColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.28,
        letterSpacing: -0.28,
        color: onSurfaceColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Hanken Grotesk',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.16,
        color: onSurfaceVariantColor,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Hanken Grotesk',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.56,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Hanken Grotesk',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.33,
        letterSpacing: 0.24,
        color: onSurfaceVariantColor,
      ),
    ),
  );
}
