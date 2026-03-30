import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_maintenance_modal.dart';
import '../providers/maintenance_provider.dart';
import '../../data/services/maintenance_api_service.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart'
    show
        showDeleteDialog,
        buildModalTitle,
        buildModalConstraints,
        showErrorDialog,
        showSuccessInfoBar,
        buildErrorCard;
import '../../../../core/utils/api_error.dart';
import '../../../../core/utils/backend_datetime.dart';
import '../../../../features/buildings/presentation/providers/building_provider.dart';
import 'package:belediye_otomasyon/core/widgets/removable_tag.dart'
    show RemovableTag;

class MaintenanceSuggestionsScreen extends ConsumerStatefulWidget {
  const MaintenanceSuggestionsScreen({super.key});

  @override
  ConsumerState<MaintenanceSuggestionsScreen> createState() => _MaintenanceSuggestionsScreenState();
}

class _MaintenanceSuggestionsScreenState extends ConsumerState<MaintenanceSuggestionsScreen> {
  String _selectedFilter = 'Tümü';
  final List<String> _filters = ['Tümü', 'Taslak', 'Planlandı', 'Tamamlandı'];

  List<Map<String, dynamic>> _getFilteredMaintenance(List<Map<String, dynamic>> allMaintenance) {
    if (_selectedFilter == 'Tümü') {
      return allMaintenance;
    }
    
    return allMaintenance.where((m) {
      switch (_selectedFilter) {
        case 'Taslak':
          return m['status'] == 'taslak';
        case 'Planlandı':
          return m['status'] == 'planlandı';
        case 'Tamamlandı':
          return m['status'] == 'tamamlandı';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final maintenanceAsync = ref.watch(allMaintenanceProvider);

    return ScaffoldPage(
      content: Container(
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            // Başlık AppShell içinde yönetiliyor
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  // Filtre ve Bakım Ekle Butonu
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          FluentIcons.filter,
                          color: theme.accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filtrele:',
                          style: theme.typography.bodyStrong,
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 140,
                          child: ComboBox<String>(
                            value: _selectedFilter,
                            items: _filters.map((filter) {
                              return ComboBoxItem(
                                value: filter,
                                child: Text(filter),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedFilter = value;
                                });
                              }
                            },
                          ),
                        ),
                        const Spacer(),
                        Tooltip(
                          message: 'Bakım Ekle',
                          child: FilledButton(
                            child: Row(
                              children: const [
                                Icon(FluentIcons.add, size: 14),
                                SizedBox(width: 6),
                                Text('Bakım Ekle'),
                              ],
                            ),
                            onPressed: () {
                              _showAddMaintenanceModal(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Özet Kartları ve Bakım Listesi
                  maintenanceAsync.when(
                    data: (allMaintenance) {
                      final filtered = _getFilteredMaintenance(allMaintenance);
                      
                      return Expanded(
                        child: Column(
                          children: [
                            // Özet Kartları
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryCard(
                                      'Toplam Bakım',
                                      allMaintenance.length.toString(),
                                      FluentIcons.settings,
                                      Colors.blue,
                                      theme,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSummaryCard(
                                      'Kritik',
                                      allMaintenance
                                          .where((m) =>
                                              m['priority']?.toString() ==
                                              'Kritik')
                                          .length
                                          .toString(),
                                      FluentIcons.warning,
                                      Colors.red,
                                      theme,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSummaryCard(
                                      'Planlandı',
                                      allMaintenance.where((m) => m['status'] == 'scheduled').length.toString(),
                                      FluentIcons.calendar,
                                      Colors.green,
                                      theme,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Bakım Kayıtları Listesi
                            Expanded(
                              child: filtered.isEmpty
                                  ? Center(
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                // Sidebar'daki \"Bakımlar\" ikonu ile tutarlı olsun
                                                FluentIcons.build_definition,
                                                size: 48,
                                                color: theme.iconTheme.color?.withOpacity(0.5),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Henüz bakım kaydı bulunmuyor',
                                                style: theme.typography.body?.copyWith(
                                                  color: theme.iconTheme.color?.withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final maintenance = filtered[index];
                                        return _MaintenanceRecordCard(
                                          maintenance: maintenance,
                                          onViewDetails: () => _viewMaintenanceDetails(maintenance),
                                          onEdit: () => _showEditMaintenanceModal(context, maintenance),
                                          onDelete: () => _showDeleteMaintenanceDialog(context, maintenance),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Expanded(
                      child: Center(child: ProgressRing()),
                    ),
                    error: (error, stack) => Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              buildErrorCard(theme, humanizeError(error)),
                              const SizedBox(height: 8),
                              Button(
                                child: const Text('Tekrar Dene'),
                                onPressed: () =>
                                    ref.invalidate(allMaintenanceProvider),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    FluentThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.typography.title?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: theme.typography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _viewMaintenanceDetails(Map<String, dynamic> maintenance) {
    final theme = FluentTheme.of(context);
    final title = maintenance['title'] ?? 'Bakım Kaydı';
    final description = maintenance['description'] ?? '';
    final status = maintenance['status'] ?? 'scheduled';
    final maintenanceType = maintenance['maintenance_type'] ?? '';
    final String locText = maintenance['location']?.toString() ?? '';
    final cost = maintenance['cost'];
    final priority = maintenance['priority']?.toString() ?? '';
    final categoryStr = maintenance['category']?.toString() ?? '';
    final scheduledDate = maintenance['scheduled_date'] != null
        ? parseBackendDateTime(maintenance['scheduled_date'].toString())
        : null;
    final completedDate = maintenance['completed_date'] != null
        ? parseBackendDateTime(maintenance['completed_date'].toString())
        : null;
    final createdAt = maintenance['created_at'] != null
        ? parseBackendDateTime(maintenance['created_at'].toString())
        : null;
    final updatedAt = maintenance['updated_at'] != null
        ? parseBackendDateTime(maintenance['updated_at'].toString())
        : null;
    final buildingId = maintenance['building_id'];
    final id = maintenance['id']?.toString() ?? '';
    final performedBy = maintenance['performed_by']?.toString() ?? '';
    final notes = maintenance['notes']?.toString() ?? '';
    final isDeleted = maintenance['is_deleted'] == true;

    // Resolve building name from provider if available
    String? buildingName;
    String? buildingAddress;
    // Initial try (may be null until provider resolves)
    final buildingsSnapshot = ref.read(buildingControllerProvider);
    if (buildingsSnapshot.hasValue) {
      final list = buildingsSnapshot.value ?? [];
      final match = list.firstWhere(
        (b) => b['id'] == buildingId,
        orElse: () => {},
      );
      if (match is Map<String, dynamic>) {
        buildingName = (match['name'] ?? '').toString();
        buildingAddress = (match['address'] ?? '').toString();
      }
    }
    
    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        constraints: buildModalConstraints(ctx, maxWidth: 820.0),
        title: buildModalTitle(title, ctx),
        content: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Üst chipler: durum, öncelik, kategori ve bina adı
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  RemovableTag(label: _getStatusText(status), color: _getStatusColor(status)),
                  if (priority.isNotEmpty)
                    RemovableTag(label: priority, color: _getPriorityColor(priority)),
                  if (categoryStr.isNotEmpty)
                    RemovableTag(label: categoryStr, color: Colors.blue),
                  if (buildingId != null)
                    Consumer(
                      builder: (context, ref, _) {
                        final buildingsAsync = ref.watch(buildingControllerProvider);
                        String label = buildingName ?? '-';
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
              const SizedBox(height: 12),
              // Detaylar
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Başlık', title),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Açıklama', description),
                      ],
                      if ((buildingAddress ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Bina Konumu', buildingAddress!),
                      ],
                      if (locText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Bakım Yeri', locText),
                      ],
                      if (maintenanceType.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Bakım Türü', _getMaintenanceTypeText(maintenanceType)),
                      ],
                      if (scheduledDate != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Planlanan Tarih', _formatDate(scheduledDate)),
                      ],
                      if (completedDate != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Tamamlanma Tarihi', _formatDate(completedDate)),
                      ],
                      if (cost != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Maliyet', '₺${(cost is num ? cost : double.parse(cost.toString())).toStringAsFixed(0)}'),
                      ],
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Notlar', notes),
                      ],
                      if (performedBy.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Yapan (UUID)', performedBy),
                      ],
                      if (createdAt != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Oluşturma', _formatDateTime(createdAt)),
                      ],
                      if (updatedAt != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Güncelleme', _formatDateTime(updatedAt)),
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

  String _getStatusText(String status) {
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

  Color _getStatusColor(String status) {
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

  String _getMaintenanceTypeText(String type) {
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


  Widget _buildDetailRow(String label, String value) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final d = _formatDate(dateTime);
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$d $hh:$mm';
  }

  Color _getPriorityColor(String priority) {
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

  void _showEditMaintenanceModal(BuildContext context, Map<String, dynamic> maintenance) {
    final formKey = GlobalKey<FormState>();
    final maintenanceId = maintenance['id'] as String;
    // Create a GlobalKey to access the modal's state - must be outside StatefulBuilder
    final modalStateKey = GlobalKey<AddMaintenanceModalState>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = FluentTheme.of(ctx);
        return ContentDialog(
          constraints: buildModalConstraints(ctx, maxWidth: 700.0),
          title: buildModalTitle('Bakım Düzenle', ctx),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: AddMaintenanceModal(
                    key: modalStateKey,
                    formKey: formKey,
                    maintenance: maintenance,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  FilledButton(
                    child: const Text('Güncelle'),
                    onPressed: () async {
                      final form = formKey.currentState;
                      if (form == null) return;
                      if (!form.validate()) return;
                      
                      // Get form data from modal state
                      final modalState = modalStateKey.currentState;
                      if (modalState == null) return;
                      
                      final formData = modalState.getFormData();
                      if (formData == null) return;
                      
                      try {
                        await ref
                            .read(maintenanceControllerProvider.notifier)
                            .updateMaintenance(maintenanceId, formData);
                        if (ctx.mounted) {
                          Navigator.pop(ctx, true);
                        }
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
    ).then((_) {
      if (context.mounted) {
        showSuccessInfoBar(context, 'Bakım güncellendi.');
      }
    });
  }

  void _showDeleteMaintenanceDialog(BuildContext context, Map<String, dynamic> maintenance) {
    final theme = FluentTheme.of(context);
    final maintenanceId = maintenance['id'] as String;
    final title = maintenance['title'] ?? 'Bakım Kaydı';
    
    showDeleteDialog(
      context: context,
      theme: theme,
      title: 'Bakım Kaydını Sil',
      message: '"$title" kaydını silmek istediğinize emin misiniz?',
      onDelete: () async {
        final success = await MaintenanceApiService().deleteMaintenance(maintenanceId);
        return success;
      },
      successMessage: '"$title" başarıyla silindi.',
      onSuccess: () {
        // Refresh maintenance list
        ref.invalidate(allMaintenanceProvider);
      },
    );
  }

  void _showAddMaintenanceModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    // Create a GlobalKey to access the modal's state
    final modalStateKey = GlobalKey<AddMaintenanceModalState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = FluentTheme.of(ctx);
        return ContentDialog(
          constraints: buildModalConstraints(ctx, maxWidth: 700.0),
          title: buildModalTitle('Bakım Ekle', ctx),
          content: StatefulBuilder(
            builder: (ctx2, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: AddMaintenanceModal(
                        key: modalStateKey,
                        formKey: formKey,
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
                          if (form == null) return;
                          if (!form.validate()) return;
                          // Get form data from modal
                          final modalState = modalStateKey.currentState;
                          if (modalState == null) return;
                          final formData = modalState.getFormData();
                          if (formData == null) return;

                          try {
                            await ref
                                .read(maintenanceControllerProvider.notifier)
                                .createMaintenance(formData);
                            if (ctx.mounted) {
                              Navigator.pop(ctx, true);
                            }
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
              );
            },
          ),
          actions: null,
        );
      },
    ).then((result) {
      if (context.mounted && result == true) {
        showSuccessInfoBar(context, 'Bakım eklendi.');
      }
    });
  }
}

class _MaintenanceRecordCard extends StatelessWidget {
  const _MaintenanceRecordCard({
    required this.maintenance,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> maintenance;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _getStatusText(String status) {
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

  Color _getStatusColor(String status) {
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

  String _getMaintenanceTypeText(String type) {
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

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final title = maintenance['title'] ?? 'Bakım Kaydı';
    final description = maintenance['description'] ?? '';
    final status = maintenance['status'] ?? 'scheduled';
    final maintenanceType = maintenance['maintenance_type'] ?? '';
    final String locText = maintenance['location']?.toString() ?? '';
    final cost = maintenance['cost'];
    final scheduledDate = maintenance['scheduled_date'] != null
        ? parseBackendDateTime(maintenance['scheduled_date'].toString())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve etiket aynı satırda hizalı
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.typography.bodyStrong?.copyWith(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  RemovableTag(label: _getStatusText(status), color: _getStatusColor(status)),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.typography.body?.copyWith(
                    color: theme.typography.body?.color?.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (locText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(FluentIcons.map_pin, size: 14, color: theme.iconTheme.color?.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locText,
                        style: theme.typography.caption?.copyWith(
                          color: theme.typography.caption?.color?.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              
              Row(
                children: [
                  if (scheduledDate != null) ...[
                    Icon(
                      FluentIcons.calendar,
                      size: 16,
                      color: theme.iconTheme.color?.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}',
                      style: theme.typography.caption?.copyWith(
                        color: theme.typography.caption?.color?.withOpacity(0.7),
                      ),
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
                  Button(
                    onPressed: onViewDetails,
                    child: const Text('Detay'),
                  ),
                  const SizedBox(width: 8),
                  Button(
                    onPressed: onEdit,
                    child: const Text('Düzenle'),
                  ),
                  const SizedBox(width: 8),
                  Button(
                    onPressed: onDelete,
                    child: const Text('Sil'),
                    style: ButtonStyle(
                      backgroundColor: ButtonState.all(Colors.red),
                      foregroundColor: ButtonState.all(Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}



