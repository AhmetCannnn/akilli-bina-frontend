import 'package:fluent_ui/fluent_ui.dart';

class AppTheme {
  // Fluent UI temaları (Material API'leri kaldırıldı)
  static FluentThemeData get lightThemeFluent {
    return FluentThemeData(
      brightness: Brightness.light,
      accentColor: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFF3F3F3),
      navigationPaneTheme: const NavigationPaneThemeData(
        backgroundColor: Color(0xFFFAFAFA),
        highlightColor: Color(0xFFE3F2FD),
      ),
      typography: Typography.fromBrightness(
        brightness: Brightness.light,
        color: Colors.black,
      ),
    );
  }

  static FluentThemeData get darkThemeFluent {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFF202020),
      navigationPaneTheme: const NavigationPaneThemeData(
        backgroundColor: Color(0xFF2D2D30),
        highlightColor: Color(0xFF404040),
      ),
      typography: Typography.fromBrightness(
        brightness: Brightness.dark,
        color: Colors.white,
      ),
    );
  }
}

