import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _locale = const Locale('en');
  
  Locale get locale => _locale;
  
  String get currentLanguageCode => _locale.languageCode;
  
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      case 'en':
      default:
        return 'English';
    }
  }

  LocalizationProvider() {
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      
      if (savedLanguage != null) {
        _locale = Locale(savedLanguage);
      } else {
        // Default to English if no saved preference
        _locale = const Locale('en');
      }
      
      notifyListeners();
    } catch (e) {
      print('Error initializing language: $e');
      _locale = const Locale('en');
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _locale = Locale(languageCode);
      await prefs.setString(_languageKey, languageCode);
      
      notifyListeners();
    } catch (e) {
      print('Error setting language: $e');
    }
  }

  // Helper to get all supported languages
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
    {'code': 'fr', 'name': 'French', 'nativeName': 'Français'},
  ];
}
