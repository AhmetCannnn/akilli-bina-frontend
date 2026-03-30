import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:belediye_otomasyon/features/buildings/data/services/visitor_api_service.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart' show showDeleteDialog, buildModalTitle, buildModalConstraints, showErrorDialog, showSuccessInfoBar, disposeControllers, buildFullName;
import 'package:belediye_otomasyon/core/utils/api_error.dart' show humanizeError;
import 'package:belediye_otomasyon/core/utils/form_field_helpers.dart' show buildFormTextField, buildFormComboBox, buildFormRow;
import '../../utils/building_helpers.dart' show formatDuration, getVisitPurposes, nowHHmm, formatDateToYyyyMmDd;
import '../../utils/detail_widgets.dart';
import '../../utils/form_validators.dart' show validateVisitorForm;



/// Ziyaretçi ekleme/düzenleme modalı
void showAddVisitorModal({
  required BuildContext context,
  required FluentThemeData theme,
  required int buildingId,
  required DateTime selectedDay,
  required VoidCallback onSuccess,
  Map<String, dynamic>? visitor,
}) {
  final isEdit = visitor != null;
  final formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController(text: visitor?['first_name'] ?? '');
  final lastNameController = TextEditingController(text: visitor?['last_name'] ?? '');
  final phoneController = TextEditingController(text: visitor?['phone'] ?? '');
  final emailController = TextEditingController(text: visitor?['email'] ?? '');

  // Saatler için controller'lar
  final entryTimeController = TextEditingController(
    text: visitor?['entry_time'] ?? nowHHmm(),
  );
  final exitTimeController = TextEditingController(text: visitor?['exit_time'] ?? '');

  String selectedPurpose = visitor?['visit_purpose'] ?? 'Randevu';
  final purposes = getVisitPurposes();

  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ContentDialog(
      constraints: buildModalConstraints(ctx, maxWidth: 800.0),
      title: buildModalTitle(isEdit ? 'Ziyaretçi Düzenle' : 'Yeni Ziyaretçi Ekle', ctx),
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
                              label: 'Ad',
                              controller: firstNameController,
                              placeholder: 'Ad',
                            ),
                          ),
                          Expanded(
                            child: buildFormTextField(
                              label: 'Soyad',
                              controller: lastNameController,
                              placeholder: 'Soyad',
                            ),
                          ),
                        ]),
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

                        // E-posta
                        buildFormTextField(
                          label: 'E-posta (Opsiyonel)',
                          controller: emailController,
                          placeholder: 'ornek@email.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Ziyaret Amacı
                        buildFormComboBox<String>(
                          label: 'Ziyaret Amacı',
                          value: selectedPurpose,
                          items: purposes,
                          displayText: (p) => p,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedPurpose = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Giriş Saati
                        buildFormTextField(
                          label: 'Giriş Saati *',
                          controller: entryTimeController,
                          placeholder: 'HH:MM (örn: 14:30)',
                          suffix: Icon(FluentIcons.clock),
                        ),
                        const SizedBox(height: 16),

                        // Çıkış Saati (Opsiyonel)
                        buildFormTextField(
                          label: 'Çıkış Saati (Opsiyonel)',
                          controller: exitTimeController,
                          placeholder: 'HH:MM (örn: 17:00)',
                          suffix: Icon(FluentIcons.clock),
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
                    child: Text(isEdit ? 'Kaydet' : 'Ekle'),
                    onPressed: () async {
                      // Validasyon kontrolü
                      if (validateVisitorForm(
                        phone: phoneController.text,
                        email: emailController.text.trim().isNotEmpty
                            ? emailController.text
                            : null,
                        entryTime: entryTimeController.text,
                        exitTime: exitTimeController.text.trim().isNotEmpty
                            ? exitTimeController.text
                            : null,
                        context: context,
                        theme: theme,
                      )) {
                        return; // Hata mesajı zaten gösterildi
                      }

                      try {
                        if (isEdit) {
                          // Düzenleme
                          final visitorData = {
                            'first_name': firstNameController.text.trim(),
                            'last_name': lastNameController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'email': emailController.text.trim().isEmpty
                                ? null
                                : emailController.text.trim(),
                            'entry_time': entryTimeController.text.trim(),
                            'visit_purpose': selectedPurpose,
                          };

                          // Çıkış saati varsa ekle
                          if (exitTimeController.text.trim().isNotEmpty) {
                            visitorData['exit_time'] = exitTimeController.text.trim();
                          }

                          final success = await VisitorApiService().updateVisitor(
                            visitor!['id'].toString(),
                            visitorData,
                          );
                          if (success != null) {
                            disposeControllers([
                              firstNameController,
                              lastNameController,
                              phoneController,
                              emailController,
                              entryTimeController,
                              exitTimeController,
                            ]);
                            if (context.mounted) {
                              Navigator.pop(context, true);
                            }
                            onSuccess(); // Listeyi yenile
                          }
                        } else {
                          // Ekleme
                          final visitorData = {
                            'building_id': buildingId,
                            'first_name': firstNameController.text.trim(),
                            'last_name': lastNameController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'email': emailController.text.trim().isEmpty
                                ? null
                                : emailController.text.trim(),
                            'visit_date': formatDateToYyyyMmDd(selectedDay),
                            'entry_time': entryTimeController.text.trim(),
                            'visit_purpose': selectedPurpose,
                          };

                          // Çıkış saati varsa ekle
                          if (exitTimeController.text.trim().isNotEmpty) {
                            visitorData['exit_time'] = exitTimeController.text.trim();
                          }

                          final success =
                              await VisitorApiService().createVisitor(visitorData);
                          if (success != null) {
                            disposeControllers([
                              firstNameController,
                              lastNameController,
                              phoneController,
                              emailController,
                              entryTimeController,
                              exitTimeController,
                            ]);
                            if (context.mounted) {
                              Navigator.pop(context, true);
                            }
                            onSuccess(); // Listeyi yenile
                          }
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
      showSuccessInfoBar(
        context,
        isEdit ? 'Ziyaretçi başarıyla güncellendi!' : 'Ziyaretçi başarıyla eklendi!',
      );
    }
  });
}

/// Ziyaretçi çıkış modalı
void showCheckoutModal({
  required BuildContext context,
  required FluentThemeData theme,
  required Map<String, dynamic> visitor,
  required VoidCallback onSuccess,
}) {
  final visitorName = buildFullName(visitor);
  final entryTime = visitor['entry_time'] as String? ?? '';
  final exitTime = nowHHmm();

  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ContentDialog(
      constraints: BoxConstraints(
        maxWidth: 450.0,
      ),
      title: buildModalTitle('Ziyaretçi Çıkışı', ctx),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$visitorName ziyaretçisinin çıkışını onaylıyor musunuz?',
            style: theme.typography.body,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.accentColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FluentIcons.clock, size: 16, color: theme.accentColor),
                    const SizedBox(width: 8),
                    Text(
                      'Giriş Saati: $entryTime',
                      style: theme.typography.body?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(FluentIcons.clock, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Çıkış Saati: $exitTime',
                      style: theme.typography.body?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              FilledButton(
                child: Text('Çıkış Yap'),
                style: ButtonStyle(
                  backgroundColor: ButtonState.all(Colors.red),
                  foregroundColor: ButtonState.all(Colors.white),
                ),
                onPressed: () async {
                  try {
                    final success = await VisitorApiService().checkoutVisitor(
                      visitor['id'].toString(),
                      DateTime.now(),
                    );

                    if (success) {
                      if (ctx.mounted) {
                        Navigator.pop(ctx, true);
                      }
                      onSuccess(); // Listeyi yenile
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      showErrorDialog(ctx, theme, 'Hata', humanizeError(e));
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
  ).then((isCheckedOut) {
    if (isCheckedOut == true && context.mounted) {
      showSuccessInfoBar(context, 'Ziyaretçi çıkışı başarıyla yapıldı!');
    }
  });
}


/// Ziyaretçi silme dialog'u
void showDeleteVisitorDialog({
  required BuildContext context,
  required FluentThemeData theme,
  required Map<String, dynamic> visitor,
  required VoidCallback onSuccess,
}) {
  final itemName = buildFullName(visitor, defaultName: 'Bu ziyaretçi');

  showDeleteDialog(
    context: context,
    theme: theme,
    title: 'Ziyaretçiyi Sil',
    message: '$itemName silmek istediğinize emin misiniz?',
    onDelete: () => VisitorApiService().deleteVisitor(visitor['id'].toString()),
    successMessage: 'Ziyaretçi başarıyla silindi!',
    onSuccess: onSuccess,
  );
}

/// Ziyaretçi detay modalı
void showVisitorDetail({
  required BuildContext context,
  required FluentThemeData theme,
  required Map<String, dynamic> visitor,
  required VoidCallback onEdit,
}) {
  final entryTime = visitor['entry_time'] as String? ?? '';
  final exitTime = visitor['exit_time'] as String? ?? '';
  final isActive = exitTime.isEmpty;
  final visitDuration = visitor['visit_duration'] != null ? formatDuration(visitor['visit_duration']) : '';

  showDialog(
    context: context,
    builder: (context) => ContentDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isActive ? FluentIcons.people : FluentIcons.check_mark,
              color: isActive ? Colors.green : Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${visitor['first_name']} ${visitor['last_name']}',
                  style: theme.typography.title?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Aktif Ziyaretçi',
                      style: theme.typography.caption?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İletişim Bilgileri
            buildDetailSection(
              theme,
              'İletişim Bilgileri',
              FluentIcons.contact,
              [
                buildDetailRow('Telefon', visitor['phone'] ?? ''),
                if (visitor['email'] != null) buildDetailRow('E-posta', visitor['email']),
              ],
            ),

            const SizedBox(height: 20),

            // Ziyaret Bilgileri
            buildDetailSection(
              theme,
              'Ziyaret Bilgileri',
              FluentIcons.calendar,
              [
                buildDetailRow('Tarih', visitor['visit_date'] ?? ''),
                buildDetailRow('Giriş', entryTime),
                if (exitTime.isNotEmpty) buildDetailRow('Çıkış', exitTime),
                if (visitDuration.isNotEmpty) buildDetailRow('Süre', visitDuration),
                buildDetailRow('Amaç', visitor['visit_purpose'] ?? ''),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Button(
          child: Text('Kapat'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
