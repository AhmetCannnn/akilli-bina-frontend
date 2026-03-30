import 'package:fluent_ui/fluent_ui.dart';

/// Modern, kompakt auth button widget
class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isPrimary = true,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: ButtonStyle(
          padding: ButtonState.all(
            const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: ProgressRing(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text('Yükleniyor...'),
                ],
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
    } else {
      return Button(
        onPressed: isLoading ? null : onPressed,
        child: Text(text),
      );
    }
  }
}

