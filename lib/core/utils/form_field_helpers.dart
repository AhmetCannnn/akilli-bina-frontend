import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import '../widgets/removable_tag.dart';

/// TextBox field helper - InfoLabel + TextBox kombinasyonu
Widget buildFormTextField({
  required String label,
  required TextEditingController controller,
  String? placeholder,
  int maxLines = 1,
  VoidCallback? onChanged,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  Widget? suffix,
}) {
  return InfoLabel(
    label: label,
    child: TextBox(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      suffix: suffix,
      onChanged: onChanged != null ? (_) => onChanged() : null,
    ),
  );
}

/// ComboBox field helper - InfoLabel + ComboBox kombinasyonu
Widget buildFormComboBox<T>({
  required String label,
  required T value,
  required List<T> items,
  required String Function(T) displayText,
  required void Function(T?) onChanged,
}) {
  return InfoLabel(
    label: label,
    child: Padding(
      // Label ile ComboBox arasında ufak bir boşluk bırak, dropdown label'i kapatmasın
      padding: const EdgeInsets.only(top: 4),
      child: ComboBox<T>(
        value: value,
        items: items.map((item) {
          return ComboBoxItem(
            value: item,
            child: Text(displayText(item)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

/// İki field'ı yan yana koyan helper
Widget buildFormRow(List<Widget> children) {
  return Row(
    children: children
        .expand((child) => [child, const SizedBox(width: 12)])
        .take(children.length * 2 - 1)
        .toList(),
  );
}

/// Liste input field helper - TextBox + Button kombinasyonu
Widget buildListInputField({
  required String label,
  required TextEditingController controller,
  required String placeholder,
  required void Function(String) onAdd,
}) {
  return InfoLabel(
    label: label,
    child: Row(
      children: [
        Expanded(
          child: TextBox(
            controller: controller,
            placeholder: placeholder,
            onSubmitted: onAdd,
          ),
        ),
        const SizedBox(width: 8),
        Button(
          onPressed: () => onAdd(controller.text),
          child: const Text('Ekle'),
        ),
      ],
    ),
  );
}

/// Tag listesi widget'ı oluştur - RemovableTag'ler için
/// 
/// Kullanım örneği:
/// ```dart
/// buildTagList(
///   items: departments,
///   color: Colors.blue,
///   onRemove: (item) {
///     setState(() => departments.remove(item));
///     getFormData();
///   },
/// )
/// ```
Widget buildTagList({
  required List<String> items,
  required void Function(String) onRemove,
  Color? color,
  double height = 64,
}) {
  return SizedBox(
    height: height,
    child: SingleChildScrollView(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map((item) => RemovableTag(
                  label: item,
                  color: color,
                  onRemove: () => onRemove(item),
                ))
            .toList(),
      ),
    ),
  );
}

