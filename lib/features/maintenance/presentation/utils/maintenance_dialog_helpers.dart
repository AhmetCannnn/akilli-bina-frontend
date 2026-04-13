import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:belediye_otomasyon/core/utils/modal_helpers.dart'
    show
        buildModalConstraints,
        buildModalTitle,
        showDeleteDialog,
        showErrorDialog,
        showSuccessInfoBar;
import '../providers/maintenance_provider.dart';
import '../screens/add_maintenance_modal.dart';

/// Tam sayfa bakım listesi ve bina detayı bakım sekmesi için ortak düzenle diyaloğu.
Future<void> showEditMaintenanceDialog({
  required WidgetRef ref,
  required BuildContext context,
  required Map<String, dynamic> maintenance,
}) {
  final formKey = GlobalKey<FormState>();
  final maintenanceId = maintenance['id'] as String;
  final modalStateKey = GlobalKey<AddMaintenanceModalState>();

  return showDialog(
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

/// Ortak silme onayı; [maintenance] içinde `id` (String) ve `title` beklenir.
void showDeleteMaintenanceDialog({
  required WidgetRef ref,
  required BuildContext context,
  required Map<String, dynamic> maintenance,
}) {
  final theme = FluentTheme.of(context);
  final maintenanceId = maintenance['id'] as String;
  final title = maintenance['title'] ?? 'Bakım Kaydı';

  showDeleteDialog(
    context: context,
    theme: theme,
    title: 'Bakım Kaydını Sil',
    message: '"$title" kaydını silmek istediğinize emin misiniz?',
    onDelete: () async {
      await ref
          .read(maintenanceControllerProvider.notifier)
          .deleteMaintenance(maintenanceId);
      return true;
    },
    successMessage: '"$title" başarıyla silindi.',
    onSuccess: () {},
  );
}
