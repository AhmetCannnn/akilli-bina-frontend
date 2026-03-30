import 'package:fluent_ui/fluent_ui.dart';

/// Detay bölümü widget'ı
/// Modal'larda ve detay sayfalarında kullanılan ortak bir widget
Widget buildDetailSection(FluentThemeData theme, String title, IconData icon, List<Widget> children) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: theme.iconTheme.color?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.accentColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.typography.subtitle?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

/// Detay satırı widget'ı
/// Modal'larda ve detay sayfalarında kullanılan ortak bir widget
Widget buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    ),
  );
}

