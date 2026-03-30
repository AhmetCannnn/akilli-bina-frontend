import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:belediye_otomasyon/core/utils/api_error.dart' show humanizeError;
import 'package:belediye_otomasyon/core/utils/form_field_helpers.dart'
    show buildFormTextField, buildFormComboBox, buildFormRow;
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart' show disposeControllers, buildErrorCard;
import '../../../../features/buildings/presentation/providers/building_provider.dart';
import '../providers/issue_provider.dart';
import '../../domain/models/issue.dart';

class ReportIssueModal extends ConsumerStatefulWidget {
  const ReportIssueModal({
    super.key,
    required this.formKey,
    this.initialTitle,
    this.initialDescription,
    this.initialLocation,
    this.initialIssuePlace,
    this.initialPriority,
    this.initialCategory,
    this.initialBuildingId,
    this.initialBuildingName,
  });

  final GlobalKey<FormState> formKey;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialLocation;
  final String? initialIssuePlace; // Bina içi arıza yeri
  final String? initialPriority; // 'Düşük' | 'Orta' | 'Yüksek' | 'Kritik'
  final String? initialCategory; // see _categories list
  final String? initialBuildingId; // as String
  final String? initialBuildingName;

  @override
  ConsumerState<ReportIssueModal> createState() => ReportIssueModalState();
}

