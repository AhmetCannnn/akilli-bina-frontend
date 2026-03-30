import 'package:fluent_ui/fluent_ui.dart';

/// Tag widget - Genel kullanım (silinebilir/silinebilir olmayan)
///
/// Kullanım örnekleri:
/// ```dart
/// // Silinebilir tag (X butonu çıkar)
/// RemovableTag(
///   label: 'Birim Adı',
///   color: Colors.blue,
///   onRemove: () => removeItem('Birim Adı'),
/// )
///
/// // Silinemeyen tag (border + şeffaf arka plan)
/// RemovableTag(
///   label: 'Durum',
///   color: Colors.green,
/// )
/// ```
class RemovableTag extends StatelessWidget {
  const RemovableTag({
    super.key,
    required this.label,
    this.onRemove,
    this.color,
  });

  final String label;
  final VoidCallback? onRemove; // Null ise silinemez
  final Color? color; // Eğer null ise varsayılan renk kullanılır

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final tagColor = color ?? Colors.blue;

    final bool isRemovable = onRemove != null;

    // Tek stil: border + şeffaf arka plan (chip görünümü)
    final decoration = BoxDecoration(
      color: tagColor.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: tagColor.withOpacity(0.35)),
    );
    final textStyle = theme.typography.caption?.copyWith(
      color: tagColor,
      fontWeight: FontWeight.w600,
    ) ??
        TextStyle(color: tagColor, fontWeight: FontWeight.w600);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: decoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textStyle,
          ),
          if (isRemovable) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: Icon(FluentIcons.chrome_close, size: 12, color: tagColor),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}

