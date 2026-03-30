import 'package:fluent_ui/fluent_ui.dart';
import 'package:belediye_otomasyon/core/utils/form_field_helpers.dart'
    show buildFormTextField, buildFormComboBox, buildFormRow;
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart'
    show disposeControllers, showErrorInfoBar, showSuccessInfoBar;
import 'package:belediye_otomasyon/core/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import '../screens/reports_screen.dart' show Report, ReportCategory;

class CreateReportModal extends StatefulWidget {
  const CreateReportModal({super.key, this.initialReport});

  /// Düzenleme modunda kullanılacak mevcut rapor (opsiyonel).
  final Report? initialReport;

  @override
  State<CreateReportModal> createState() => CreateReportModalState();
}

class CreateReportModalState extends State<CreateReportModal> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ApiService _api = ApiService();
  
  String _selectedCategory = 'Enerji';

  // Bina seçimi
  final List<Map<String, dynamic>> _buildings = [];
  int? _selectedBuildingId; // null => Genel (bina seçilmedi)

  // Dosya seçimi (web'de PlatformFile, mobil/desktop'ta path'li PlatformFile)
  PlatformFile? _selectedFile;
  String? _selectedFileName;
  
  final List<String> _categories = ['Enerji', 'Bakım', 'Güvenlik', 'Doluluk', 'Çevresel'];

  @override
  void dispose() {
    disposeControllers([
      _titleController,
      _descriptionController,
    ]);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadBuildings();

    // Düzenleme modunda alanları doldur
    final initial = widget.initialReport;
    if (initial != null) {
      _titleController.text = initial.title;
      _descriptionController.text = initial.description;

      // Kategori
      switch (initial.category) {
        case ReportCategory.energy:
          _selectedCategory = 'Enerji';
          break;
        case ReportCategory.maintenance:
          _selectedCategory = 'Bakım';
          break;
        case ReportCategory.security:
          _selectedCategory = 'Güvenlik';
          break;
        case ReportCategory.occupancy:
          _selectedCategory = 'Doluluk';
          break;
        case ReportCategory.environmental:
          _selectedCategory = 'Çevresel';
          break;
      }

      // Bina
      _selectedBuildingId = initial.buildingId;

      // Mevcut dosya varsa adını göster
      if (initial.fileUrl != null && initial.fileUrl!.isNotEmpty) {
        _selectedFileName = _getCleanFileNameFromUrl(initial.fileUrl!);
      }
    }
  }

  /// URL'den okunabilir dosya adı çıkarır (mevcut rapor dosyası için)
  static String _getCleanFileNameFromUrl(String url) {
    final fullName = url.split('/').last;
    if (fullName.isEmpty) return 'Mevcut dosya';
    if (!fullName.contains('_') && fullName.length > 30) {
      final ext = fullName.split('.').last;
      return 'Rapor Dosyası.$ext';
    }
    final parts = fullName.split('_');
    if (parts.length >= 3) return parts.sublist(2).join('_');
    if (parts.length == 2 && parts[0].length > 30) return parts[1];
    return fullName;
  }

  void _saveReportData() {
    if (_titleController.text.isEmpty) {
      showErrorInfoBar(context, 'Lütfen rapor başlığını giriniz.');
      return;
    }

    _createReport();
  }

  /// Dış diyaloğun altındaki "Rapor Oluştur / Güncelle" butonu burayı çağırır.
  Future<void> submit() async {
    _saveReportData();
  }

  Future<void> _loadBuildings() async {
    try {
      final response = await _api.get('/buildings');
      final data = response.data;
      if (data is List) {
        setState(() {
          _buildings
            ..clear()
            ..addAll(data.whereType<Map<String, dynamic>>());
        });
      }
    } catch (_) {
      // Bina listesi yüklenemezse, sadece genel rapor seçeneği kalır; ekstra hata göstermeyelim.
    }
  }

  String _mapCategoryToReportType(String category) {
    switch (category) {
      case 'Enerji':
        return 'enerji';
      case 'Bakım':
        return 'bakim';
      case 'Güvenlik':
        return 'ariza';
      case 'Doluluk':
      case 'Çevresel':
      default:
        return 'genel';
    }
  }

  Future<void> _createReport() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    final body = {
      'title': title,
      'content': description.isNotEmpty ? description : title,
      'report_type': _mapCategoryToReportType(_selectedCategory),
      if (_selectedBuildingId != null) 'building_id': _selectedBuildingId,
      'parameters': {
        'category_label': _selectedCategory,
      },
    };

    try {
      String? reportId;
      if (widget.initialReport == null) {
        // Yeni rapor
        final response = await _api.post('/reports', data: body);
        reportId = response.data['id']?.toString();
      } else {
        // Mevcut raporu güncelle
        final response =
            await _api.put('/reports/${widget.initialReport!.id}', data: body);
        reportId = response.data['id']?.toString();
      }

      // Dosya seçildiyse, rapor kaydına dosyayı yükle
      if (reportId != null && _selectedFile != null) {
        await _api.uploadFile(
          '/reports/$reportId/upload-file',
          _selectedFile!,
          filename: _selectedFileName,
        );
      }

      // Başarılı ise modal'ı true ile kapat
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      showErrorInfoBar(
        context,
        'Rapor oluşturulurken hata oluştu: $e',
      );
    }
  }

  Future<void> _pickReportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'csv', 'xlsx', 'txt'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        final file = result.files.single;
        _selectedFile = file;
        _selectedFileName = file.name;
      });
    } catch (e) {
      showErrorInfoBar(
        context,
        'Dosya seçilirken hata oluştu: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildFormTextField(
            label: 'Rapor Başlığı',
            controller: _titleController,
            placeholder: 'Örn: Mart Ayı Enerji Tüketimi',
          ),
          const SizedBox(height: 16),

          buildFormTextField(
            label: 'Açıklama (İsteğe Bağlı)',
            controller: _descriptionController,
            placeholder: 'Rapor hakkında kısa bir açıklama...',
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          buildFormComboBox<int?>(
            label: 'İlişkili Bina (Opsiyonel)',
            value: _selectedBuildingId,
            items: [
              null,
              ..._buildings.map((b) => b['id'] as int),
            ],
            displayText: (id) {
              if (id == null) return 'Genel (Bina Seçilmedi)';
              final building = _buildings.firstWhere(
                (b) => b['id'] == id,
                orElse: () => {},
              );
              return building['name']?.toString() ?? 'Bina #$id';
            },
            onChanged: (value) =>
                setState(() => _selectedBuildingId = value),
          ),
          const SizedBox(height: 16),

          // Kategori
          buildFormComboBox<String>(
            label: 'Kategori',
            value: _selectedCategory,
            items: _categories,
            displayText: (e) => e,
            onChanged: (value) =>
                setState(() => _selectedCategory = value!),
          ),
          const SizedBox(height: 16),

          // Rapor dosyası
          Text(
            'Rapor Dosyası',
            style: theme.typography.bodyStrong,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Button(
                child: const Text('Dosya Seç'),
                onPressed: _pickReportFile,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedFileName ?? 'Herhangi bir dosya seçilmedi',
                  style: theme.typography.body?.copyWith(
                    color:
                        theme.typography.body?.color?.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
