import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:belediye_otomasyon/core/widgets/entity_add_button.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart'
    show
        buildModalConstraints,
        buildModalTitle,
        showErrorDialog,
        showSuccessInfoBar;
import '../../../../maintenance/presentation/providers/maintenance_provider.dart';
import '../../../../maintenance/presentation/utils/maintenance_dialog_helpers.dart';
import '../../../../maintenance/presentation/screens/add_maintenance_modal.dart';
import '../../../../maintenance/presentation/widgets/maintenance_entity_list_card.dart';
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
            data: (maintenanceList) => Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppUiTokens.space12,
                        vertical: AppUiTokens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppUiTokens.radius12),
                        border:
                            Border.all(color: theme.accentColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FluentIcons.build_definition,
                            size: AppUiTokens.iconMd,
                            color: theme.accentColor,
                          ),
                          const SizedBox(width: AppUiTokens.space4),
                          Text(
                            '${maintenanceList.length}',
                            style: theme.typography.caption?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    EntityAddButton(
                      label: 'Bakım Ekle',
                      tooltip: 'Bu binaya bakım kaydı ekle',
                      onPressed: () =>
                          _showAddMaintenanceModal(context, ref, buildingId),
                      size: AppControlSize.sm,
                    ),
                  ],
                ),
                const SizedBox(height: AppUiTokens.space12),
                _MaintenanceList(maintenanceList: maintenanceList),
              ],
            ),
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

class _MaintenanceList extends ConsumerWidget {
  const _MaintenanceList({required this.maintenanceList});

  final List<Map<String, dynamic>> maintenanceList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);

    if (maintenanceList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppUiTokens.space24),
          child: Column(
            children: [
              Icon(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final maintenance in maintenanceList)
          MaintenanceEntityListCard(
            maintenance: maintenance,
            onEdit: () => showEditMaintenanceDialog(
              ref: ref,
              context: context,
              maintenance: maintenance,
            ),
            onDelete: () => showDeleteMaintenanceDialog(
              ref: ref,
              context: context,
              maintenance: maintenance,
            ),
            onDetail: () => _openMaintenanceDetailModal(context, maintenance),
          ),
      ],
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
                          final nm = (match['name'] ?? '').toString();
                          if (nm.isNotEmpty) label = nm;
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

void _showAddMaintenanceModal(
  BuildContext context,
  WidgetRef ref,
  int buildingId,
) {
  final formKey = GlobalKey<FormState>();
  final modalStateKey = GlobalKey<AddMaintenanceModalState>();

  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = FluentTheme.of(ctx);
      return ContentDialog(
        constraints: buildModalConstraints(ctx, maxWidth: 700.0),
        title: buildModalTitle('Bakım Ekle', ctx),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: AddMaintenanceModal(
                  key: modalStateKey,
                  formKey: formKey,
                  maintenance: {'building_id': buildingId},
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                FilledButton(
                  child: const Text('Kaydet'),
                  onPressed: () async {
                    final form = formKey.currentState;
                    if (form == null || !form.validate()) return;

                    final modalState = modalStateKey.currentState;
                    if (modalState == null) return;

                    final formData = modalState.getFormData();
                    if (formData == null) return;

                    try {
                      await ref
                          .read(maintenanceControllerProvider.notifier)
                          .createMaintenance(formData);
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      final errorMessage =
                          e.toString().replaceFirst('Exception: ', '');
                      showErrorDialog(ctx, theme, 'Hata', errorMessage);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: null,
      );
    },
  ).then((isSaved) {
    if (context.mounted && isSaved == true) {
      showSuccessInfoBar(context, 'Bakım eklendi.');
    }
  });
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

