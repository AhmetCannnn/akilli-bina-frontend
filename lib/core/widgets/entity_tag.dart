import 'package:fluent_ui/fluent_ui.dart';

/// Ortak etiket stili (rapor detay / liste kartlarındaki pill ile aynı):
/// hafif renkli arka plan, 4px köşe, caption + w600.
///
/// [onRemove] verilirse sağda küçük kapatma ikonu gösterilir.
class EntityTag extends StatelessWidget {
  const EntityTag({
    super.key,
    required this.label,
    required this.color,
    this.onRemove,
  });

  final String label;
  final Color color;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.typography.caption?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(FluentIcons.chrome_close, size: 12, color: color),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}
