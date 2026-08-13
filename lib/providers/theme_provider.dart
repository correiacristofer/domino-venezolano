import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _key = 'theme_mode_dark';
  bool _isDark = true;
  bool _isLoading = true;

  bool get isDark => _isDark;
  bool get isLoading => _isLoading;
  ThemeMode get mode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool(_key) ?? true;
    } catch (error) {
      debugPrint('Failed to load theme preference: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
  }
}
