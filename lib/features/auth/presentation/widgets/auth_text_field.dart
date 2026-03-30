import 'package:fluent_ui/fluent_ui.dart';

/// Modern, kompakt auth text field widget
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.icon,
    this.obscureText = false,
    this.onToggleVisibility,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.errorText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.typography.bodyStrong?.copyWith(
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextBox(
          controller: controller,
          placeholder: placeholder,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          enabled: enabled,
          prefix: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              icon,
              color: theme.accentColor,
              size: 16,
            ),
          ),
          suffix: onToggleVisibility != null
              ? IconButton(
                  icon: Icon(
                    obscureText ? FluentIcons.view : FluentIcons.hide,
                    size: 16,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          style: theme.typography.body,
        ),
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

