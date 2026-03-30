import 'package:belediye_otomasyon/core/utils/modal_helpers.dart' show showErrorDialog;
import 'package:fluent_ui/fluent_ui.dart';

/// E-posta validasyon regex'i
final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

/// Saat formatı validasyon regex'i (HH:MM)
final RegExp _timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');

/// Tarih formatı validasyon regex'i (YYYY-MM-DD)
final RegExp _dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Çalışan form validasyonu
/// Hata varsa true döner (hata zaten dialog ile gösterilmiş), başarılıysa false döner
bool validateEmployeeForm({
  required String firstName,
  required String lastName,
  required String email,
  required String phone,
  required String position,
  String? hireDate,
  required BuildContext context,
  required FluentThemeData theme,
}) {
  if (firstName.trim().isEmpty) {
    showErrorDialog(context, theme, 'Hata', 'Ad alanı boş olamaz.');
    return true; // Hata var
  }

  if (lastName.trim().isEmpty) {
    showErrorDialog(context, theme, 'Hata', 'Soyad alanı boş olamaz.');
    return true; // Hata var
  }

  if (email.trim().isEmpty) {
    showErrorDialog(context, theme, 'Hata', 'E-posta alanı boş olamaz.');
    return true; // Hata var
  }

  if (!_emailRegex.hasMatch(email.trim())) {
    showErrorDialog(context, theme, 'Hata', 'Geçerli bir e-posta adresi giriniz.');
    return true; // Hata var
  }

  if (phone.trim().isEmpty) {
    showErrorDialog(context, theme, 'Hata', 'Telefon alanı boş olamaz.');
    return true; // Hata var
  }

  if (phone.trim().length < 10) {
    showErrorDialog(context, theme, 'Hata', 'Telefon numarası en az 10 rakam olmalıdır.');
    return true; // Hata var
  }

  if (phone.trim().length > 15) {
    showErrorDialog(context, theme, 'Hata', 'Telefon numarası en fazla 15 rakam olabilir.');
    return true; // Hata var
  }

  if (position.trim().isEmpty) {
    showErrorDialog(context, theme, 'Hata', 'Pozisyon alanı boş olamaz.');
    return true; // Hata var
  }

  // Tarih formatı kontrolü (eğer girildiyse)
  if (hireDate != null && hireDate.trim().isNotEmpty) {
    if (!_dateRegex.hasMatch(hireDate.trim())) {
      showErrorDialog(context, theme, 'Hata', 'Tarih formatı YYYY-MM-DD olmalıdır (örn: 2024-01-15).');
      return true; // Hata var
    }
  }

  return false; // Validasyon başarılı
}

/// Ziyaretçi form validasyonu
/// Hata varsa true döner (hata zaten dialog ile gösterilmiş), başarılıysa false döner
bool validateVisitorForm({
  required String phone,
  String? email,
  String? entryTime,
  String? exitTime,
  required BuildContext context,
  required FluentThemeData theme,
}) {
  if (phone.trim().isEmpty) {
    showErrorDialog(context, theme, 'Hata', 'Telefon alanı boş olamaz.');
    return true; // Hata var
  }

  if (phone.trim().length < 10) {
    showErrorDialog(context, theme, 'Hata', 'Telefon numarası en az 10 rakam olmalıdır.');
    return true; // Hata var
  }

  if (phone.trim().length > 15) {
    showErrorDialog(context, theme, 'Hata', 'Telefon numarası en fazla 15 rakam olabilir.');
    return true; // Hata var
  }

  // E-posta formatı kontrolü (eğer girildiyse)
  if (email != null && email.trim().isNotEmpty) {
    if (!_emailRegex.hasMatch(email.trim())) {
      showErrorDialog(context, theme, 'Hata', 'Geçerli bir e-posta adresi giriniz.');
      return true; // Hata var
    }
  }

  // Giriş saati kontrolü
  if (entryTime != null && entryTime.trim().isNotEmpty) {
    if (!_timeRegex.hasMatch(entryTime.trim())) {
      showErrorDialog(context, theme, 'Hata', 'Giriş saati HH:MM formatında olmalıdır (örn: 14:30).');
      return true; // Hata var
    }
  }

  // Çıkış saati kontrolü (eğer girildiyse)
  if (exitTime != null && exitTime.trim().isNotEmpty) {
    if (!_timeRegex.hasMatch(exitTime.trim())) {
      showErrorDialog(context, theme, 'Hata', 'Çıkış saati HH:MM formatında olmalıdır (örn: 17:00).');
      return true; // Hata var
    }
  }

  return false; // Validasyon başarılı
}