class ReportIssueModalState extends ConsumerState<ReportIssueModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _issuePlaceController;
  final TextEditingController _buildingSearchController = TextEditingController();
  late final DateTime _createdAt = DateTime.now();
  // Not editable: will be auto-filled from auth/session later
  // For now, placeholders to demonstrate behavior
  final String _reporterName = 'Mevcut Kullanıcı';
  final String _reporterPhone = '0505 000 00 00';
  final String _reporterEmail = 'user@example.com';
  // Buildings will be loaded from backend
  String? _selectedBuildingId;
  
  // Buildings will be loaded from backend via Riverpod
  List<Map<String, dynamic>> _buildings = [];
  
  String _selectedPriority = 'Orta';
  String _selectedCategory = 'Elektrik';
  
  final List<String> _priorities = ['Düşük', 'Orta', 'Yüksek', 'Kritik'];
  final List<String> _categories = ['Elektrik', 'Su', 'Isıtma', 'Asansör', 'Güvenlik', 'Temizlik', 'Diğer'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _locationController = TextEditingController(text: widget.initialLocation ?? '');
    _issuePlaceController = TextEditingController(text: widget.initialIssuePlace ?? '');
    if (widget.initialPriority != null && _priorities.contains(widget.initialPriority)) {
      _selectedPriority = widget.initialPriority!;
    }
    if (widget.initialCategory != null && _categories.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    }
    // Pre-fill selected building id/name if provided
    _selectedBuildingId = widget.initialBuildingId;
    if ((widget.initialBuildingName ?? '').isNotEmpty) {
      _buildingSearchController.text = widget.initialBuildingName!;
    }
  }

  @override
  void dispose() {
    disposeControllers([
      _titleController,
      _descriptionController,
      _locationController,
      _issuePlaceController,
      _buildingSearchController,
    ]);
    super.dispose();
  }

  /// Form verilerini Map olarak döndürür
  Map<String, dynamic>? getFormData() {
    // Validasyon parent tarafından tetiklenmiş olmalı veya burada kontrol edilebilir
    if (!widget.formKey.currentState!.validate()) {
      return null;
    }

    final buildingId = _selectedBuildingId != null ? int.tryParse(_selectedBuildingId!) : null;
    
    if (buildingId == null) {
      // TODO: Show error or validation message
      return null;
    }

    return {
      'building_id': buildingId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'issuePlace': _issuePlaceController.text.trim(),
      'priority': IssuePriorityX.displayNameToApiValue(_selectedPriority),
      'category': _selectedCategory,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final buildingsAsync = ref.watch(buildingControllerProvider);
    
    return buildingsAsync.when(
      data: (buildings) {
        _buildings = buildings;
        // If initial id provided and not yet set in UI, ensure controller shows initial name
        if (_selectedBuildingId != null && _buildingSearchController.text.isEmpty) {
          final match = _buildings.firstWhere(
            (b) => b['id'].toString() == _selectedBuildingId,
            orElse: () => {},
          );
          final name = match is Map<String, dynamic> ? (match['name'] ?? '').toString() : '';
          if (name.isNotEmpty) _buildingSearchController.text = name;
        }
        return _buildContent(theme);
      },
      loading: () => const Center(child: ProgressRing()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildErrorCard(theme, humanizeError(error)),
            const SizedBox(height: 16),
            Button(
              child: const Text('Yeniden Dene'),
              onPressed: () => ref.refresh(buildingControllerProvider),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContent(FluentThemeData theme) {

    // Bakım ekleme modalinin sade tasarımını baz alan form
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildFormTextField(
              label: 'Başlık',
              controller: _titleController,
              placeholder: 'Arıza başlığını giriniz',
            ),
            const SizedBox(height: 16),

            buildFormTextField(
              label: 'Açıklama',
              controller: _descriptionController,
              placeholder: 'Arıza detaylarını açıklayınız',
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            InfoLabel(
              label: 'Bina',
              child: AutoSuggestBox<String>(
                controller: _buildingSearchController,
                placeholder: 'Bina arayın ve seçin',
                items: [
                  for (final b in _buildings)
                    AutoSuggestBoxItem<String>(
                      value: b['id'].toString(),
                      label: b['name'],
                      child: Tooltip(
                        message: b['name'],
                        child: Text(
                          b['name'],
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
                onSelected: (item) {
                  setState(() {
                    _selectedBuildingId = item.value;
                    final selected = _buildings.firstWhere(
                      (b) => b['id'].toString() == item.value,
                      orElse: () => _buildings.first,
                    );
                    _locationController.text = selected['address'] ?? '';
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Öncelik + Kategori (yan yana), bakım modaline benzer
            buildFormRow([
              Expanded(
                child: buildFormComboBox<String>(
                  label: 'Öncelik',
                  value: _selectedPriority,
                  items: _priorities,
                  displayText: (v) => v,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPriority = value);
                    }
                  },
                ),
              ),
              Expanded(
                child: buildFormComboBox<String>(
                  label: 'Kategori',
                  value: _selectedCategory,
                  items: _categories,
                  displayText: (v) => v,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Konum + Arıza Yeri (yan yana)
            buildFormRow([
              Expanded(
                child: buildFormTextField(
                  label: 'Konum',
                  controller: _locationController,
                  placeholder: 'Bina adresi (otomatik dolar)',
                ),
              ),
              Expanded(
                child: buildFormTextField(
                  label: 'Arıza Yeri',
                  controller: _issuePlaceController,
                  placeholder: 'Örn: Zemin kat - Toplantı Salonu',
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    // Display name'den IssuePriority enum'ına çevir ve color'ını al
    final apiValue = IssuePriorityX.displayNameToApiValue(priority);
    final priorityEnum = IssuePriorityX.fromApiValue(apiValue);
    return priorityEnum.color;
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'Düşük':
        return FluentIcons.info;
      case 'Orta':
        return FluentIcons.warning;
      case 'Yüksek':
        return FluentIcons.warning;
      case 'Kritik':
        return FluentIcons.error;
      default:
        return FluentIcons.info;
    }
  }

  String _getPriorityDescription(String priority) {
    switch (priority) {
      case 'Düşük':
        return 'Acil olmayan, rutin bakım gerektiren durumlar';
      case 'Orta':
        return 'Günlük işleyişi etkileyebilecek durumlar';
      case 'Yüksek':
        return 'Hızlı müdahale gerektiren önemli durumlar';
      case 'Kritik':
        return 'Acil müdahale gerektiren, güvenliği tehdit eden durumlar';
      default:
        return '';
    }
  }
}

