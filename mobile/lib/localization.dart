import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const supportedLocales = [
    Locale('en', ''),
    Locale('km', ''),
  ];

  static const fallbackLocale = Locale('en', '');

  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
  }

  static Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('language') ?? 'en';
    return Locale(language);
  }
}
