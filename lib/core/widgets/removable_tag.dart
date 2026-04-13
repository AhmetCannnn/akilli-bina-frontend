import 'package:fluent_ui/fluent_ui.dart';

import 'entity_tag.dart';

/// Silinebilir veya sabit etiket; görünüm [EntityTag] ile aynı (rapor stili).
///
/// [onRemove] null ise sadece etiket; doluysa sağda kapatma ikonu çıkar.
class RemovableTag extends StatelessWidget {
  const RemovableTag({
    super.key,
    required this.label,
    this.onRemove,
    this.color,
  });

  final String label;
  final VoidCallback? onRemove;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tagColor = color ?? Colors.blue;
    return EntityTag(
      label: label,
      color: tagColor,
      onRemove: onRemove,
    );
  }
}
