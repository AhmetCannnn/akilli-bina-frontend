import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/issue_provider.dart';
import '../../../../features/buildings/presentation/providers/building_provider.dart';
import 'package:belediye_otomasyon/features/employees/data/services/employee_api_service.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart' show buildModalTitle, buildModalConstraints, showSuccessInfoBar, buildErrorCard, showDeleteDialog;
import 'package:belediye_otomasyon/core/utils/form_field_helpers.dart' show buildFormTextField, buildFormComboBox;
import 'package:belediye_otomasyon/core/utils/api_error.dart' show humanizeError;
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';
import 'package:belediye_otomasyon/core/widgets/app_scaffold_page.dart';
import 'package:belediye_otomasyon/core/widgets/entity_action_buttons.dart';
import 'package:belediye_otomasyon/core/widgets/entity_add_button.dart';
import '../../domain/models/issue.dart';
import 'report_issue_modal.dart';
import 'package:belediye_otomasyon/core/widgets/removable_tag.dart' show RemovableTag;

void openInterventionDetailModal(BuildContext context, Issue issue) {
  final theme = FluentTheme.of(context);
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => ContentDialog(
      constraints: buildModalConstraints(ctx, maxWidth: 520.0),
      title: buildModalTitle('Müdahale Detayı', ctx),
      content: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow(icon: FluentIcons.contact, label: 'Ekip/Kişi', value: issue.interventionAssignee ?? issue.assignedTo ?? '—'),
            const SizedBox(height: 8),
            _InfoRow(icon: FluentIcons.clock, label: 'Zaman', value: issue.interventionAt != null ? _formatDateTime(issue.interventionAt!) : '—'),
            const SizedBox(height: 8),
            _InfoRow(icon: FluentIcons.progress_ring_dots, label: 'Durum', value: issue.status.displayName),
            if (issue.resolvedAt != null) ...[
              const SizedBox(height: 8),
              _InfoRow(icon: FluentIcons.check_mark, label: 'Çözüm Zamanı', value: _formatDateTime(issue.resolvedAt!)),
            ],
            if (issue.status == IssueStatus.inProgress && issue.estimatedCost != null) ...[
              const SizedBox(height: 8),
              _InfoRow(icon: FluentIcons.calculator, label: 'Tahmini Maliyet', value: _formatCurrency(issue.estimatedCost!)),
            ],
            // Actual cost gösterimi: çözüldüyse veya değer mevcutsa göster
            if ((issue.status == IssueStatus.resolved || issue.actualCost != null) && issue.actualCost != null) ...[
              const SizedBox(height: 8),
              _InfoRow(icon: FluentIcons.money, label: 'Gerçekleşen Maliyet', value: _formatCurrency(issue.actualCost!)),
            ],
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(FluentIcons.edit, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    issue.interventionNote?.isNotEmpty == true ? issue.interventionNote! : '—',
                    style: theme.typography.body,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: null,
    ),
  );
}

class ActiveIssuesScreen extends ConsumerStatefulWidget {
  const ActiveIssuesScreen({super.key});

  @override
  ConsumerState<ActiveIssuesScreen> createState() => _ActiveIssuesScreenState();
}

class _ActiveIssuesScreenState extends ConsumerState<ActiveIssuesScreen> {
  String _selectedFilter = 'Tümü';
  final List<String> _filters = ['Tümü', 'Kritik', 'Yüksek', 'Orta', 'Düşük'];

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final issuesAsync = ref.watch(issueControllerProvider);
    final buildingsAsync = ref.watch(buildingControllerProvider);
    Map<int, String> buildingIdToName = {};
    Map<int, String> buildingIdToAddress = {};
    buildingsAsync.whenData((list) {
      for (final b in list) {
        final id = b['id'];
        if (id is int) {
          buildingIdToName[id] = (b['name'] ?? '').toString();
          buildingIdToAddress[id] = (b['address'] ?? '').toString();
        }
      }
    });

