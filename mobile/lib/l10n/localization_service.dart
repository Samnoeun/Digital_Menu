import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static final supportedLocales = [
    const Locale('en'),
    const Locale('km'),
  ];

  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
  }

  static Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'en';
    return Locale(langCode);
  }
}
