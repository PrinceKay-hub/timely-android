part of 'theme_cubit.dart';

enum AppTheme { light, dark, system }

class ThemeState extends Equatable {
  final AppTheme themeMode;
  
  const ThemeState({
    required this.themeMode,
  });

  ThemeState copyWith({
    AppTheme? themeMode,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object> get props => [themeMode];

  @override
  bool get stringify => true;
}