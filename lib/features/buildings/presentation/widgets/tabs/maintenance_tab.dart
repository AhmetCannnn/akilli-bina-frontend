import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../maintenance/presentation/providers/maintenance_provider.dart';
import '../../utils/building_helpers.dart';
import '../../providers/building_provider.dart';
import 'package:belediye_otomasyon/core/widgets/removable_tag.dart' show RemovableTag;
import 'package:belediye_otomasyon/core/utils/backend_datetime.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';

class MaintenanceTab extends ConsumerWidget {
  const MaintenanceTab({required this.building, super.key});

  final Map<String, dynamic> building;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final buildingId = building['id'] as int;
    final maintenanceAsync = ref.watch(maintenanceByBuildingProvider(buildingId));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppUiTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          maintenanceAsync.when(
            data: (maintenanceList) => _MaintenanceList(maintenanceList: maintenanceList),
            loading: () => const Center(child: ProgressRing()),
            error: (error, stack) => Card(
              child: Padding(
                padding: const EdgeInsets.all(AppUiTokens.space24),
                child: Column(
                  children: [
                    Icon(
                      FluentIcons.warning,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: AppUiTokens.space12),
                    Text(
                      'Bakım verileri yüklenirken hata oluştu',
                      style: theme.typography.body?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppUiTokens.space4),
                    Text(
                      'Lütfen daha sonra tekrar deneyin',
                      style: theme.typography.caption?.copyWith(
                        color: theme.iconTheme.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceList extends StatelessWidget {
  const _MaintenanceList({required this.maintenanceList});

  final List<Map<String, dynamic>> maintenanceList;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    if (maintenanceList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppUiTokens.space24),
          child: Column(
            children: [
              Icon(
                // Sidebar'daki \"Bakımlar\" sekmesi ile aynı ikon
                FluentIcons.build_definition,
                size: 48,
                color: theme.iconTheme.color?.withOpacity(0.5),
              ),
              const SizedBox(height: AppUiTokens.space12),
              Text(
                'Henüz bakım kaydı bulunmuyor',
                style: theme.typography.body?.copyWith(
                  color: theme.iconTheme.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppUiTokens.space4),
              Text(
                'Bu binaya ait bakım kayıtları görüntülenecek',
                style: theme.typography.caption?.copyWith(
                  color: theme.iconTheme.color?.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppUiTokens.space16),
        child: Column(
          children: [
            ...maintenanceList.map((maintenance) => Padding(
              padding: const EdgeInsets.only(bottom: AppUiTokens.space16),
              child: _MaintenanceItem(
                maintenance: maintenance,
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  MaintenanceStatus _getMaintenanceStatus(String? status) {
    switch (status) {
      case 'taslak':
        return MaintenanceStatus.draft;
      case 'planlandı':
        return MaintenanceStatus.planned;
      case 'tamamlandı':
        return MaintenanceStatus.done;
      default:
        return MaintenanceStatus.planned;
    }
  }
}

enum MaintenanceStatus {
  draft,
  planned,
  done;

  Color get color {
    switch (this) {
      case MaintenanceStatus.draft:
        return Colors.blue; // Taslak - Mavi
      case MaintenanceStatus.planned:
        return Colors.orange; // Planlandı - Turuncu
      case MaintenanceStatus.done:
        return Colors.green; // Tamamlandı - Yeşil
    }
  }

  String get text {
    switch (this) {
      case MaintenanceStatus.draft:
        return 'Taslak';
      case MaintenanceStatus.planned:
        return 'Planlandı';
      case MaintenanceStatus.done:
        return 'Tamamlandı';
    }
  }
}

// Top-level helper to map status string to enum (reused by list items)
MaintenanceStatus _mapMaintenanceStatus(String? status) {
  switch (status) {
    case 'taslak':
      return MaintenanceStatus.draft;
    case 'planlandı':
      return MaintenanceStatus.planned;
    case 'tamamlandı':
      return MaintenanceStatus.done;
    default:
      return MaintenanceStatus.planned;
  }
}

class _MaintenanceItem extends StatelessWidget {
  const _MaintenanceItem({
    required this.maintenance,
  });

  final Map<String, dynamic> maintenance;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    final String title = maintenance['title'] ?? 'Bakım Kaydı';
    final String? description = maintenance['description'];
    final DateTime date = maintenance['scheduled_date'] != null
        ? parseBackendDateTime(maintenance['scheduled_date'].toString())
        : DateTime.now();
    final MaintenanceStatus status = _mapMaintenanceStatus(maintenance['status']);
    final double? cost = (maintenance['cost'] is num)
        ? (maintenance['cost'] as num).toDouble()
        : (maintenance['cost'] != null
            ? double.tryParse(maintenance['cost'].toString())
            : null);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openMaintenanceDetailModal(context, maintenance),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppUiTokens.space12,
          AppUiTokens.space8,
          AppUiTokens.space12,
          AppUiTokens.space12,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.iconTheme.color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
          ),
          borderRadius: BorderRadius.circular(AppUiTokens.radius8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.typography.bodyStrong,
                      ),
                      if (description != null) ...[
                        const SizedBox(height: AppUiTokens.space4),
                        Text(
                          description,
                          style: theme.typography.caption?.copyWith(
                            color: theme.typography.caption?.color?.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppUiTokens.space12),
                RemovableTag(label: status.text, color: status.color),
              ],
            ),
            const SizedBox(height: AppUiTokens.space8),
            Row(
              children: [
                Icon(
                  FluentIcons.calendar,
                  size: 14,
                  color: theme.iconTheme.color?.withOpacity(0.6),
                ),
                const SizedBox(width: AppUiTokens.space4),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: theme.typography.caption?.copyWith(
                    color: theme.iconTheme.color?.withOpacity(0.7),
                  ),
                ),
                if (cost != null) ...[
                  const SizedBox(width: AppUiTokens.space16),
                  Text(
                    '₺${cost.toStringAsFixed(0)}',
                    style: theme.typography.caption?.copyWith(
                      color: theme.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _openMaintenanceDetailModal(
  BuildContext context,
  Map<String, dynamic> maintenance,
) {
  final theme = FluentTheme.of(context);

  final String title = maintenance['title'] ?? 'Bakım Kaydı';
  final String description = maintenance['description'] ?? '';
  final String status = maintenance['status'] ?? 'scheduled';
  final String maintenanceType = maintenance['maintenance_type'] ?? '';
  final String locationText = maintenance['location']?.toString() ?? '';
  final dynamic costRaw = maintenance['cost'];
  final String priority = maintenance['priority']?.toString() ?? '';
  final String categoryStr = maintenance['category']?.toString() ?? '';
  final DateTime? scheduledDate = maintenance['scheduled_date'] != null
      ? parseBackendDateTime(maintenance['scheduled_date'].toString())
      : null;
  final DateTime? completedDate = maintenance['completed_date'] != null
      ? parseBackendDateTime(maintenance['completed_date'].toString())
      : null;
  final DateTime? createdAt = maintenance['created_at'] != null
      ? parseBackendDateTime(maintenance['created_at'].toString())
      : null;
  final DateTime? updatedAt = maintenance['updated_at'] != null
      ? parseBackendDateTime(maintenance['updated_at'].toString())
      : null;
  final dynamic buildingId = maintenance['building_id'];
  final String notes = maintenance['notes']?.toString() ?? '';
  final String performedBy = maintenance['performed_by']?.toString() ?? '';

  showDialog(
    context: context,
    builder: (ctx) => ContentDialog(
      constraints: BoxConstraints(
        maxWidth: (MediaQuery.of(context).size.width - 96)
            .clamp(0.0, 820.0)
            .toDouble(),
      ),
      title: SizedBox(
        height: 40,
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FluentIcons.build_definition, size: 18),
                  const SizedBox(width: AppUiTokens.space8),
                  Text(title, style: theme.typography.bodyStrong),
                ],
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: Icon(FluentIcons.chrome_close, color: Colors.red),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppUiTokens.space12, AppUiTokens.space4, AppUiTokens.space12, AppUiTokens.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppUiTokens.space8,
              runSpacing: AppUiTokens.space8,
              children: [
                RemovableTag(label: _statusText(status), color: _statusColor(status)),
                if (priority.isNotEmpty)
                  RemovableTag(label: priority, color: _priorityColor(priority)),
                if (categoryStr.isNotEmpty)
                  RemovableTag(label: categoryStr, color: Colors.blue),
                if (buildingId != null)
                  Consumer(
                    builder: (context, ref, _) {
                      final buildingsAsync = ref.watch(buildingControllerProvider);
                      String label = '-';
                      buildingsAsync.when(
                        data: (list) {
                          final match = list.firstWhere(
                            (b) => b['id'] == buildingId,
                            orElse: () => {},
                          );
                          if (match is Map<String, dynamic>) {
                            final nm = (match['name'] ?? '').toString();
                            if (nm.isNotEmpty) label = nm;
                          }
                        },
                        loading: () {},
                        error: (_, __) {},
                      );
                      return RemovableTag(label: label, color: theme.accentColor);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppUiTokens.space12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppUiTokens.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(ctx, 'Başlık', title),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: AppUiTokens.space8),
                      _detailRow(ctx, 'Açıklama', description),
                    ],
                    if (locationText.isNotEmpty) ...[
                      const SizedBox(height: AppUiTokens.space8),
                      _detailRow(ctx, 'Bakım Yeri', locationText),
                    ],
                    if (maintenanceType.isNotEmpty) ...[
                      const SizedBox(height: AppUiTokens.space8),
                      _detailRow(ctx, 'Bakım Türü', _maintenanceTypeText(maintenanceType)),
                    ],
                    if (scheduledDate != null) ...[
                      const SizedBox(height: AppUiTokens.space8),
                      _detailRow(ctx, 'Planlanan Tarih', _formatDate(scheduledDate)),
                    ],
                    if (completedDate != null) ...[
                      const SizedBox(height: AppUiTokens.space8),
                      _detailRow(ctx, 'Tamamlanma Tarihi', _formatDate(completedDate)),
                    ],
                    if (costRaw != null) ...[
                      const SizedBox(height: AppUiTokens.space8),
                      _detailRow(
                        ctx,
                        'Maliyet',
                        '₺${(costRaw is num ? costRaw : double.parse(costRaw.toString())).toStringAsFixed(0)}',
                      ),
                    ],
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: AppUiTokens.space8),
                      _detailRow(ctx, 'Notlar', notes),
                    ],
                    if (performedBy.isNotEmpty) ...[
                      const SizedBox(height: AppUiTokens.space8),
                      _detailRow(ctx, 'Yapan (UUID)', performedBy),
                    ],
                    if (createdAt != null) ...[
                      const SizedBox(height: AppUiTokens.space8),
                      _detailRow(ctx, 'Oluşturma', _formatDateTime(createdAt)),
                    ],
                    if (updatedAt != null) ...[
                      const SizedBox(height: AppUiTokens.space8),
                      _detailRow(ctx, 'Güncelleme', _formatDateTime(updatedAt)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: null,
    ),
  );
}

String _statusText(String status) {
  switch (status) {
    case 'taslak':
      return 'Taslak';
    case 'planlandı':
      return 'Planlandı';
    case 'tamamlandı':
      return 'Tamamlandı';
    default:
      return status;
  }
}

Color _statusColor(String status) {
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

Color _priorityColor(String priority) {
  switch (priority) {
    case 'Düşük':
      return Colors.green;
    case 'Orta':
      return Colors.blue;
    case 'Yüksek':
      return Colors.orange;
    case 'Kritik':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String _maintenanceTypeText(String type) {
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

Widget _detailRow(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: FluentTheme.of(context).typography.caption,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: FluentTheme.of(context).typography.body,
          ),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

String _formatDateTime(DateTime dateTime) {
  final d = _formatDate(dateTime);
  final hh = dateTime.hour.toString().padLeft(2, '0');
  final mm = dateTime.minute.toString().padLeft(2, '0');
  return '$d $hh:$mm';
}

