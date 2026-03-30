import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show TextEditingController;

/// Modal başlığı oluştur (kapatma butonu ile)
Widget buildModalTitle(String title, BuildContext ctx) {
  return SizedBox(
    height: 40,
    child: Stack(
      children: [
        Center(child: Text(title)),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: IconButton(
            icon: Icon(FluentIcons.chrome_close, color: Colors.red),
            onPressed: () => Navigator.pop(ctx, false),
          ),
        ),
      ],
    ),
  );
}

/// Modal constraints'ini oluştur (genel kullanım için)
BoxConstraints buildModalConstraints(BuildContext ctx, {double maxWidth = 1200.0}) {
  return BoxConstraints(
    maxWidth: (MediaQuery.of(ctx).size.width - 96)
        .clamp(0.0, maxWidth)
        .toDouble(),
  );
}

/// Başarı mesajı göster (InfoBar ile)
void showSuccessInfoBar(BuildContext context, String message) {
  displayInfoBar(
    context,
    alignment: Alignment.topCenter,
    builder: (c, close) => InfoBar(
      title: const Text('Başarılı'),
      content: Text(message),
      severity: InfoBarSeverity.success,
      onClose: close,
    ),
  );
}

/// Hata mesajı göster (InfoBar ile)
void showErrorInfoBar(BuildContext context, String message) {
  displayInfoBar(
    context,
    alignment: Alignment.topCenter,
    builder: (c, close) => InfoBar(
      title: const Text('Hata'),
      content: Text(message),
      severity: InfoBarSeverity.error,
      onClose: close,
    ),
  );
}

/// Error dialog gösterir
void showErrorDialog(
  BuildContext context,
  FluentThemeData theme,
  String title,
  String message,
) {
  showDialog(
    context: context,
    builder: (context) => ContentDialog(
      title: Row(
        children: [
          Icon(FluentIcons.error, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        Button(
          child: Text('Tamam'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

/// Success dialog gösterir
void showSuccessDialog(
  BuildContext context,
  FluentThemeData theme,
  String title,
  String message,
) {
  showDialog(
    context: context,
    builder: (context) => ContentDialog(
      title: Row(
        children: [
          Icon(FluentIcons.check_mark, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        Button(
          child: Text('Tamam'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

/// Error card widget'ı oluşturur
Widget buildErrorCard(
  FluentThemeData theme, [
  String? errorMessage,
]) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            FluentIcons.warning,
            size: 48,
            color: theme.iconTheme.color?.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'Veri yüklenemedi',
            style: theme.typography.body?.copyWith(
              color: theme.iconTheme.color?.withOpacity(0.7),
            ),
          ),
          if (errorMessage == null) ...[
            const SizedBox(height: 4),
            Text(
              'Backend\'den veri alınamadı',
              style: theme.typography.caption?.copyWith(
                color: theme.iconTheme.color?.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Genel silme dialog'u - tüm proje genelinde kullanılabilir
/// 
/// Kullanım örneği:
/// ```dart
/// showDeleteDialog(
///   context: context,
///   theme: FluentTheme.of(context),
///   title: 'Çalışanı Sil',
///   message: 'Bu çalışanı silmek istediğinize emin misiniz?',
///   onDelete: () => EmployeeApiService().deleteEmployee(id),
///   successMessage: 'Çalışan başarıyla silindi!',
///   onSuccess: () => refreshList(),
/// );
/// ```
void showDeleteDialog({
  required BuildContext context,
  required FluentThemeData theme,
  required String title,
  required String message,
  required Future<bool> Function() onDelete,
  required String successMessage,
  VoidCallback? onSuccess,
  double maxWidth = 450.0,
}) {
  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ContentDialog(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
      ),
      title: buildModalTitle(title, ctx),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(FluentIcons.warning, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.typography.body,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              FilledButton(
                child: Text('Sil'),
                style: ButtonStyle(
                  backgroundColor: ButtonState.all(Colors.red),
                ),
                onPressed: () async {
                  try {
                    final success = await onDelete();
                    // Başarılı olsun ya da olmasın dialog'u kapat; başarı durumunu geri döndür.
                    if (ctx.mounted) {
                      Navigator.pop(ctx, success);
                    }
                    if (success) {
                      onSuccess?.call(); // Listeyi yenile
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      Navigator.pop(ctx, false);
                      final errorMessage =
                          e.toString().replaceFirst('Exception: ', '');
                      showErrorDialog(ctx, theme, 'Hata', errorMessage);
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
  ).then((isDeleted) {
    if (isDeleted == true && context.mounted) {
      displayInfoBar(
        context,
        alignment: Alignment.topCenter,
        builder: (c, close) => InfoBar(
          title: const Text('Başarılı'),
          content: Text(successMessage),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      );
    }
  });
}

/// Tüm controller'ları dispose eder (genel kullanım için)
void disposeControllers(List<TextEditingController> controllers) {
  for (final controller in controllers) {
    controller.dispose();
  }
}

/// Ad ve soyadı birleştirir (genel kullanım için)
String buildFullName(Map<String, dynamic> data, {String defaultName = 'İsimsiz'}) {
  final firstName = data['first_name']?.toString() ?? '';
  final lastName = data['last_name']?.toString() ?? '';
  final fullName = '$firstName $lastName'.trim();
  return fullName.isNotEmpty ? fullName : defaultName;
}

