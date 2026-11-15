import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _key = 'theme_mode';
  // Older builds stored a bool; still honoured so nobody loses their choice.
  static const String _legacyKey = 'theme_mode_dark';

  ThemeMode _mode = ThemeMode.system;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_key);
      final legacyDark = prefs.getBool(_legacyKey);
      if (stored != null) {
        _mode = ThemeMode.values.firstWhere(
          (mode) => mode.name == stored,
          orElse: () => ThemeMode.system,
        );
      } else if (legacyDark != null) {
        _mode = legacyDark ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (error) {
      debugPrint('Failed to load theme preference: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Until the user picks a theme the app follows the system setting.
  Future<void> setDark(bool dark) async {
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _mode.name);
  }
}
