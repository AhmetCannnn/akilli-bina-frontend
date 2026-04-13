import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/building_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:belediye_otomasyon/core/services/api_service.dart';
import 'package:belediye_otomasyon/features/employees/data/services/employee_api_service.dart';
import 'package:belediye_otomasyon/core/utils/api_error.dart'; // For humanizeError
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart' show buildModalTitle, buildModalConstraints, showSuccessInfoBar, showErrorInfoBar;
import 'package:belediye_otomasyon/core/utils/form_field_helpers.dart' show buildFormTextField, buildFormComboBox, buildFormRow, buildListInputField, buildTagList;

class AddBuildingModal extends StatefulWidget {
  const AddBuildingModal({
    super.key, 
    required this.formKey,
    this.buildingData,
    this.onFormDataChanged,
  });

  final GlobalKey<FormState> formKey;
  final Map<String, dynamic>? buildingData;
  final Function(Map<String, dynamic>)? onFormDataChanged;

  @override
  State<AddBuildingModal> createState() => AddBuildingModalState();

  // Ortak modal content widget'ı
  static Widget _buildModalContent({
    required GlobalKey<FormState> formKey,
    required GlobalKey<AddBuildingModalState> modalKey,
    required String buttonText,
    required Future<void> Function(Map<String, dynamic> data) onSubmit,
    required String errorMessage,
    Map<String, dynamic>? buildingData,
  }) {
    return StatefulBuilder(
      builder: (ctx, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: AddBuildingModal(
                  key: modalKey,
                  formKey: formKey,
                  buildingData: buildingData,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                FilledButton(
                  child: Text(buttonText),
                  onPressed: () async {
                    final form = formKey.currentState;
                    if (form == null || !form.validate()) return;
                    
                    final modalState = modalKey.currentState;
                    if (modalState == null) return;
                    
                    final buildingData = modalState.getFormData();
                    
                    try {
                      await onSubmit(buildingData);
                      if (ctx.mounted) {
                        Navigator.pop(ctx, true);
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        showErrorInfoBar(ctx, '$errorMessage: ${humanizeError(e)}');
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Opens the "Add Building" modal (for creating new buildings)
  static void showAddBuildingModal(
    BuildContext context,
    WidgetRef ref,
  ) {
    final formKey = GlobalKey<FormState>();
    final modalKey = GlobalKey<AddBuildingModalState>();
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ContentDialog(
        constraints: buildModalConstraints(ctx),
        title: buildModalTitle('Yeni Bina Ekle', ctx),
        content: _buildModalContent(
          formKey: formKey,
          modalKey: modalKey,
          buttonText: 'Kaydet',
          onSubmit: (data) => ref.read(buildingControllerProvider.notifier).createBuilding(data),
          errorMessage: 'Bina eklenirken hata oluştu',
        ),
        actions: null,
      ),
    ).then((isSaved) {
      if (isSaved == true) {
        showSuccessInfoBar(context, 'Bina bilgileri kaydedildi.');
      }
    });
  }

  /// Opens the "Edit Building" modal (for updating existing buildings)
  static void showEditBuildingModal(
    BuildContext context,
    WidgetRef ref,
    int buildingId,
    Map<String, dynamic> building,
  ) {
    final formKey = GlobalKey<FormState>();
    final modalKey = GlobalKey<AddBuildingModalState>();
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ContentDialog(
        constraints: buildModalConstraints(ctx),
        title: buildModalTitle('Bina Düzenle', ctx),
        content: _buildModalContent(
          formKey: formKey,
          modalKey: modalKey,
          buttonText: 'Güncelle',
          onSubmit: (data) async {
            // Bina listesi provider'ını güncelle (ana sayfa için)
            await ref.read(buildingControllerProvider.notifier).updateBuilding(buildingId, data);
            // Detay sayfası provider'ını direkt güncelle (optimize - API'ye tekrar istek atmaz)
            await ref.read(buildingDetailControllerProvider(buildingId).notifier).updateBuilding(buildingId, data);
          },
          errorMessage: 'Bina güncellenirken hata oluştu',
          buildingData: building,
        ),
        actions: null,
      ),
    ).then((isSaved) {
      if (isSaved == true) {
        showSuccessInfoBar(context, 'Bina bilgileri güncellendi.');
      }
    });
  }
}

class AddBuildingModalState extends State<AddBuildingModal> {
  
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _areaController = TextEditingController();
  final _floorController = TextEditingController();
  final _yearController = TextEditingController();
  final _assetController = TextEditingController();
  final _parkingController = TextEditingController();
  final _departmentInputController = TextEditingController();
  final _facilityInputController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _workingHoursOpenController = TextEditingController();
  final _workingHoursCloseController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final List<String> _departments = [];
  final List<String> _facilities = [];
  
  String _selectedType = 'KOMEK';
  String _selectedStatus = 'active';
  String? _selectedManagerId; // UUID string
  bool _workingHoursWeekend = false;
  bool _workingHoursHolidays = false;
  bool _hasChiller = false;
  static const List<String> _buildingTypes = ['KOMEK', 'Müze', 'Hizmet Binası'];
  static const List<String> _statusOptions = ['active', 'inactive', 'under_maintenance', 'under_construction'];
  static const Map<String, String> _statusDisplayNames = {
    'active': 'Aktif',
    'inactive': 'Pasif',
    'under_maintenance': 'Bakımda',
    'under_construction': 'İnşaat Halinde',
  };
  
  dynamic _selectedPhoto; // Web'de XFile, mobilde File
  bool _isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _populateFields();
    // İlk form data'sını gönder
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getFormData();
    });
  }

  void _populateFields() {
    if (widget.buildingData != null) {
      final data = widget.buildingData!;
      
      _nameController.text = data['name']?.toString() ?? '';
      _addressController.text = data['address']?.toString() ?? '';
      _cityController.text = data['city']?.toString() ?? '';
      _districtController.text = data['district']?.toString() ?? '';
      _areaController.text = data['building_area']?.toString() ?? '';
      _floorController.text = data['floor_count']?.toString() ?? '';
      _yearController.text = data['construction_year']?.toString() ?? '';
      _assetController.text = data['asset_count']?.toString() ?? '';
      _parkingController.text = data['parking_capacity']?.toString() ?? '';
      _descriptionController.text = data['description']?.toString() ?? '';
      _photoUrlController.text = data['photo_url']?.toString() ?? '';
      _hasChiller = data['has_chiller'] == true;

      final rawCoordinates = data['coordinates'];
      if (rawCoordinates is List && rawCoordinates.length == 2) {
        _latitudeController.text = rawCoordinates[0]?.toString() ?? '';
        _longitudeController.text = rawCoordinates[1]?.toString() ?? '';
      }
      
      // Building type
      _selectedType = data['building_type']?.toString() ?? 'KOMEK';
      
      // Status
      _selectedStatus = data['status']?.toString() ?? 'active';
      
      // Working hours
      _populateWorkingHours(data['working_hours']);
      
      // Manager ID - direkt building'den manager_id al
      final managerId = data['manager_id'];
      _selectedManagerId = managerId != null ? managerId.toString() : null;
      
      // Departments
      if (data['departments'] is List) {
        _departments.clear();
        _departments.addAll(
          (data['departments'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty)
        );
      }
      
      // Facilities
      if (data['facilities'] is List) {
        _facilities.clear();
        _facilities.addAll(
          (data['facilities'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty)
        );
      }
    }
  }

  // Tüm controller'ları liste halinde tut (dispose için)
  List<TextEditingController> get _allControllers => [
    _nameController,
    _addressController,
    _cityController,
    _districtController,
    _areaController,
    _floorController,
    _yearController,
    _assetController,
    _parkingController,
    _departmentInputController,
    _facilityInputController,
    _descriptionController,
    _photoUrlController,
    _workingHoursOpenController,
    _workingHoursCloseController,
    _latitudeController,
    _longitudeController,
  ];

  @override
  void dispose() {
    // Tüm controller'ları dispose et
    for (final controller in _allControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Form data'sını topla ve döndür
  Map<String, dynamic> getFormData() {
    final parsedLat = double.tryParse(_latitudeController.text.trim());
    final parsedLng = double.tryParse(_longitudeController.text.trim());

    final formData = {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'district': _districtController.text.trim(),
      'building_type': _selectedType,
      'building_area': int.tryParse(_areaController.text) ?? 0,
      'floor_count': int.tryParse(_floorController.text) ?? 0,
      'construction_year': int.tryParse(_yearController.text) ?? 0,
      'employee_count': 0, // Çalışan sayısı otomatik hesaplanır
      'asset_count': int.tryParse(_assetController.text) ?? 0,
      'parking_capacity': int.tryParse(_parkingController.text) ?? 0,
      'has_chiller': _hasChiller,
      'departments': _departments,
      'facilities': _facilities,
      'status': _selectedStatus,
      if (_descriptionController.text.trim().isNotEmpty)
        'description': _descriptionController.text.trim(),
      if (_photoUrlController.text.trim().isNotEmpty)
        'photo_url': _photoUrlController.text.trim(),
      // Working hours
      'working_hours': _buildWorkingHours(),
      // Manager ID (FK to employees table)
      if (_selectedManagerId != null && _selectedManagerId!.isNotEmpty)
        'manager_id': _selectedManagerId,
      if (parsedLat != null && parsedLng != null)
        'coordinates': [
          parsedLat,
          parsedLng,
        ],
    };
    
    // Callback ile form data'sını dışarıya gönder
    widget.onFormDataChanged?.call(formData);
    
    return formData;
  }

  // Working hours objesini oluştur
  Map<String, dynamic> _buildWorkingHours() {
    return {
      'weekdays': {
        'open': _workingHoursOpenController.text.trim().isNotEmpty 
            ? _workingHoursOpenController.text.trim() 
            : '08:00',
        'close': _workingHoursCloseController.text.trim().isNotEmpty 
            ? _workingHoursCloseController.text.trim() 
            : '18:00',
      },
      'weekend': _workingHoursWeekend,
      'holidays': _workingHoursHolidays,
    };
  }

  

  // Fotoğraf seç ve yükle
  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingPhoto = true;
      });

      // Web platformunda File yerine XFile kullan
      try {
        final apiService = ApiService();
        final response = await apiService.uploadFile(
          '/upload/building-photo',
          pickedFile,
          filename: pickedFile.name,
        );

        if (response.statusCode == 200 && response.data['url'] != null) {
          setState(() {
            _photoUrlController.text = response.data['url'];
            _isUploadingPhoto = false;
            // Web ve mobil için XFile kullan
            _selectedPhoto = pickedFile;
          });
          getFormData(); // Form data'sını güncelle
        } else {
          throw Exception('Fotoğraf yüklenemedi');
        }
      } catch (e) {
        setState(() => _isUploadingPhoto = false);
        if (mounted) {
          showErrorInfoBar(context, 'Fotoğraf yüklenirken hata oluştu: ${humanizeError(e)}');
        }
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        showErrorInfoBar(context, 'Fotoğraf seçilirken hata oluştu: ${humanizeError(e)}');
      }
    }
  }

  // Working hours verilerini doldur
  void _populateWorkingHours(dynamic workingHours) {
    const defaultOpen = '08:00';
    const defaultClose = '18:00';
    
    if (workingHours != null && workingHours is Map) {
      final weekdays = workingHours['weekdays'];
      if (weekdays != null && weekdays is Map) {
        _workingHoursOpenController.text = weekdays['open']?.toString() ?? defaultOpen;
        _workingHoursCloseController.text = weekdays['close']?.toString() ?? defaultClose;
      } else {
        _workingHoursOpenController.text = defaultOpen;
        _workingHoursCloseController.text = defaultClose;
      }
      _workingHoursWeekend = workingHours['weekend'] == true;
      _workingHoursHolidays = workingHours['holidays'] == true;
    } else {
      _workingHoursOpenController.text = defaultOpen;
      _workingHoursCloseController.text = defaultClose;
      _workingHoursWeekend = false;
      _workingHoursHolidays = false;
    }
  }


  // Department veya Facility ekle
  void _addListItem(String item, bool isDepartment) {
    final trimmedItem = item.trim();
    if (trimmedItem.isEmpty) return;
    
    setState(() {
      if (isDepartment) {
        if (!_departments.contains(trimmedItem)) {
          _departments.add(trimmedItem);
        }
        _departmentInputController.clear();
      } else {
        if (!_facilities.contains(trimmedItem)) {
          _facilities.add(trimmedItem);
        }
        _facilityInputController.clear();
      }
    });
    getFormData();
  }



  // Form field grupları arası boşluk
  static const _fieldSpacing = SizedBox(height: 16);

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Form(
            key: widget.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tek satır: Bina Adı (daha geniş) + Bina Türü + Durum
                buildFormRow([
                  Expanded(
                    flex: 2,
                    child: buildFormTextField(
                      label: 'Bina Adı',
                      controller: _nameController,
                      placeholder: 'Bina adını giriniz',
                      onChanged: getFormData,
                    ),
                  ),
                  Expanded(
                    child: buildFormComboBox<String>(
                      label: 'Bina Türü',
                      value: _selectedType,
                      items: _buildingTypes,
                      displayText: (type) => type,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                          getFormData();
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: buildFormComboBox<String>(
                      label: 'Durum',
                      value: _selectedStatus,
                      items: _statusOptions,
                      displayText: (status) =>
                          _statusDisplayNames[status] ?? status,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStatus = value);
                          getFormData();
                        }
                      },
                    ),
                  ),
                ]),
                _fieldSpacing,
                buildFormTextField(label: 'Adres', controller: _addressController, placeholder: 'Bina adresini giriniz', maxLines: 2, onChanged: getFormData),
                _fieldSpacing,
                buildFormRow([
                  Expanded(child: buildFormTextField(label: 'Şehir', controller: _cityController, placeholder: 'Şehir adını giriniz', onChanged: getFormData)),
                  Expanded(child: buildFormTextField(label: 'İlçe', controller: _districtController, placeholder: 'İlçe adını giriniz', onChanged: getFormData)),
                ]),
                _fieldSpacing,
                buildFormRow([
                  Expanded(child: buildListInputField(label: 'Birimler', controller: _departmentInputController, placeholder: 'Birim adı ekle', onAdd: (v) => _addListItem(v, true))),
                  Expanded(child: buildListInputField(label: 'Tesisler', controller: _facilityInputController, placeholder: 'Tesis adı ekle', onAdd: (v) => _addListItem(v, false))),
                ]),
                _fieldSpacing,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: buildTagList(
                        items: _departments,
                        color: Colors.blue,
                        onRemove: (item) {
                          setState(() => _departments.remove(item));
                          getFormData();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildTagList(
                        items: _facilities,
                        color: Colors.green,
                        onRemove: (item) {
                          setState(() => _facilities.remove(item));
                          getFormData();
                        },
                      ),
                    ),
                  ],
                ),
                _fieldSpacing,
                buildFormRow([
                  Expanded(child: buildFormTextField(label: 'Bina Alanı (m²)', controller: _areaController, placeholder: '0', onChanged: getFormData)),
                  Expanded(child: buildFormTextField(label: 'Kat Sayısı', controller: _floorController, placeholder: '0', onChanged: getFormData)),
                  Expanded(child: buildFormTextField(label: 'Yapım Yılı', controller: _yearController, placeholder: '2024', onChanged: getFormData)),
                ]),
                _fieldSpacing,
                buildFormRow([
                  Expanded(child: buildFormTextField(label: 'Demirbaş Sayısı', controller: _assetController, placeholder: '0', onChanged: getFormData)),
                  Expanded(child: buildFormTextField(label: 'Otopark Kapasitesi', controller: _parkingController, placeholder: '0', onChanged: getFormData)),
                ]),
                _fieldSpacing,
                buildFormRow([
                  Expanded(
                    child: buildFormTextField(
                      label: 'Enlem (opsiyonel)',
                      controller: _latitudeController,
                      placeholder: '37.87',
                      onChanged: getFormData,
                    ),
                  ),
                  Expanded(
                    child: buildFormTextField(
                      label: 'Boylam (opsiyonel)',
                      controller: _longitudeController,
                      placeholder: '32.48',
                      onChanged: getFormData,
                    ),
                  ),
                ]),
                _fieldSpacing,
                InfoLabel(
                  label: 'Chiller Sistemi',
                  child: ToggleSwitch(
                    checked: _hasChiller,
                    content: const Text('Binada chiller sistemi var'),
                    onChanged: (value) {
                      setState(() => _hasChiller = value);
                      getFormData();
                    },
                  ),
                ),
                _fieldSpacing,
                InfoLabel(
                  label: 'Çalışma Saatleri',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildFormRow([
                        Expanded(child: buildFormTextField(label: 'Hafta İçi Açılış', controller: _workingHoursOpenController, placeholder: '08:00', onChanged: getFormData)),
                        Expanded(child: buildFormTextField(label: 'Hafta İçi Kapanış', controller: _workingHoursCloseController, placeholder: '18:00', onChanged: getFormData)),
                      ]),
                      const SizedBox(height: 12),
                      buildFormRow([
                        Expanded(child: ToggleSwitch(
                          checked: _workingHoursWeekend,
                          content: const Text('Hafta Sonu Açık'),
                          onChanged: (value) {
                            setState(() => _workingHoursWeekend = value);
                            getFormData();
                          },
                        )),
                        Expanded(child: ToggleSwitch(
                          checked: _workingHoursHolidays,
                          content: const Text('Tatillerde Açık'),
                          onChanged: (value) {
                            setState(() => _workingHoursHolidays = value);
                            getFormData();
                          },
                        )),
                      ]),
                            ],
                          ),
                        ),
                _fieldSpacing,
                // Bina Yöneticisi seçimi:
                // Yeni bina oluştururken de seçilebilsin diye tüm aktif çalışanlardan listelenir.
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: EmployeeApiService().getEmployees(isActive: true),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return InfoLabel(
                        label: 'Bina Yöneticisi',
                        child: ProgressRing(),
                      );
                    }

                    if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                      return InfoLabel(
                        label: 'Bina Yöneticisi',
                        child: Text('Aktif çalışan bulunamadı veya yüklenemedi'),
                      );
                    }

                    final employees = snapshot.data!;
                    final selectedEmployee = _selectedManagerId == null
                        ? null
                        : employees.where((e) => e['id']?.toString() == _selectedManagerId).firstOrNull;

                    return InfoLabel(
                      label: 'Bina Yöneticisi',
                      child: ComboBox<Map<String, dynamic>?>(
                        value: selectedEmployee,
                        items: [
                          const ComboBoxItem<Map<String, dynamic>?>(
                            value: null,
                            child: Text('Seçiniz'),
                          ),
                          ...employees.map((employee) {
                            final firstName = employee['first_name']?.toString() ?? '';
                            final lastName = employee['last_name']?.toString() ?? '';
                            final position = employee['position']?.toString() ?? '';
                            final fullName = '$firstName $lastName'.trim();
                            final label = position.isNotEmpty ? '$fullName ($position)' : fullName;

                            return ComboBoxItem<Map<String, dynamic>?>(
                              value: employee,
                              child: Text(label.isEmpty ? 'Adsız Çalışan' : label),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedManagerId = value?['id']?.toString();
                          });
                          getFormData();
                        },
                      ),
                    );
                  },
                ),
                _fieldSpacing,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: buildFormTextField(label: 'Açıklama', controller: _descriptionController, placeholder: 'Bina açıklaması (isteğe bağlı)', maxLines: 3, onChanged: getFormData),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: InfoLabel(
                        label: 'Fotoğraf',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            if (_selectedPhoto != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(FluentIcons.picture, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      (_selectedPhoto as XFile).name,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.typography.caption,
                                          ),
                                  ),
                                  IconButton(
                                    icon: Icon(FluentIcons.chrome_close, size: 16),
                                            onPressed: () {
                                                setState(() {
                                        _selectedPhoto = null;
                                        _photoUrlController.clear();
                                                });
                                                getFormData();
                                            },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            Button(
                              onPressed: _isUploadingPhoto ? null : () => _pickAndUploadPhoto(),
                              child: _isUploadingPhoto
                                  ? const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ProgressRing(),
                                        SizedBox(width: 8),
                                        Text('Yükleniyor...'),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(FluentIcons.picture, size: 16),
                                        SizedBox(width: 6),
                                        Text('Fotoğraf Seç'),
                                      ],
                                    ),
                                  ),
                                ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
        ),
      ),
    );
  }
}
