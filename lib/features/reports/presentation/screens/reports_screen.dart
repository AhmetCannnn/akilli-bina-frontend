import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'add_report_modal.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart'
    show
        buildModalTitle,
        buildModalConstraints,
        showSuccessInfoBar,
        showErrorInfoBar,
        showDeleteDialog;
import 'package:belediye_otomasyon/core/services/api_service.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';
import 'package:belediye_otomasyon/core/widgets/app_scaffold_page.dart';
import 'package:belediye_otomasyon/core/widgets/entity_action_buttons.dart';
import 'package:belediye_otomasyon/core/widgets/entity_add_button.dart';
import 'package:belediye_otomasyon/core/widgets/entity_list_card.dart';
import 'package:belediye_otomasyon/core/widgets/entity_tag.dart';
import 'package:belediye_otomasyon/core/utils/backend_datetime.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _api = ApiService();
  final List<Report> _reports = [];

  bool _isLoading = false;
  String? _errorMessage;

  String _selectedFilter = 'Tümü';
  final List<String> _filters = ['Tümü', 'Tamamlandı', 'İşleniyor', 'Beklemede'];

  List<Report> get _filteredReports {
    if (_selectedFilter == 'Tümü') {
      return _reports;
    }
    
    ReportStatus? filterStatus;
    switch (_selectedFilter) {
      case 'Tamamlandı':
        filterStatus = ReportStatus.completed;
        break;
      case 'İşleniyor':
        filterStatus = ReportStatus.processing;
        break;
      case 'Beklemede':
        filterStatus = ReportStatus.pending;
        break;
    }
    
    return _reports.where((report) => report.status == filterStatus).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.get('/reports');
      final data = response.data;

      if (data is Map<String, dynamic> && data['items'] is List) {
        final items = (data['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(Report.fromApi)
            .toList();

        setState(() {
          _reports
            ..clear()
            ..addAll(items);
        });
      } else {
        setState(() {
          _errorMessage = 'Beklenmeyen veri formatı alındı.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Raporlar yüklenirken hata oluştu: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
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
              child: Column(
          children: [
            // Filtre ve İstatistik Bölümü
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // Filtre
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
                          border: Border.all(
                            color: theme.accentColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FluentIcons.analytics_report,
                              size: AppUiTokens.iconMd,
                              color: theme.accentColor,
                            ),
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
                      const SizedBox(width: AppUiTokens.space8),
                      Expanded(
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
                            EntityAddButton(
                              label: 'Rapor Ekle',
                              tooltip: 'Rapor Ekle',
                              onPressed: () async {
                                final created = await _showCreateReportModal(context);
                                if (created == true) {
                                  await _loadReports();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // İstatistik Kartları
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Toplam Rapor',
                          _reports.length.toString(),
                          FluentIcons.document,
                          Colors.blue,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Tamamlandı',
                          _reports.where((r) => r.status == ReportStatus.completed).length.toString(),
                          FluentIcons.check_mark,
                          Colors.green,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'İşleniyor',
                          _reports.where((r) => r.status == ReportStatus.processing).length.toString(),
                          FluentIcons.progress_ring_dots,
                          Colors.orange,
                          theme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Rapor Listesi
            Expanded(
              child: _isLoading
                  ? const Center(child: ProgressRing())
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            _errorMessage!,
                            style: theme.typography.body,
                          ),
                        )
                      : _filteredReports.isEmpty
                          ? Center(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        // Sidebar'daki \"Raporlar\" sekmesi ile aynı ikon
                                        FluentIcons.analytics_report,
                                        size: 48,
                                        color: theme.iconTheme.color?.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Henüz rapor kaydı bulunmuyor',
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
                              itemCount: _filteredReports.length,
                              itemBuilder: (context, index) {
                                final report = _filteredReports[index];
                                return _buildReportListCard(report);
                              },
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

  Widget _buildReportListCard(Report report) {
    final theme = FluentTheme.of(context);
    return EntityListCard(
      header: EntityListCardHeaderRow(
        leading: EntityListCardLeadingIconBox(
          icon: report.category.icon,
          color: report.category.color,
        ),
        title: report.title,
        subtitle: report.buildingName ?? 'Genel Rapor',
        trailing: EntityListCardHeaderPill(
          label: report.category.displayName,
          color: report.category.color,
        ),
      ),
      description: report.description,
      footer: Row(
        children: [
          EntityListCardMetaIconText(
            icon: FluentIcons.contact,
            text: report.createdByName ?? report.createdBy,
          ),
          const SizedBox(width: 16),
          EntityListCardMetaIconText(
            icon: FluentIcons.clock,
            text: _formatReportListDate(report.createdDate),
          ),
          const SizedBox(width: 16),
          if (report.fileUrl != null) ...[
            Icon(
              _getFileIcon(report.fileUrl!),
              size: 16,
              color: theme.iconTheme.color?.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Tooltip(
                message: _getCleanFileName(report.fileUrl!),
                child: Text(
                  _getCleanFileName(report.fileUrl!),
                  style: theme.typography.caption?.copyWith(
                    color: theme.typography.caption?.color?.withOpacity(0.7),
                  ),
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (report.fileSize != null) ...[
            const SizedBox(width: 16),
            Icon(
              FluentIcons.hard_drive,
              size: 16,
              color: theme.iconTheme.color?.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              report.fileSize!,
              style: theme.typography.caption?.copyWith(
                color: theme.typography.caption?.color?.withOpacity(0.7),
              ),
            ),
          ],
          const Spacer(),
          EntityActionButtons(
            width: report.status == ReportStatus.completed ? 280 : 170,
            primaryLabel:
                report.status == ReportStatus.completed ? 'Raporu Aç' : null,
            onPrimary:
                report.status == ReportStatus.completed ? () => _openReport(report) : null,
            onEdit: () => _editReport(report),
            onDelete: () => _deleteReport(report),
            onDetail: () => _showReportDetails(report),
          ),
        ],
      ),
    );
  }

  String _formatReportListDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

  void _createNewReport() {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        constraints: buildModalConstraints(context, maxWidth: 1300.0),
        title: buildModalTitle('Yeni Rapor Oluştur', context),
        content: SizedBox(
          width: double.infinity,
          height: 800,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hangi türde rapor oluşturmak istiyorsunuz?'),
        const SizedBox(height: 16),
            ...ReportCategory.values.map((category) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    category.icon,
                    color: category.color,
                  ),
                  title: Text(category.displayName),
                  subtitle: Text(category.description),
                  onPressed: () {
                    Navigator.pop(context);
                    _startReportGeneration(category);
                  },
                ),
              );
            }).toList(),
          ],
          ),
        ),
        actions: [
          Button(
            child: const Text('İptal'),
            onPressed: () => Navigator.pop(context),
        ),
      ],
      ),
    );
  }

  void _startReportGeneration(ReportCategory category) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Rapor Oluşturuluyor'),
        content: Text('${category.displayName} raporu oluşturulmaya başlandı.'),
        severity: InfoBarSeverity.info,
        onClose: close,
      ),
    );
  }

  void _downloadReport(Report report) {
    // Eski fonksiyon kullanılmıyor; geriye dönük uyumluluk için bırakıldı.
    _openReport(report);
  }

  void _viewReport(Report report) {
    // Eski fonksiyon kullanılmıyor; geriye dönük uyumluluk için bırakıldı.
    _openReport(report);
  }

  Future<void> _openReport(Report report) async {
    if (report.status != ReportStatus.completed || report.fileUrl == null || report.fileUrl!.isEmpty) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Uyarı'),
          content: const Text('Rapor henüz tamamlanmadı veya dosya eklenmemiş.'),
          severity: InfoBarSeverity.warning,
          onClose: close,
        ),
      );
      return;
    }

    // Backend file_url alanı genelde "/static/..." şeklinde geliyor
    final url = Uri.parse('${ApiService.baseUrl}${report.fileUrl}');

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        showErrorInfoBar(
          context,
          'Rapor açılırken bir sorun oluştu.',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorInfoBar(
          context,
          'Rapor açılırken hata oluştu: $e',
        );
      }
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

    if (updated == true) {
      await _loadReports();
    }
  }

  void _showReportDetails(Report report) {
    final theme = FluentTheme.of(context);
    final params = report.parameters;

    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        constraints: buildModalConstraints(ctx, maxWidth: 820.0),
        title: buildModalTitle('Rapor Detayı', ctx),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Üst satır: ID + kategori + durum
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (report.buildingName != null)
                      EntityTag(label: report.buildingName!, color: theme.accentColor),
                    EntityTag(
                      label: report.category.displayName,
                      color: report.category.color,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Başlık
                Text(
                  report.title,
                  style:
                      theme.typography.title?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Açıklama
                if (report.description.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        report.description,
                        style: theme.typography.body,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Bilgi satırları
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _ReportInfoRow(
                          icon: FluentIcons.contact,
                          label: 'Oluşturan',
                          value: report.createdByName ?? report.createdBy,
                        ),
                        const SizedBox(height: 8),
                        _ReportInfoRow(
                          icon: FluentIcons.clock,
                          label: 'Oluşturulma Tarihi',
                          value: _formatFullDate(report.createdDate),
                        ),
                        if (report.fileUrl != null) ...[
                          const SizedBox(height: 8),
                          _ReportInfoRow(
                            icon: _getFileIcon(report.fileUrl!),
                            label: 'Dosya',
                            value: _getCleanFileName(report.fileUrl!),
                          ),
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

  String _formatFullDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getCleanFileName(String url) {
    final fullName = url.split('/').last;
    
    // Eğer dosya adı çok uzunsa ve '_' içermiyorsa, muhtemelen sadece UUID'dir.
    if (!fullName.contains('_') && fullName.length > 30) {
      final ext = fullName.split('.').last;
      return 'Rapor Dosyası.$ext';
    }

    final parts = fullName.split('_');
    
    // Yeni format: {ReportID}_{ShortUUID}_{OriginalName} -> 3+ parça
    if (parts.length >= 3) {
      // İlk iki parçayı (ID kısımlarını) atla
      return parts.sublist(2).join('_');
    }
    
    // Olası eski format: {ID}_{OriginalName} -> 2 parça
    if (parts.length == 2) {
      // İlk parça UUID uzunluğundaysa (30+) atla
      if (parts[0].length > 30) {
        return parts[1];
      }
    }
    
    return fullName;
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
          setState(() {
            _reports.remove(report);
          });
          return true;
        } catch (e) {
          showErrorInfoBar(
            context,
            'Rapor silinirken hata oluştu: $e',
          );
          return false;
        }
      },
      successMessage: 'Rapor başarıyla silindi.',
    );
  }
}

String _formatDateForDetails(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays > 0) {
    return '${difference.inDays} gün önce';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} saat önce';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} dakika önce';
  } else {
    return 'Şimdi';
  }
}

class _ReportInfoRow extends StatelessWidget {
  const _ReportInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
          child: Text(
            label,
            style: theme.typography.caption
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
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

IconData _getFileIcon(String url) {
  final ext = url.split('.').last.toLowerCase();
  
  if (ext.contains('pdf')) {
    return FluentIcons.pdf;
  } else if (ext.contains('xls') || ext.contains('csv')) {
    return FluentIcons.table; // Excel/CSV için
  } else if (ext.contains('doc') || ext.contains('docx')) {
    return FluentIcons.edit; // Word için düzenleme/kalem ikonu
  } else if (ext.contains('txt')) {
    return FluentIcons.text_document;
  } else if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
    return FluentIcons.photo2;
  }
  
  return FluentIcons.page; // Bilinmeyen türler için genel ikon
}

// Model sınıfları
class Report {
  final String id;
  final String title;
  final String description;
  final ReportCategory category;
  final DateTime createdDate;
  final String createdBy;
  final ReportStatus status;
  final String? fileSize;
  final String? fileUrl;
  final int? buildingId;
  final String? createdByName;
  final String? buildingName;
  final Map<String, dynamic>? parameters;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdDate,
    required this.createdBy,
    required this.status,
    this.fileSize,
    this.fileUrl,
    this.buildingId,
    this.createdByName,
    this.buildingName,
    this.parameters,
  });

  /// Backend API (reports tablosu) cevabından Report modeline dönüştürme.
  factory Report.fromApi(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at']?.toString();
    final createdAt = parseBackendDateTime(createdAtRaw);

    final reportType = (json['report_type'] as String?) ?? 'genel';
    final fileUrl = json['file_url'] as String?;
    final buildingId = json['building_id'] as int?;

    Map<String, dynamic>? params;
    final rawParams = json['parameters'];
    if (rawParams is Map<String, dynamic>) {
      params = rawParams;
    } else if (rawParams is String) {
      try {
        params = Map<String, dynamic>.from(
          (jsonDecode(rawParams) as Map),
        );
      } catch (_) {
        params = null;
      }
    }

    return Report(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['content']?.toString() ?? '',
      category: ReportCategoryMapper.fromReportType(reportType),
      createdDate: createdAt,
      createdBy: json['created_by']?.toString() ?? 'Bilinmiyor',
      createdByName: json['created_by_name']?.toString(),
      buildingName: json['building_name']?.toString(),
      status: _mapStatusFromFileUrl(fileUrl),
      fileSize: null,
      fileUrl: fileUrl,
      buildingId: buildingId,
      parameters: params,
    );
  }
}

