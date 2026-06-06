import 'package:flutter/material.dart';

class AppColor {
  AppColor._();

  // Background Colors
  static const Color kbgColor  = Color(0xFFF0F4F8); 
  static const Color kbgColor2 = Color(0xFFFFFFFF);

  // Primary Brand Colors  (blue to match screenshots)
  static const Color kPrimaryColor  = Color(0xFF2563EB);  
  static const Color kSecondColor   = Color(0xFF0F172A);  

  // Text Colors
  static const Color kTextStyleColor     = Color(0xFF1E293B);
  static const Color kTextStyleColorGray = Color(0xFF94A3B8);

  // Border Colors
  static const Color borderPrimary   = Color(0xFFE2E8F0);
  static const Color borderSecondary = Color(0xFFF1F5F9);

  // Button Colors
  static const Color buttonPrimary   = Color(0xFF2563EB);
  static const Color buttonSecondary = Color(0xFF0F172A);
  static const Color buttonDisabled  = Color(0xFFCBD5E1);

  // Success / Completed Task
  static const Color kCheckInActiveTextColor  = Color(0xFF16A34A);
  static const Color kcheckInInActiveBgColor  = Color(0xFFDCFCE7);

  // Error / Urgent Task
  static const Color kCheckOutActiveTextColor = Color(0xFFDC2626);
  static const Color kCheckOutInActiveBgColor = Color(0xFFFEE2E2);
}