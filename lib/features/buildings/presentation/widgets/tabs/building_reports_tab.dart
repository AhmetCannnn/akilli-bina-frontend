import 'package:fluent_ui/fluent_ui.dart';
import 'package:belediye_otomasyon/core/services/api_service.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';
import 'package:belediye_otomasyon/core/widgets/entity_add_button.dart';
import 'package:belediye_otomasyon/core/widgets/entity_action_buttons.dart';
import 'package:belediye_otomasyon/core/widgets/entity_list_card.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart'
    show
        buildModalTitle,
        buildModalConstraints,
        showErrorInfoBar,
        showDeleteDialog;
import 'package:belediye_otomasyon/features/reports/presentation/screens/add_report_modal.dart';
import 'package:belediye_otomasyon/features/reports/presentation/screens/reports_screen.dart'
    show Report, ReportStatus;
import 'package:url_launcher/url_launcher.dart';

/// Bina detayında: yalnızca bu binaya bağlı raporlar (`GET /reports?building_id=`).
class BuildingReportsTab extends StatefulWidget {
  const BuildingReportsTab({required this.building, super.key});

  final Map<String, dynamic> building;

  @override
  State<BuildingReportsTab> createState() => _BuildingReportsTabState();
}

class _BuildingReportsTabState extends State<BuildingReportsTab> {
  final ApiService _api = ApiService();
  final List<Report> _reports = [];
  bool _loading = true;
  String? _error;

  int get _buildingId => widget.building['id'] as int;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.get(
        '/reports',
        queryParameters: {'building_id': _buildingId, 'limit': 100, 'offset': 0},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['items'] is List) {
        final items = (data['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(Report.fromApi)
            .toList();
        if (mounted) {
          setState(() {
            _reports
              ..clear()
              ..addAll(items);
          });
        }
      } else if (mounted) {
        setState(() => _error = 'Beklenmeyen veri formatı.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFile(Report report) async {
    if (report.status != ReportStatus.completed ||
        report.fileUrl == null ||
        report.fileUrl!.isEmpty) {
      displayInfoBar(
        context,
        builder: (c, close) => InfoBar(
          title: const Text('Uyarı'),
          content: const Text('Rapor henüz tamamlanmadı veya dosya eklenmemiş.'),
          severity: InfoBarSeverity.warning,
          onClose: close,
        ),
      );
      return;
    }
    final url = Uri.parse('${ApiService.baseUrl}${report.fileUrl}');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        showErrorInfoBar(context, 'Rapor açılırken bir sorun oluştu.');
      }
    } catch (e) {
      if (mounted) showErrorInfoBar(context, 'Rapor açılırken hata: $e');
    }
  }

  Future<void> _editReport(Report report) async {
    final modalKey = GlobalKey<CreateReportModalState>();
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return ContentDialog(
          constraints: buildModalConstraints(ctx, maxWidth: 700.0),
          title: buildModalTitle('Raporu Düzenle', ctx),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: CreateReportModal(
                    key: modalKey,
                    initialReport: report,
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
                    onPressed: () => modalKey.currentState?.submit(),
                    child: const Text('Raporu Güncelle'),
                  ),
                ],
              ),
            ],
          ),
          actions: null,
        );
      },
    );
    if (updated == true) await _load();
  }

  void _details(Report report) {
    final theme = FluentTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        constraints: buildModalConstraints(ctx, maxWidth: 720.0),
        title: buildModalTitle('Rapor Detayı', ctx),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(report.title, style: theme.typography.subtitle?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (report.description.isNotEmpty) Text(report.description, style: theme.typography.body),
              const SizedBox(height: 8),
              Text(
                'Durum: ${report.status.displayName}',
                style: theme.typography.caption,
              ),
              if (report.fileUrl != null && report.fileUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Dosya: ${report.fileUrl}', style: theme.typography.caption),
              ],
            ],
          ),
        ),
        actions: null,
      ),
    );
  }

  void _deleteReport(Report report) {
    final theme = FluentTheme.of(context);
    showDeleteDialog(
      context: context,
      theme: theme,
      title: 'Raporu Sil',
      message: '${report.title} raporunu silmek istediğinizden emin misiniz?',
      onDelete: () async {
        try {
          await _api.delete('/reports/${report.id}');
          await _load();
          return true;
        } catch (e) {
          if (mounted) showErrorInfoBar(context, 'Rapor silinirken hata: $e');
          return false;
        }
      },
      successMessage: 'Rapor silindi.',
    );
  }

  Future<void> _addReport() async {
    final modalKey = GlobalKey<CreateReportModalState>();
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return ContentDialog(
          constraints: buildModalConstraints(ctx, maxWidth: 700.0),
          title: buildModalTitle('Yeni Rapor', ctx),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: CreateReportModal(
                    key: modalKey,
                    initialBuildingId: _buildingId,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Button(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => modalKey.currentState?.submit(),
                    child: const Text('Rapor Oluştur'),
                  ),
                ],
              ),
            ],
          ),
          actions: null,
        );
      },
    );
    if (created == true) await _load();
  }

  String _shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Widget _buildReportListCard(Report report) {
    return EntityListCard(
      margin: const EdgeInsets.only(bottom: 10),
      header: EntityListCardHeaderRow(
        leading: EntityListCardLeadingIconBox(
          icon: report.category.icon,
          color: report.category.color,
        ),
        title: report.title,
        subtitle: report.category.displayName,
        trailing: EntityListCardHeaderPill(
          label: report.status.displayName,
          color: report.status.color,
        ),
      ),
      description: report.description,
      descriptionMaxLines: 2,
      footer: Row(
        children: [
          EntityListCardMetaIconText(
            icon: FluentIcons.contact,
            text: report.createdByName ?? report.createdBy,
          ),
          const SizedBox(width: 16),
          EntityListCardMetaIconText(
            icon: FluentIcons.clock,
            text: _shortDate(report.createdDate),
          ),
          const Spacer(),
          EntityActionButtons(
            width: report.status == ReportStatus.completed ? 280 : 170,
            primaryLabel:
                report.status == ReportStatus.completed ? 'Raporu Aç' : null,
            onPrimary: report.status == ReportStatus.completed
                ? () => _openFile(report)
                : null,
            onEdit: () => _editReport(report),
            onDelete: () => _deleteReport(report),
            onDetail: () => _details(report),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppUiTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  border: Border.all(color: theme.accentColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.analytics_report, size: AppUiTokens.iconMd, color: theme.accentColor),
                    const SizedBox(width: AppUiTokens.space4),
                    Text(
                      '${_reports.length}',
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
                label: 'Rapor Ekle',
                onPressed: _addReport,
                size: AppControlSize.sm,
              ),
            ],
          ),
          const SizedBox(height: AppUiTokens.space12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: ProgressRing()))
          else if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppUiTokens.space24),
                child: Text(_error!, style: theme.typography.body?.copyWith(color: Colors.red)),
              ),
            )
          else if (_reports.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppUiTokens.space24),
                child: Column(
                  children: [
                    Icon(FluentIcons.analytics_report, size: 48, color: theme.iconTheme.color?.withOpacity(0.5)),
                    const SizedBox(height: AppUiTokens.space12),
                    Text(
                      'Bu bina için rapor kaydı yok',
                      style: theme.typography.body?.copyWith(color: theme.iconTheme.color?.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._reports.map(_buildReportListCard),
        ],
      ),
    );
  }
}
