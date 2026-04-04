import 'package:fluent_ui/fluent_ui.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';

class EntityAddButton extends StatelessWidget {
  const EntityAddButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.icon = FluentIcons.add,
    this.iconSize,
    this.size = AppControlSize.md,
  });

  final String label;
  final VoidCallback onPressed;
  final String? tooltip;
  final IconData icon;
  final double? iconSize;
  final AppControlSize size;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(size.contentPadding),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize ?? size.iconSize),
          const SizedBox(width: AppUiTokens.space6),
          Text(label),
        ],
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) {
      return button;
    }

    return Tooltip(
      message: tooltip!,
      child: button,
    );
  }
}

