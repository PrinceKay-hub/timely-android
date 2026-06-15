import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeKey = 'app_theme';
  
  ThemeCubit() : super(const ThemeState(themeMode: AppTheme.system)) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);
      
      if (themeIndex != null && themeIndex >= 0 && themeIndex < AppTheme.values.length) {
        final themeMode = AppTheme.values[themeIndex];
        emit(ThemeState(themeMode: themeMode));
      }
    } catch (e) {
      // Use default theme if error occurs
      emit(const ThemeState(themeMode: AppTheme.system));
    }
  }

  Future<void> setTheme(AppTheme themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeMode.index);
      emit(ThemeState(themeMode: themeMode));
    } catch (e) {
      // If saving fails, still update the state
      emit(ThemeState(themeMode: themeMode));
    }
  }

  Future<void> toggleTheme() async {
    final currentTheme = state.themeMode;
    AppTheme newTheme;
    
    if (currentTheme == AppTheme.light) {
      newTheme = AppTheme.dark;
    } else if (currentTheme == AppTheme.dark) {
      newTheme = AppTheme.system;
    } else {
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      newTheme = brightness == Brightness.dark ? AppTheme.light : AppTheme.dark;
    }
    
    await setTheme(newTheme);
  }

  bool get isDarkMode {
    if (state.themeMode == AppTheme.dark) return true;
    if (state.themeMode == AppTheme.light) return false;
    
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    return brightness == Brightness.dark;
  }
}