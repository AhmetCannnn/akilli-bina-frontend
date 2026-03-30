import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    loadTheme();
  }

  static const _key = 'theme_mode';

  /// Tema modunu değiştir (Sistem, Açık, Koyu)
  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    ThemeMode newMode;
    
    switch (mode) {
      case 'Sistem':
        newMode = ThemeMode.system;
        break;
      case 'Açık':
        newMode = ThemeMode.light;
        break;
      case 'Koyu':
        newMode = ThemeMode.dark;
        break;
      default:
        newMode = ThemeMode.system;
    }
    
    state = newMode;
    await prefs.setString(_key, mode);
  }

  /// Mevcut tema modunu string olarak döndür
  String getThemeModeString() {
    switch (state) {
      case ThemeMode.system:
        return 'Sistem';
      case ThemeMode.light:
        return 'Açık';
      case ThemeMode.dark:
        return 'Koyu';
    }
  }

  /// Eski toggle fonksiyonu (geriye dönük uyumluluk için)
  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await prefs.setString(_key, getThemeModeString());
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_key);
    if (themeString != null) {
      switch (themeString) {
        case 'Sistem':
          state = ThemeMode.system;
          break;
        case 'Açık':
          state = ThemeMode.light;
          break;
        case 'Koyu':
          state = ThemeMode.dark;
          break;
        // Eski format desteği (geriye dönük uyumluluk)
        case 'ThemeMode.dark':
          state = ThemeMode.dark;
          await prefs.setString(_key, 'Koyu');
          break;
        case 'ThemeMode.light':
          state = ThemeMode.light;
          await prefs.setString(_key, 'Açık');
          break;
        default:
          state = ThemeMode.system;
      }
    } else {
      // Varsayılan olarak sistem temasını kullan
      state = ThemeMode.system;
    }
  }
}

