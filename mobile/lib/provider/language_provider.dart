import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  String _language = 'English';

  String get language => _language;

  void setLanguage(String newLanguage) {
    _language = newLanguage;
    notifyListeners();
  }
}
