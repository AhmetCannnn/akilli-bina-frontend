import 'package:fluent_ui/fluent_ui.dart';

/// Bina tipi enum'ı
enum BuildingType {
  komek,
  museum,
  service;

  String get name {
    switch (this) {
      case BuildingType.komek:
        return 'KOMEK';
      case BuildingType.museum:
        return 'Müze';
      case BuildingType.service:
        return 'Hizmet Binası';
    }
  }

  /// UI için icon getter'ı
  IconData get icon {
    switch (this) {
      case BuildingType.komek:
        return FluentIcons.reading_mode;
      case BuildingType.museum:
        return FluentIcons.library;
      case BuildingType.service:
        return FluentIcons.city_next;
    }
  }

  /// UI için color getter'ı
  Color get color {
    switch (this) {
      case BuildingType.komek:
        return Colors.blue;
      case BuildingType.museum:
        return Colors.orange;
      case BuildingType.service:
        return Colors.teal;
    }
  }
}

/// Güvenli string listesi dönüştürme fonksiyonu
/// Dynamic listeleri String listesine dönüştürür
List<String> safeStringList(dynamic data) {
  if (data == null) return [];
  if (data is List<String>) return data;
  if (data is List) {
    return data
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return [];
}

/// Ziyaret süresini formatlar
String formatDuration(dynamic duration) {
  if (duration == null) return '';
  
  // Eğer string ise direkt döndür
  if (duration is String) return duration;
  
  // Eğer int ise (saniye cinsinden) dakikaya çevir
  if (duration is int) {
    final minutes = duration ~/ 60;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '$hours saat $remainingMinutes dakika';
    } else {
      return '$minutes dakika';
    }
  }
  
  // Eğer double ise
  if (duration is double) {
    final minutes = duration.toInt() ~/ 60;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '$hours saat $remainingMinutes dakika';
    } else {
      return '$minutes dakika';
    }
  }
  
  return duration.toString();
}

/// Bakım tipini Türkçe'ye çevirir
String getMaintenanceTypeText(String type) {
  switch (type) {
    case 'rutin':
      return 'Rutin';
    case 'acil':
      return 'Acil';
    case 'planlı':
      return 'Planlı';
    default:
      return type;
  }
}

/// Ziyaret amacı seçeneklerini getirir
List<String> getVisitPurposes() {
  return [
    'Randevu',
    'Toplantı',
    'Teslimat',
    'Bakım/Onarım',
    'Eğitim',
    'Sosyal Ziyaret',
    'Resmi İşlem',
    'Diğer',
  ];
}

/// Şu anki saati HH:MM formatında döndürür
String nowHHmm() {
  final now = DateTime.now();
  final hh = now.hour.toString().padLeft(2, '0');
  final mm = now.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// DateTime'ı YYYY-MM-DD formatına çevirir
String formatDateToYyyyMmDd(DateTime date) {
  return date.toIso8601String().split('T')[0];
}
