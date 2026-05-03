import "package:flutter/material.dart";

class AppColor {
  AppColor._();

  // Background Colors
  static Color kbgColor = const Color(0xFFF8FAFC);
  static Color kbgColor2 = const Color(0xFFFFFFFF);

  // Primary Brand Colors
  static Color kPrimaryColor = const Color(0xFF4F46E5); 
  static Color kSecondColor = const Color(0xFF0F172A); 

  // Text Colors
  static Color kTextStyleColor = const Color(0xFF1E293B);
  static Color kTextStyleColorGray = const Color(0xFF94A3B8);

  // Border Colors
  static const Color borderPrimary = Color(0xFFE2E8F0);
  static const Color borderSecondary = Color(0xFFF1F5F9);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF4F46E5);
  static const Color buttonSecondary = Color(0xFF0F172A);
  static const Color buttonDisabled = Color(0xFFCBD5E1);

  // Success / Completed Task
  static const Color kCheckInActiveTextColor = Color(0xFF16A34A);
  static const Color kcheckInInActiveBgColor = Color(0xFFDCFCE7);

  // Error / Urgent Task
  static const Color kCheckOutActiveTextColor = Color(0xFFDC2626);
  static const Color kCheckOutInActiveBgColor = Color(0xFFFEE2E2);
}