    final horizontalPad = PageHeader.horizontalPadding(context);
    return AppScaffoldPage(
      content: Container(
        color: theme.scaffoldBackgroundColor,
        padding: EdgeInsets.only(
          left: horizontalPad,
          right: horizontalPad,
          top: AppUiTokens.space8,
          bottom: AppUiTokens.space12,
        ),
        child: Column(
          children: [
            Expanded(
              child: issuesAsync.when(
                loading: () => const Center(child: ProgressRing()),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: buildErrorCard(theme, humanizeError(e)),
                ),
                data: (items) {
                  final apiIssues = _mapFromApi(items, buildingIdToName, buildingIdToAddress);
                  final filtered = _filteredIssuesOf(apiIssues);

                  return Column(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.filter,
                    color: theme.accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                            Text('Filtrele:', style: theme.typography.bodyStrong),
                  const SizedBox(width: 16),
                      SizedBox(
                        width: 140,
                        child: ComboBox<String>(
                      value: _selectedFilter,
                                items: _filters
                                    .map((f) => ComboBoxItem(value: f, child: Text(f)))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedFilter = v ?? _selectedFilter),
                    ),
                  ),
                  const Spacer(),
                  EntityAddButton(
                    label: 'Arıza Bildirimi Ekle',
                    tooltip: 'Arıza Bildirimi Ekle',
                    onPressed: () {
                      showReportIssueModal(context, ref);
                      ref.read(issueControllerProvider.notifier).refreshIssues();
                    },
                  ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Toplam Arıza',
                                apiIssues.length.toString(),
                      FluentIcons.report_hacked,
                      Colors.blue,
                      theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Kritik',
                                apiIssues.where((i) => i.priority == IssuePriority.critical).length.toString(),
                      FluentIcons.warning,
                      Colors.red,
                      theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Üzerine Çalışılıyor',
                                apiIssues.where((i) => i.status == IssueStatus.inProgress).length.toString(),
                      FluentIcons.progress_ring_dots,
                      (FluentTheme.of(context).brightness == Brightness.light)
                          ? const Color(0xFFFFC107)
                          : Colors.yellow,
                      theme,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
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
                                // Sidebar'daki \"Arızalar\" sekmesi ile aynı ikon
                                FluentIcons.warning,
                                size: 48,
                                color: theme.iconTheme.color?.withOpacity(0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Henüz arıza kaydı bulunmuyor',
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
                      padding: EdgeInsets.zero,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final issue = filtered[index];
                        return IssueCard(
                          issue: issue,
                          onEdit: () => openIssueEditUsingReportModal(context, ref, issue),
                          onAddIntervention: () => openInterventionModal(context, ref, issue, isEdit: true),
                          onDeleteIntervention: () {
                            final theme = FluentTheme.of(context);
                            showDeleteDialog(
                              context: context,
                              theme: theme,
                              title: 'Müdahaleyi Sil',
                              message: '"${issue.title}" için müdahale bilgilerini silmek istediğinize emin misiniz?',
                              onDelete: () async {
                                await ref.read(issueControllerProvider.notifier).updateIssue(
                                  issue.id,
                                  {
                                    'status': IssueStatus.pending.apiValue,
                                    'assigned_to': null,
                                    'intervention_assignee': null,
                                    'intervention_note': null,
                                    'intervention_at': null,
                                    'estimated_cost': null,
                                    'actual_cost': null,
                                    'resolved_at': null,
                                  },
                                );
                                return true;
                              },
                              successMessage: 'Müdahale bilgileri silindi.',
                              onSuccess: null,
                            );
                          },
                          onDelete: () {
                            final theme = FluentTheme.of(context);
                            showDeleteDialog(
                              context: context,
                              theme: theme,
                              title: 'Arızayı Sil',
                              message: '"${issue.title}" kaydını silmek istediğinize emin misiniz?',
                              onDelete: () async {
                                await ref.read(issueControllerProvider.notifier).deleteIssue(issue.id);
                                return true;
                              },
                              successMessage: '"${issue.title}" başarıyla silindi.',
                              onSuccess: null, // Provider zaten listeyi yeniliyor
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
                  );
                },
        ),
            ),
          ],
        ),
      ),
    );
  }

  List<Issue> _mapFromApi(List<Map<String, dynamic>> items, Map<int, String> nameMap, Map<int, String> addrMap) {
    return items.map((m) => Issue.fromJson(m, buildingNameMap: nameMap, buildingAddressMap: addrMap)).toList();
  }

  List<Issue> _filteredIssuesOf(List<Issue> source) {
    if (_selectedFilter == 'Tümü') return source;
    final key = _selectedFilter.toLowerCase();
    return source.where((i) => i.priority.name == key).toList();
  }

  Widget _buildStatCard(
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
}


void openIssueEditUsingReportModal(BuildContext context, WidgetRef ref, Issue issue) {
  final formKey = GlobalKey<FormState>();
  final modalKey = GlobalKey<ReportIssueModalState>();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ContentDialog(
      constraints: buildModalConstraints(ctx, maxWidth: 700.0),
      title: buildModalTitle('Arıza Düzenle', ctx),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: ReportIssueModal(
                key: modalKey,
                formKey: formKey,
                initialTitle: issue.title,
                initialDescription: issue.description,
                initialLocation: issue.buildingAddress,
                initialIssuePlace: issue.issuePlace ?? issue.location,
                initialPriority: issue.priority.displayName,
                initialCategory: issue.category,
                initialBuildingId: issue.buildingId?.toString(),
                initialBuildingName: issue.buildingName,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Button(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              const Spacer(),
              FilledButton(
                child: const Text('Güncelle'),
                onPressed: () async {
                  if (formKey.currentState == null || !formKey.currentState!.validate()) {
                    return;
                  }

                  final modalState = modalKey.currentState;
                  if (modalState == null) return;
                  
                  final formData = modalState.getFormData();
                  if (formData == null) return;

                  try {
                    await ref.read(issueControllerProvider.notifier).updateIssue(issue.id, formData);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      showSuccessInfoBar(context, 'Arıza bilgileri güncellendi.');
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      showDialog(
                        context: ctx,
                        builder: (errorCtx) => ContentDialog(
                          title: const Text('Hata'),
                          content: Text(humanizeError(e)),
                          actions: [
                            Button(
                              onPressed: () => Navigator.pop(errorCtx),
                              child: const Text('Tamam'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
      actions: null,
    ),
  );
}

// Helper: Maliyet string'ini double'a çevirir
double? _parseCost(String s) {
  final t = s.replaceAll('.', '').replaceAll(',', '.').trim();
  return double.tryParse(t);
}

void openInterventionModal(BuildContext context, WidgetRef ref, Issue issue, {bool isEdit = false}) {
  final theme = FluentTheme.of(context);
  final TextEditingController note = TextEditingController(text: isEdit ? (issue.interventionNote ?? '') : '');
  String? selectedEmployeeId = issue.assignedTo; // UUID string if present
  String? selectedEmployeeName = issue.interventionAssignee; // fallback display name
  final TextEditingController estimatedCostCtrl = TextEditingController();
  final TextEditingController actualCostCtrl = TextEditingController();
  // Başlangıç durumu: pending ise inProgress, diğer durumlarda mevcut durum
  IssueStatus sel = (issue.status == IssueStatus.pending) ? IssueStatus.inProgress : issue.status;
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => ContentDialog(
      constraints: buildModalConstraints(ctx, maxWidth: 700.0),
      title: buildModalTitle(isEdit ? 'Müdahaleyi Düzenle' : 'Müdahale Ekle', ctx),
      content: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: StatefulBuilder(
          builder: (ctx2, setState) {
            // Çalışanlar dropdown'u için bina ID gerekli
            if (issue.buildingId == null) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(FluentIcons.clock, size: 14),
                      const SizedBox(width: 6),
                      Text(_formatDateTime(DateTime.now()), style: theme.typography.caption),
                    ],
                  ),
                  const SizedBox(height: 8),
                  buildFormComboBox<IssueStatus>(
                    label: 'Durum',
                    value: sel,
                    items: const [IssueStatus.inProgress, IssueStatus.resolved],
                    displayText: (v) => v == IssueStatus.inProgress ? 'Üzerine Çalışılıyor' : 'Çözüldü',
                    onChanged: (v) => setState(() { sel = v ?? sel; }),
                  ),
                  const SizedBox(height: 8),
                  // Üzerine çalışılıyor: Tahmini maliyet
                  if (sel == IssueStatus.inProgress) ...[
                    buildFormTextField(
                      label: 'Tahmini Maliyet (₺)',
                      controller: estimatedCostCtrl,
                      placeholder: 'Örn: 750',
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Çözüldü: Gerçekleşen maliyet
                  if (sel == IssueStatus.resolved) ...[
                    buildFormTextField(
                      label: 'Gerçekleşen Maliyet (₺)',
                      controller: actualCostCtrl,
                      placeholder: 'Örn: 730',
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  InfoLabel(
                    label: 'Ekip veya kişi adı',
                    child: TextBox(
                      controller: TextEditingController(text: selectedEmployeeName ?? ''),
                      placeholder: 'Ekip veya kişi adı',
                      onChanged: (v) => setState(() { selectedEmployeeName = v; }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildFormTextField(
                    label: 'Kısa not',
                    controller: note,
                    placeholder: 'Kısa not (zorunlu değil, çözümde önerilir)',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Spacer(),
                      FilledButton(
                        child: const Text('Güncelle'),
                        onPressed: () async {
                          final nowIso = DateTime.now().toUtc().toIso8601String();
                          final isResolved = sel == IssueStatus.resolved;
                          final isInProgress = sel == IssueStatus.inProgress;
                          final update = <String, dynamic>{
                            'status': sel.apiValue,
                            'intervention_assignee': (selectedEmployeeName ?? '').trim().isEmpty ? null : selectedEmployeeName!.trim(),
                            'intervention_note': note.text.trim().isEmpty ? null : note.text.trim(),
                            'intervention_at': nowIso,
                            // set resolved_at only when resolved
                            if (isResolved) 'resolved_at': nowIso,
                            if (isInProgress && estimatedCostCtrl.text.trim().isNotEmpty)
                              'estimated_cost': _parseCost(estimatedCostCtrl.text),
                            if (isResolved && actualCostCtrl.text.trim().isNotEmpty)
                              'actual_cost': _parseCost(actualCostCtrl.text),
                          }..removeWhere((k, v) => v == null || (v is String && v.isEmpty));
                          await ref.read(issueControllerProvider.notifier).updateIssue(issue.id, update);
                          if (context.mounted) {
                            showSuccessInfoBar(context, 'Müdahale bilgileri güncellendi.');
                          }
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ],
              );
            }

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: EmployeeApiService().getEmployeesByBuildingId(issue.buildingId!),
              builder: (context, snapshot) {
                final employees = snapshot.data ?? [];
                // id -> name map
                final Map<String, String> idToName = {
                  for (final e in employees)
                    if (e['id'] != null) e['id'].toString(): (e['name'] ?? '').toString(),
                };
                // Preselect name if we have id
                if (selectedEmployeeId != null && selectedEmployeeName == null) {
                  selectedEmployeeName = idToName[selectedEmployeeId!];
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(FluentIcons.clock, size: 14),
                        const SizedBox(width: 6),
                        Text(_formatDateTime(DateTime.now()), style: theme.typography.caption),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: buildFormComboBox<IssueStatus>(
                            label: 'Durum',
                            value: sel,
                            items: const [IssueStatus.inProgress, IssueStatus.resolved],
                            displayText: (v) => v == IssueStatus.inProgress ? 'Üzerine Çalışılıyor' : 'Çözüldü',
                            onChanged: (v) => setState(() { sel = v ?? sel; }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Çalışan', style: theme.typography.bodyStrong),
                              const SizedBox(height: 6),
                              if (snapshot.connectionState == ConnectionState.waiting)
                                const ProgressRing()
                              else
                                ComboBox<String>(
                                  value: selectedEmployeeId,
                                  items: [
                                    ...idToName.entries.map((e) => ComboBoxItem<String>(value: e.key, child: Text(e.value)))
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      selectedEmployeeId = v;
                                      selectedEmployeeName = v != null ? idToName[v] : null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Üzerine çalışılıyor: Tahmini maliyet
                    if (sel == IssueStatus.inProgress) ...[
                      buildFormTextField(
                        label: 'Tahmini Maliyet (₺)',
                        controller: estimatedCostCtrl,
                        placeholder: 'Örn: 750',
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Çözüldü: Gerçekleşen maliyet
                    if (sel == IssueStatus.resolved) ...[
                      buildFormTextField(
                        label: 'Gerçekleşen Maliyet (₺)',
                        controller: actualCostCtrl,
                        placeholder: 'Örn: 730',
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
                    buildFormTextField(
                      label: 'Kısa not',
                      controller: note,
                      placeholder: 'Kısa not (zorunlu değil, çözümde önerilir)',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Spacer(),
                        FilledButton(
                          child: const Text('Güncelle'),
                          onPressed: () async {
                            final nowIso = DateTime.now().toUtc().toIso8601String();
                            final isResolved = sel == IssueStatus.resolved;
                            final isInProgress = sel == IssueStatus.inProgress;
                            final update = <String, dynamic>{
                              'status': sel.apiValue,
                              'assigned_to': selectedEmployeeId, // UUID
                              'intervention_assignee': selectedEmployeeName, // display name
                              'intervention_note': note.text.trim().isNotEmpty ? note.text.trim() : null,
                              'intervention_at': nowIso,
                              if (isResolved) 'resolved_at': nowIso,
                              if (isInProgress && estimatedCostCtrl.text.trim().isNotEmpty)
                                'estimated_cost': _parseCost(estimatedCostCtrl.text),
                              if (isResolved && actualCostCtrl.text.trim().isNotEmpty)
                                'actual_cost': _parseCost(actualCostCtrl.text),
                            }..removeWhere((k, v) => v == null || (v is String && v.isEmpty));
                          await ref.read(issueControllerProvider.notifier).updateIssue(issue.id, update);
                          if (context.mounted) {
                            showSuccessInfoBar(context, 'Müdahale bilgileri güncellendi.');
                          }
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      actions: null,
    ),
  );
}


String _formatDateTime(DateTime date) {
  final d = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  final t = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  return '$d $t';
}

String _formatCurrency(double value) {
  try {
    return '${value.toStringAsFixed(2)} ₺';
  } catch (_) {
    return '$value ₺';
  }
}

void showIssueDetailModal(BuildContext context, Issue issue) {
  final theme = FluentTheme.of(context);
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => ContentDialog(
      constraints: buildModalConstraints(ctx, maxWidth: 820.0),
      title: buildModalTitle('Arıza Detayı', ctx),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Üst satır: ID + durum + öncelik
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  RemovableTag(label: issue.id, color: theme.accentColor),
                  if (issue.buildingName != null)
                    RemovableTag(label: issue.buildingName!, color: Colors.blue),
                  RemovableTag(label: issue.status.displayName, color: issue.status.color),
                  RemovableTag(label: issue.priority.displayName, color: issue.priority.color),
                ],
              ),
              const SizedBox(height: 12),
              // Başlık
              Text(issue.title, style: theme.typography.title?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Açıklama
              if (issue.description.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      issue.description,
                      style: theme.typography.body,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              // Bilgi çiftleri
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _InfoRow(icon: FluentIcons.location, label: 'Konum', value: (issue.buildingAddress ?? '-')),
                      const SizedBox(height: 8),
                      _InfoRow(icon: FluentIcons.poi, label: 'Arıza Yeri', value: (issue.issuePlace ?? issue.location)),
                      const SizedBox(height: 8),
                      _InfoRow(icon: FluentIcons.tag, label: 'Kategori', value: issue.category),
                      const SizedBox(height: 8),
                      _InfoRow(icon: FluentIcons.clock, label: 'Rapor Zamanı', value: _formatDateTime(issue.reportDate)),
                      if (issue.reporterName != null || issue.reporterPhone != null || issue.reporterEmail != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: FluentIcons.contact,
                          label: 'Raporlayan',
                          value: [
                            if (issue.reporterName != null) issue.reporterName!,
                            if (issue.reporterPhone != null) issue.reporterPhone!,
                            if (issue.reporterEmail != null) issue.reporterEmail!,
                          ].where((e) => e.isNotEmpty).join(' • '),
                        ),
                      ],
                      if (issue.assignedTo != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(icon: FluentIcons.contact, label: 'Atanan', value: issue.assignedTo!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: null,
    ),
  );
}


class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.iconTheme.color?.withOpacity(0.8)),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Text(label, style: theme.typography.caption?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.body,
          ),
        ),
      ],
    );
  }
}

class IssueCard extends StatelessWidget {
  const IssueCard({
    super.key,
    required this.issue,
    required this.onEdit,
    required this.onAddIntervention,
    required this.onDeleteIntervention,
    required this.onDelete,
  });

  final Issue issue;
  final VoidCallback onEdit;
  final VoidCallback onAddIntervention;
  final VoidCallback onDeleteIntervention;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        RemovableTag(label: issue.priority.displayName, color: issue.priority.color),
                        RemovableTag(label: issue.status.displayName, color: issue.status.color),
                        RemovableTag(label: issue.id, color: issue.priority.color),
                        if ((issue.buildingName ?? '').isNotEmpty)
                          RemovableTag(label: issue.buildingName!, color: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            issue.title,
                            style: theme.typography.bodyStrong?.copyWith(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      issue.description,
                      style: theme.typography.body?.copyWith(
                        color: theme.typography.body?.color?.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(FluentIcons.location, size: 16, color: theme.iconTheme.color?.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text(
                          issue.location,
                          style: theme.typography.caption?.copyWith(
                            color: theme.typography.caption?.color?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(FluentIcons.tag, size: 16, color: theme.iconTheme.color?.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text(
                          issue.category,
                          style: theme.typography.caption?.copyWith(
                            color: theme.typography.caption?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(FluentIcons.clock, size: 16, color: theme.iconTheme.color?.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(issue.reportDate),
                          style: theme.typography.caption?.copyWith(
                            color: theme.typography.caption?.color?.withOpacity(0.7),
                          ),
                        ),
                        if (issue.assignedTo != null) ...[
                          const SizedBox(width: 16),
                          Icon(FluentIcons.contact, size: 16, color: theme.iconTheme.color?.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            issue.assignedTo!,
                            style: theme.typography.caption?.copyWith(
                              color: theme.typography.caption?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    EntityActionButtons(
                      onEdit: onEdit,
                      onDelete: onDelete,
                      onDetail: () => showIssueDetailModal(context, issue),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 280,
                child: Builder(
                  builder: (ctx) {
                    final isSummary = issue.status == IssueStatus.inProgress || issue.status == IssueStatus.resolved;
                    if (isSummary) {
                      return Card(
          child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Müdahale Özeti', style: theme.typography.bodyStrong),
                              const SizedBox(height: 8),
                              Row(children: [
                                const Icon(FluentIcons.contact, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    issue.interventionAssignee ?? issue.assignedTo ?? 'Atama yok',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.typography.caption,
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(FluentIcons.clock, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  issue.interventionAt != null ? _formatDateTime(issue.interventionAt!) : '—',
                                  style: theme.typography.caption,
                                ),
                              ]),
                              const SizedBox(height: 6),
                              if ((issue.interventionNote ?? '').isNotEmpty)
                                Text(issue.interventionNote!, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.typography.body),
                              const SizedBox(height: 8),
                              EntityActionButtons(
                                onEdit: onAddIntervention,
                                onDelete: onDeleteIntervention,
                                onDetail: () => openInterventionDetailModal(context, issue),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Müdahale', style: theme.typography.bodyStrong),
                            const SizedBox(height: 8),
                            Text('Bu arıza için henüz müdahale bilgisi yok.', style: theme.typography.caption),
                            const SizedBox(height: 8),
                            FilledButton(onPressed: onAddIntervention, child: const Text('Müdahale Ekle')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inDays > 0) return '${difference.inDays} gün önce';
  if (difference.inHours > 0) return '${difference.inHours} saat önce';
  if (difference.inMinutes > 0) return '${difference.inMinutes} dakika önce';
  return 'Şimdi';
}

void showReportIssueModal(
  BuildContext context,
  WidgetRef ref, {
  String? initialBuildingId,
  String? initialBuildingName,
}) {
  final formKey = GlobalKey<FormState>();
  final modalKey = GlobalKey<ReportIssueModalState>();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ContentDialog(
      constraints: buildModalConstraints(ctx, maxWidth: 700.0),
      title: buildModalTitle('Arıza Bildirimi Ekle', ctx),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: ReportIssueModal(
                key: modalKey,
                formKey: formKey,
                initialBuildingId: initialBuildingId,
                initialBuildingName: initialBuildingName,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Button(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              const Spacer(),
              FilledButton(
                child: const Text('Kaydet'),
                onPressed: () async {
                  // Formu doğrula
                  if (formKey.currentState == null || !formKey.currentState!.validate()) {
                    return;
                  }

                  // Modal'dan verileri al
                  final modalState = modalKey.currentState;
                  if (modalState == null) return;
                  
                  final result = modalState.getFormData();
                  if (result == null) {
                    // Validasyon başarısız olduysa veya bina seçilmediyse
                    return;
                  }

                  try {
                    await ref.read(issueControllerProvider.notifier).createIssue(result);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      showSuccessInfoBar(context, 'Arıza kaydı başarıyla oluşturuldu.');
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      showDialog(
                        context: ctx,
                        builder: (errorCtx) => ContentDialog(
                          title: const Text('Hata'),
                          content: Text(humanizeError(e)),
                          actions: [
                            Button(
                              onPressed: () => Navigator.pop(errorCtx),
                              child: const Text('Tamam'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
      actions: null,
    ),
  );
}

