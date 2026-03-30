import 'package:fluent_ui/fluent_ui.dart';

class AuthErrorInfo extends StatelessWidget {
  const AuthErrorInfo({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return InfoBar(
      title: Text(title),
      content: Text(message),
      severity: InfoBarSeverity.error,
    );
  }
}

