import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale';

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('es');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeModeString = prefs.getString(_themeKey) ?? 'light';
    _themeMode = themeModeString == 'dark' ? ThemeMode.dark : ThemeMode.light;
    
    final localeString = prefs.getString(_localeKey) ?? 'es';
    _locale = Locale(localeString);
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}