ReportStatus _mapStatusFromFileUrl(String? fileUrl) {
  // Şimdilik basit bir kural: file_url varsa tamamlandı, yoksa beklemede.
  if (fileUrl != null && fileUrl.isNotEmpty) {
    return ReportStatus.completed;
  }
  return ReportStatus.pending;
}

class ReportCategoryMapper {
  /// Backend report_type -> UI ReportCategory
  static ReportCategory fromReportType(String value) {
    switch (value) {
      case 'enerji':
        return ReportCategory.energy;
      case 'bakım':
      case 'bakim':
        return ReportCategory.maintenance;
      case 'arıza':
      case 'ariza':
        return ReportCategory.security;
      case 'genel':
      default:
        return ReportCategory.environmental;
    }
  }
}

enum ReportCategory {
  energy,
  maintenance,
  security,
  occupancy,
  environmental;

  String get displayName {
    switch (this) {
      case ReportCategory.energy:
        return 'Enerji';
      case ReportCategory.maintenance:
        return 'Bakım';
      case ReportCategory.security:
        return 'Güvenlik';
      case ReportCategory.occupancy:
        return 'Doluluk';
      case ReportCategory.environmental:
        return 'Çevresel';
    }
  }

  String get description {
    switch (this) {
      case ReportCategory.energy:
        return 'Enerji tüketimi ve verimlilik raporları';
      case ReportCategory.maintenance:
        return 'Bakım faaliyetleri ve planlama raporları';
      case ReportCategory.security:
        return 'Güvenlik olayları ve analiz raporları';
      case ReportCategory.occupancy:
        return 'Bina kullanımı ve doluluk raporları';
      case ReportCategory.environmental:
        return 'Çevresel etki ve sürdürülebilirlik raporları';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportCategory.energy:
        return FluentIcons.lightning_bolt;
      case ReportCategory.maintenance:
        return FluentIcons.build_definition;
      case ReportCategory.security:
        return FluentIcons.shield;
      case ReportCategory.occupancy:
        return FluentIcons.people;
      case ReportCategory.environmental:
        return FluentIcons.circle_shape;
    }
  }

  Color get color {
    switch (this) {
      case ReportCategory.energy:
        return Colors.orange;
      case ReportCategory.maintenance:
        return Colors.blue;
      case ReportCategory.security:
        return Colors.red;
      case ReportCategory.occupancy:
        return Colors.purple;
      case ReportCategory.environmental:
        return Colors.green;
    }
  }
}

enum ReportStatus {
  pending,
  processing,
  completed;

  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Beklemede';
      case ReportStatus.processing:
        return 'İşleniyor';
      case ReportStatus.completed:
        return 'Tamamlandı';
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.pending:
        return Colors.grey;
      case ReportStatus.processing:
        return Colors.orange;
      case ReportStatus.completed:
        return Colors.green;
    }
  }
}

  Future<bool?> _showCreateReportModal(BuildContext context) {
    final modalKey = GlobalKey<CreateReportModalState>();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return ContentDialog(
          constraints: buildModalConstraints(ctx, maxWidth: 700.0),
          title: buildModalTitle('Yeni Rapor Oluştur', ctx),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: CreateReportModal(
                    key: modalKey,
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
  }
