import 'package:fluent_ui/fluent_ui.dart';
import 'package:belediye_otomasyon/core/utils/backend_datetime.dart';
import 'package:belediye_otomasyon/core/widgets/entity_action_buttons.dart';
import 'package:belediye_otomasyon/core/widgets/entity_list_card.dart';

String maintenanceStatusLabel(String? status) {
  switch (status) {
    case 'taslak':
      return 'Taslak';
    case 'planlandı':
      return 'Planlandı';
    case 'tamamlandı':
      return 'Tamamlandı';
    default:
      return status ?? '';
  }
}

Color maintenanceStatusColorFor(String? status) {
  switch (status) {
    case 'taslak':
      return Colors.blue;
    case 'planlandı':
      return Colors.orange;
    case 'tamamlandı':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

String maintenanceTypeLabel(String? type) {
  if (type == null || type.isEmpty) return '';
  switch (type) {
    case 'rutin':
      return 'Rutin';
    case 'acil':
      return 'Acil';
    case 'planlı':
      return 'Planlı';
    default:
      return type;
  }
}

/// Liste satırı: Türkiye gösterim saati (`parseBackendDateTime` sonrası) — rapor listesi ile aynı biçim.
String formatMaintenanceListDateTime(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// `updated_at`, `created_at` sonrası anlamlıysa güncelleme; değilse oluşturulma metni.
String? maintenanceRowCreatedOrUpdatedLabel(Map<String, dynamic> maintenance) {
  final cRaw = maintenance['created_at'];
  final uRaw = maintenance['updated_at'];
  final DateTime? createdAt = (cRaw != null && cRaw.toString().isNotEmpty)
      ? parseBackendDateTime(cRaw.toString())
      : null;
  final DateTime? updatedAt = (uRaw != null && uRaw.toString().isNotEmpty)
      ? parseBackendDateTime(uRaw.toString())
      : null;
  if (updatedAt != null &&
      createdAt != null &&
      updatedAt.isAfter(createdAt)) {
    return 'Güncelleme: ${formatMaintenanceListDateTime(updatedAt)}';
  }
  if (createdAt != null) {
    return 'Oluşturulma: ${formatMaintenanceListDateTime(createdAt)}';
  }
  if (updatedAt != null) {
    return 'Güncelleme: ${formatMaintenanceListDateTime(updatedAt)}';
  }
  return null;
}

/// Bakım listelerinde (tam sayfa ve bina detayı sekmesi) ortak kart düzeni.
class MaintenanceEntityListCard extends StatelessWidget {
  const MaintenanceEntityListCard({
    super.key,
    required this.maintenance,
    required this.onEdit,
    required this.onDelete,
    required this.onDetail,
  });

  final Map<String, dynamic> maintenance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final title = maintenance['title'] ?? 'Bakım Kaydı';
    final description = maintenance['description'] ?? '';
    final status = maintenance['status'] ?? 'scheduled';
    final maintenanceType = maintenance['maintenance_type']?.toString() ?? '';
    final String locText = maintenance['location']?.toString() ?? '';
    final cost = maintenance['cost'];
    final scheduledDate = maintenance['scheduled_date'] != null
        ? parseBackendDateTime(maintenance['scheduled_date'].toString())
        : null;
    final createdOrUpdatedLine = maintenanceRowCreatedOrUpdatedLabel(maintenance);
    final statusColor = maintenanceStatusColorFor(status);
    final subtitle =
        maintenanceType.isNotEmpty ? maintenanceTypeLabel(maintenanceType) : null;

    return EntityListCard(
      margin: const EdgeInsets.only(bottom: 10),
      header: EntityListCardHeaderRow(
        leading: EntityListCardLeadingIconBox(
          icon: FluentIcons.build_definition,
          color: statusColor,
        ),
        title: title,
        subtitle: subtitle,
        trailing: EntityListCardHeaderPill(
          label: maintenanceStatusLabel(status),
          color: statusColor,
        ),
      ),
      description: description,
      descriptionMaxLines: 2,
      footer: Row(
        children: [
          if (locText.isNotEmpty) ...[
            EntityListCardMetaIconText(
              icon: FluentIcons.map_pin,
              text: locText,
            ),
            const SizedBox(width: 16),
          ],
          if (scheduledDate != null) ...[
            EntityListCardMetaIconText(
              icon: FluentIcons.calendar,
              text: 'Planlanan: ${formatMaintenanceListDateTime(scheduledDate)}',
            ),
            const SizedBox(width: 16),
          ],
          if (createdOrUpdatedLine != null) ...[
            EntityListCardMetaIconText(
              icon: FluentIcons.clock,
              text: createdOrUpdatedLine,
            ),
            const SizedBox(width: 16),
          ],
          if (cost != null) ...[
            Icon(
              FluentIcons.money,
              size: 16,
              color: theme.iconTheme.color?.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              '₺${(cost is num ? cost : double.parse(cost.toString())).toStringAsFixed(0)}',
              style: theme.typography.caption?.copyWith(
                color: theme.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          EntityActionButtons(
            width: 170,
            onEdit: onEdit,
            onDelete: onDelete,
            onDetail: onDetail,
          ),
        ],
      ),
    );
  }
}
