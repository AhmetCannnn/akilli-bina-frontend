import 'package:belediye_otomasyon/core/utils/api_error.dart';
import 'package:belediye_otomasyon/core/utils/form_field_helpers.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/buildings/presentation/providers/building_provider.dart';

class AddMaintenanceModal extends ConsumerStatefulWidget {
  const AddMaintenanceModal({
    super.key,
    required this.formKey,
    this.initialTitle,
    this.initialDescription,
    this.initialLocation,
    this.initialCategory,
    this.initialPriority,
    this.initialEstimatedDuration,
    this.initialCost,
    this.submitLabel,
    this.maintenance, // Optional: existing maintenance record for editing
    this.onGetFormData, // Callback to get form data
  });

  final GlobalKey<FormState> formKey;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialLocation;
  final String? initialCategory; // Display name from _categories list
  final String? initialPriority; // Display name from _priorities list
  final String? initialEstimatedDuration;
  // final DateTime? initialSuggestedDate; // removed suggested date input
  final String? initialCost; // display string like "1500 TL"
  final String? submitLabel;
  final Map<String, dynamic>? maintenance; // Optional: existing maintenance record for editing
  final Map<String, dynamic>? Function()? onGetFormData; // Callback to get form data

  @override
  ConsumerState<AddMaintenanceModal> createState() => AddMaintenanceModalState();
}

// State'i public yap ki GlobalKey ile erişilebilsin
class AddMaintenanceModalState extends ConsumerState<AddMaintenanceModal> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  // Removed estimated duration as per requirements
  final _costController = TextEditingController();
  final TextEditingController _buildingSearchController = TextEditingController();
  String? _selectedBuildingId;
  List<Map<String, dynamic>> _buildings = [];
  
  String _selectedCategory = 'Asansör';
  String _selectedPriority = 'Orta';
  DateTime _suggestedDate = DateTime.now().add(const Duration(days: 7));
  
  // Status selection
  String _selectedStatus = 'planlandı';
  final List<String> _statuses = ['taslak', 'planlandı', 'tamamlandı'];
  
  final List<String> _categories = ['Asansör', 'İklimlendirme', 'Elektrik', 'Tesisatçı', 'Güvenlik'];
  final List<String> _priorities = ['Kritik', 'Yüksek', 'Orta', 'Düşük'];

  @override
  void initState() {
    super.initState();
    
    // If maintenance record is provided, use it to prefill fields
    if (widget.maintenance != null) {
      final m = widget.maintenance!;
      _titleController.text = m['title'] ?? '';
      _descriptionController.text = m['description'] ?? '';
      
      // Cost handling
      if (m['cost'] != null) {
        final cost = m['cost'];
        _costController.text = (cost is num ? cost : double.parse(cost.toString())).toStringAsFixed(0);
      }
      
      // Scheduled date
      if (m['scheduled_date'] != null) {
        try {
          _suggestedDate = DateTime.parse(m['scheduled_date']);
        } catch (e) {
          // Keep default date
        }
      }
      
      // Status prefill
      if (m['status'] is String && _statuses.contains(m['status'])) {
        _selectedStatus = m['status'];
      }
      // Location prefill
      if (m['location'] is String) {
        _locationController.text = m['location'];
      }
      // Prefill selected building id if provided
      if (m['building_id'] != null) {
        _selectedBuildingId = m['building_id'].toString();
      }
    } else {
      // Prefill controllers from initial values if provided
      if (widget.initialTitle != null) {
        _titleController.text = widget.initialTitle!;
      }
      if (widget.initialDescription != null) {
        _descriptionController.text = widget.initialDescription!;
      }
      if (widget.initialLocation != null) {
        _locationController.text = widget.initialLocation!;
      }
      if (widget.initialCost != null) {
        _costController.text = widget.initialCost!;
      }
      if (widget.initialCategory != null &&
          _categories.contains(widget.initialCategory)) {
        _selectedCategory = widget.initialCategory!;
      }
      if (widget.initialPriority != null &&
          _priorities.contains(widget.initialPriority)) {
        _selectedPriority = widget.initialPriority!;
      }
      // suggested date input removed
    }
  }

  @override
  void dispose() {
    disposeControllers([
      _titleController,
      _descriptionController,
      _locationController,
      _costController,
      _buildingSearchController,
    ]);
    super.dispose();
  }

  double? _parseCost(String raw) {
    final costStr = raw.trim().replaceAll(RegExp(r'[^\d.]'), '');
    if (costStr.isEmpty) return null;
    return double.tryParse(costStr);
  }

  /// Form verilerini Map olarak döndürür
  Map<String, dynamic>? getFormData() {
    if (!widget.formKey.currentState!.validate()) {
      return null;
    }

    // Building selection required
    if (_selectedBuildingId == null) {
      return null;
    }

    final cost = _parseCost(_costController.text);

    return {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _selectedCategory,
      'priority': _selectedPriority,
      'status': _selectedStatus,
      // 'scheduled_date': _suggestedDate.toIso8601String(), // removed from payload
      'building_id': int.parse(_selectedBuildingId!),
      if (_locationController.text.trim().isNotEmpty)
        'location': _locationController.text.trim(),
      if (cost != null) 'cost': cost,
      // notes optional
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

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Form(
            key: widget.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildFormTextField(
                  label: 'Bakım Başlığı',
                  controller: _titleController,
                  placeholder: 'Bakım başlığını giriniz',
                ),
                const SizedBox(height: 16),

                buildFormTextField(
                  label: 'Açıklama',
                  controller: _descriptionController,
                  placeholder: 'Bakım açıklamasını giriniz',
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
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                buildFormTextField(
                  label: 'Bakım Yeri',
                  controller: _locationController,
                  placeholder: 'Arızanın/bakımın olduğu yeri giriniz',
                ),
                const SizedBox(height: 16),

                buildFormRow([
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
                ]),
                const SizedBox(height: 16),

                buildFormComboBox<String>(
                  label: 'Durum',
                  value: _selectedStatus,
                  items: _statuses,
                  displayText: (v) => v,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                buildFormTextField(
                  label: 'Tahmini Maliyet',
                  controller: _costController,
                  placeholder: 'Örn: 1500 TL',
                ),
                const SizedBox(height: 16),

                // Önerilen Tarih alanı kaldırıldı
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: ProgressRing()),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildErrorCard(theme, humanizeError(error)),
            const SizedBox(height: 8),
            Button(
              child: const Text('Yeniden Dene'),
              onPressed: () => ref.invalidate(buildingControllerProvider),
            ),
          ],
        ),
      ),
    );
  }
}

