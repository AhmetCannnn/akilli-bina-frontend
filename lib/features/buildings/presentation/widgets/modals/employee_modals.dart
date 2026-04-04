import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:belediye_otomasyon/features/employees/data/services/employee_api_service.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart' show buildModalTitle, buildModalConstraints, showErrorDialog, showSuccessInfoBar, showDeleteDialog, disposeControllers, buildFullName;
import 'package:belediye_otomasyon/core/utils/api_error.dart' show humanizeError;
import 'package:belediye_otomasyon/core/utils/form_field_helpers.dart' show buildFormTextField, buildFormRow;
import '../../utils/form_validators.dart' show validateEmployeeForm;


/// Çalışan ekleme modalı
void showAddEmployeeModal({
  required BuildContext context,
  required FluentThemeData theme,
  int? buildingId,
  List<Map<String, dynamic>>? buildings,
  required Function(Map<String, dynamic>) onSuccess,
}) {
  final formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final positionController = TextEditingController();
  final hireDateController = TextEditingController();
  int? selectedBuildingId = buildingId;

  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ContentDialog(
      constraints: buildModalConstraints(ctx, maxWidth: 800.0),
      title: buildModalTitle('Yeni Çalışan Ekle', ctx),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (buildings != null) ...[
                          InfoLabel(
                            label: 'Bina *',
                            child: ComboBox<int>(
                              value: selectedBuildingId,
                              isExpanded: true,
                              placeholder: const Text('Bina seçin'),
                              items: [
                                for (final b in buildings)
                                  ComboBoxItem<int>(
                                    value: b['id'] as int,
                                    child: Text(
                                      (b['name'] ?? 'İsimsiz Bina').toString(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) => setState(() {
                                selectedBuildingId = v;
                              }),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Ad Soyad
                        buildFormRow([
                          Expanded(
                            child: buildFormTextField(
                              label: 'Ad *',
                              controller: firstNameController,
                              placeholder: 'Ad',
                            ),
                          ),
                          Expanded(
                            child: buildFormTextField(
                              label: 'Soyad *',
                              controller: lastNameController,
                              placeholder: 'Soyad',
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // E-posta
                        buildFormTextField(
                          label: 'E-posta *',
                          controller: emailController,
                          placeholder: 'ornek@email.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Telefon
                        buildFormTextField(
                          label: 'Telefon *',
                          controller: phoneController,
                          placeholder: '05321234567',
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Pozisyon
                        buildFormTextField(
                          label: 'Pozisyon *',
                          controller: positionController,
                          placeholder: 'Örn: Güvenlik Görevlisi',
                        ),
                        const SizedBox(height: 16),

                        // İşe Başlama Tarihi (Opsiyonel)
                        buildFormTextField(
                          label: 'İşe Başlama Tarihi (Opsiyonel)',
                          controller: hireDateController,
                          placeholder: 'YYYY-MM-DD (örn: 2024-01-15)',
                          suffix: Icon(FluentIcons.calendar),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  FilledButton(
                    child: Text('Ekle'),
                    onPressed: () async {
                      if (selectedBuildingId == null) {
                        showErrorDialog(
                          context,
                          theme,
                          'Eksik Bilgi',
                          'Lütfen bir bina seçin.',
                        );
                        return;
                      }

                      // Validasyon kontrolü
                      final hasError = validateEmployeeForm(
                        firstName: firstNameController.text,
                        lastName: lastNameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                        position: positionController.text,
                        hireDate: hireDateController.text.trim().isNotEmpty
                            ? hireDateController.text.trim()
                            : null,
                        context: context,
                        theme: theme,
                      );

                      if (hasError) {
                        return; // Hata mesajı zaten gösterildi
                      }

                      String? hireDate;
                      if (hireDateController.text.trim().isNotEmpty) {
                        hireDate = hireDateController.text.trim();
                      }

                      final employeeData = {
                        'building_id': selectedBuildingId,
                        'first_name': firstNameController.text.trim(),
                        'last_name': lastNameController.text.trim(),
                        'email': emailController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'position': positionController.text.trim(),
                        'is_active': true,
                      };

                      if (hireDate != null) {
                        employeeData['hire_date'] = hireDate;
                      }

                      try {
                        final newEmployee =
                            await EmployeeApiService().createEmployee(employeeData);
                        if (newEmployee != null) {
                          disposeControllers([
                            firstNameController,
                            lastNameController,
                            emailController,
                            phoneController,
                            positionController,
                            hireDateController,
                          ]);
                          if (context.mounted) {
                            Navigator.pop(context, true);
                          }
                          onSuccess(newEmployee); // Yeni çalışanı direkt ekle
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showErrorDialog(context, theme, 'Hata', humanizeError(e));
                        }
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
    ),
  ).then((isSaved) {
    if (isSaved == true && context.mounted) {
      showSuccessInfoBar(context, 'Çalışan başarıyla eklendi!');
    }
  });
}

/// Çalışan detay modalı
void showEmployeeDetailModal({
  required BuildContext context,
  required FluentThemeData theme,
  required Map<String, dynamic> employee,
  required VoidCallback onEdit,
}) {
  final fullName = buildFullName(employee, defaultName: 'İsimsiz Çalışan');
  final hireDate = employee['hire_date'] != null
      ? DateTime.tryParse(employee['hire_date'].toString())?.toString().split(' ')[0]
      : null;

  showDialog(
    context: context,
    builder: (ctx) => ContentDialog(
      constraints: const BoxConstraints(
        maxWidth: 600,
        minWidth: 500,
      ),
      title: SizedBox(
        height: 40,
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(FluentIcons.contact, color: theme.accentColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fullName,
                    style: theme.typography.bodyStrong,
                  ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (employee['position'] != null && employee['position'].toString().isNotEmpty) ...[
              InfoLabel(
                label: 'Pozisyon',
                child: Text(employee['position'] ?? ''),
              ),
              const SizedBox(height: 16),
            ],
            if (employee['email'] != null && employee['email'].toString().isNotEmpty) ...[
              InfoLabel(
                label: 'E-posta',
                child: Text(employee['email'] ?? ''),
              ),
              const SizedBox(height: 16),
            ],
            if (employee['phone'] != null && employee['phone'].toString().isNotEmpty) ...[
              InfoLabel(
                label: 'Telefon',
                child: Text(employee['phone'] ?? ''),
              ),
              const SizedBox(height: 16),
            ],
            if (hireDate != null) ...[
              InfoLabel(
                label: 'İşe Başlama Tarihi',
                child: Text(hireDate),
              ),
              const SizedBox(height: 16),
            ],
            InfoLabel(
              label: 'Durum',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (employee['is_active'] ?? true)
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (employee['is_active'] ?? true)
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  (employee['is_active'] ?? true) ? 'Aktif' : 'Pasif',
                  style: theme.typography.body?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: (employee['is_active'] ?? true) ? Colors.green : Colors.red,
                  ),
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

/// Çalışan düzenleme modalı
void showEditEmployeeModal({
  required BuildContext context,
  required FluentThemeData theme,
  required Map<String, dynamic> employee,
  required Function(Map<String, dynamic>) onSuccess,
}) {
  final formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController(text: employee['first_name'] ?? '');
  final lastNameController = TextEditingController(text: employee['last_name'] ?? '');
  final emailController = TextEditingController(text: employee['email'] ?? '');
  final phoneController = TextEditingController(text: employee['phone'] ?? '');
  final positionController = TextEditingController(text: employee['position'] ?? '');
  final hireDateController = TextEditingController(
    text: employee['hire_date'] != null
        ? DateTime.tryParse(employee['hire_date'].toString())?.toString().split(' ')[0] ?? ''
        : '',
  );
  bool isActive = employee['is_active'] ?? true;

  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ContentDialog(
      constraints: buildModalConstraints(ctx, maxWidth: 800.0),
      title: buildModalTitle('Çalışan Düzenle', ctx),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Ad Soyad
                        buildFormRow([
                          Expanded(
                            child: buildFormTextField(
                              label: 'Ad *',
                              controller: firstNameController,
                              placeholder: 'Ad',
                            ),
                          ),
                          Expanded(
                            child: buildFormTextField(
                              label: 'Soyad *',
                              controller: lastNameController,
                              placeholder: 'Soyad',
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // E-posta
                        buildFormTextField(
                          label: 'E-posta *',
                          controller: emailController,
                          placeholder: 'ornek@email.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Telefon
                        buildFormTextField(
                          label: 'Telefon *',
                          controller: phoneController,
                          placeholder: '05321234567',
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Pozisyon
                        buildFormTextField(
                          label: 'Pozisyon *',
                          controller: positionController,
                          placeholder: 'Örn: Güvenlik Görevlisi',
                        ),
                        const SizedBox(height: 16),

                        // İşe Başlama Tarihi (Opsiyonel)
                        buildFormTextField(
                          label: 'İşe Başlama Tarihi (Opsiyonel)',
                          controller: hireDateController,
                          placeholder: 'YYYY-MM-DD (örn: 2024-01-15)',
                          suffix: Icon(FluentIcons.calendar),
                        ),
                        const SizedBox(height: 16),

                        // Durum
                        InfoLabel(
                          label: 'Durum',
                          child: ToggleSwitch(
                            checked: isActive,
                            content: Text(isActive ? 'Aktif' : 'Pasif'),
                            onChanged: (value) {
                              setState(() {
                                isActive = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  FilledButton(
                    child: Text('Kaydet'),
                    onPressed: () async {
                      // Validasyon kontrolü
                      final hasError = validateEmployeeForm(
                        firstName: firstNameController.text,
                        lastName: lastNameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                        position: positionController.text,
                        hireDate: hireDateController.text.trim().isNotEmpty
                            ? hireDateController.text.trim()
                            : null,
                        context: context,
                        theme: theme,
                      );

                      if (hasError) {
                        return; // Hata mesajı zaten gösterildi
                      }

                      String? hireDate;
                      if (hireDateController.text.trim().isNotEmpty) {
                        hireDate = hireDateController.text.trim();
                      }

                      final employeeData = {
                        'first_name': firstNameController.text.trim(),
                        'last_name': lastNameController.text.trim(),
                        'email': emailController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'position': positionController.text.trim(),
                        'is_active': isActive,
                      };

                      if (hireDate != null) {
                        employeeData['hire_date'] = hireDate;
                      }

                      try {
                        final updatedEmployee = await EmployeeApiService().updateEmployee(
                          employee['id'].toString(),
                          employeeData,
                        );
                        if (updatedEmployee != null) {
                          disposeControllers([
                            firstNameController,
                            lastNameController,
                            emailController,
                            phoneController,
                            positionController,
                            hireDateController,
                          ]);
                          if (context.mounted) {
                            Navigator.pop(context, true);
                          }
                          onSuccess(updatedEmployee); // Güncellenmiş çalışanı direkt güncelle
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showErrorDialog(context, theme, 'Hata', humanizeError(e));
                        }
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
    ),
  ).then((isSaved) {
    if (isSaved == true && context.mounted) {
      showSuccessInfoBar(context, 'Çalışan başarıyla güncellendi!');
    }
  });
}

/// Çalışan silme dialog'u
void showDeleteEmployeeDialog({
  required BuildContext context,
  required FluentThemeData theme,
  required Map<String, dynamic> employee,
  required Function(String) onSuccess, // Silinen çalışanın ID'sini geçir
}) {
  final itemName = buildFullName(employee, defaultName: 'Bu çalışan');
  final employeeId = employee['id'].toString();

  showDeleteDialog(
    context: context,
    theme: theme,
    title: 'Çalışanı Sil',
    message: '$itemName silmek istediğinize emin misiniz?',
    onDelete: () => EmployeeApiService().deleteEmployee(employeeId),
    successMessage: 'Çalışan başarıyla silindi!',
    onSuccess: () => onSuccess(employeeId), // Silinen çalışanın ID'sini callback'e geçir
  );
}

