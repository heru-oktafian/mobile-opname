import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  const AppColors._();

  // 🌐 Warna utama (Facebook Blue)
  static const primary = MaterialColor(0xFF1877F2, {
    100: Color(0xFFE3F0FF),
    200: Color(0xFFB8D8FF),
    300: Color(0xFF8DC0FF),
    400: Color(0xFF5FA8FF),
    500: Color(0xFF1877F2),
    600: Color(0xFF166FE0),
    700: Color(0xFF135FC0),
    800: Color(0xFF0F4F9F),
    900: Color(0xFF0C3F7F),
  });

  // 🔵 Warna sekunder (abu kebiruan khas UI Facebook)
  static const secondary = MaterialColor(0xFFCED6E0, {
    100: Color(0xFFF7F9FA),
    200: Color(0xFFEDEFF2),
    300: Color(0xFFDEE3E8),
    400: Color(0xFFC7CED6),
    500: Color(0xFFCED6E0),
    600: Color(0xFFB2BAC4),
    700: Color(0xFF9BA3AD),
    800: Color(0xFF7F8993),
    900: Color(0xFF636C74),
  });

  // ℹ️ Warna info (biru muda)
  static const info = MaterialColor(0xFF00A0FF, {
    100: Color(0xFFD9F2FF),
    200: Color(0xFFB3E5FF),
    300: Color(0xFF80D4FF),
    400: Color(0xFF4DC3FF),
    500: Color(0xFF00A0FF),
    600: Color(0xFF0094E6),
    700: Color(0xFF0088CC),
    800: Color(0xFF007AB3),
    900: Color(0xFF006B99),
  });

  // ✅ Warna success (hijau khas Facebook Messenger success)
  static const success = MaterialColor(0xFF42B72A, {
    100: Color(0xFFE6F7E3),
    200: Color(0xFFC3ECB8),
    300: Color(0xFF9FE18D),
    400: Color(0xFF7BD662),
    500: Color(0xFF42B72A),
    600: Color(0xFF3CA425),
    700: Color(0xFF379021),
    800: Color(0xFF317D1C),
    900: Color(0xFF2B6918),
  });

  // ⚠️ Warna warning (kuning-oranye)
  static const warning = MaterialColor(0xFFFFC107, {
    100: Color(0xFFFFF8E1),
    200: Color(0xFFFFECB3),
    300: Color(0xFFFFE082),
    400: Color(0xFFFFD54F),
    500: Color(0xFFFFC107),
    600: Color(0xFFFFB300),
    700: Color(0xFFFFA000),
    800: Color(0xFFFF8F00),
    900: Color(0xFFFF6F00),
  });

  // ❌ Warna error (merah khas Google/Meta)
  static const error = MaterialColor(0xFFEB4335, {
    100: Color(0xFFFFE2DF),
    200: Color(0xFFFFB8B1),
    300: Color(0xFFFF8C82),
    400: Color(0xFFFF6053),
    500: Color(0xFFEB4335),
    600: Color(0xFFD13B2E),
    700: Color(0xFFB83228),
    800: Color(0xFF9E2A22),
    900: Color(0xFF851F1B),
  });

  // ⚪ Warna abu-abu netral untuk teks, background, border
  static const gray = MaterialColor(0xFF606770, {
    100: Color(0xFFF5F6F7),
    200: Color(0xFFE4E6EB),
    300: Color(0xFFD8DADF),
    400: Color(0xFFCCD0D5),
    500: Color(0xFF606770),
    600: Color(0xFF4E555E),
    700: Color(0xFF3C4043),
    800: Color(0xFF2A2C2F),
    900: Color(0xFF18191A),
  });

  // 🌈 Gradien utama Facebook
  static Gradient get gradients => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1877F2), Color(0xFF166FE0)],
  );
}

// 🖋️ Text styles dengan warna dan font khas Facebook UI
TextStyle blackTextStyle = GoogleFonts.poppins(color: AppColors.gray[900]);
TextStyle whiteTextStyle = GoogleFonts.poppins(color: AppColors.gray[100]);
TextStyle greyTextStyle = GoogleFonts.poppins(color: AppColors.gray[500]);
TextStyle successTextStyle = GoogleFonts.poppins(color: AppColors.success);
TextStyle infoTextStyle = GoogleFonts.poppins(color: AppColors.info);
TextStyle warningTextStyle = GoogleFonts.poppins(color: AppColors.warning);
TextStyle errorTextStyle = GoogleFonts.poppins(color: AppColors.error);

// 🧱 Font weights standar
FontWeight light = FontWeight.w300;
FontWeight reguler = FontWeight.w400;
FontWeight medium = FontWeight.w500;
FontWeight semiBold = FontWeight.w600;
FontWeight bold = FontWeight.w700;
FontWeight extraBold = FontWeight.w800;
FontWeight black = FontWeight.w900;
