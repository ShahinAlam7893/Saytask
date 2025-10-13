import 'package:flutter/material.dart';


class AppColors {
  static const Color red = Color(0xFFE94057);
  static const Color secondaryRed = Color(0xFFFFEDE9);
  static const Color secondaryTextColor = Color(0xFF747474);
  static const Color blueColor = Color(0XFF0C517E);
  static const Color accentColor = Color(0xFFF27121);
  static const Color black = Color(0xFF1F1F1F);
  static const Color deepBlack = Color(0xFF2C2C2C);
  static const Color green = Color(0xFF31B155);
  static const Color secondaryGreen = Color(0xFFE4EDE6);
  static const Color inputFieldBorder = Color(0xFF9D9D9D);
  static const Color white = Color(0xFFFEFEFE);
  static const Color grey = Color(0xFF7D7D7D);

  static LinearGradient backgroundGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0E4269),
      Color(0xFF2AB29C),
      Color(0xFFF6C643),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient horizontalGradient = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFF4F4F4), // Light gray
      Color(0xFF0C517E), // Deep blue
      Color(0xFFF4F4F4), // Light gray again
    ],
    stops: [0.0, 0.5, 1.0],
  );

}