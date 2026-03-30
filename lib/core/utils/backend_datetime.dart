/// Backend tarihleri UTC kaydeder (FastAPI / PostgreSQL).
/// [DateTime.parse] timezone yoksa değeri yerel sanır; Web'de [toLocal] da bazen UTC ile aynı kalır.
///
/// Türkiye için sabit **UTC+3** (yaz saati yok) uygulanır; böylece 13:16 UTC → 16:16 gösterilir.
/// Çok bölgeli ürün için ileride `.env` / ayar ile değiştirilebilir.
const Duration _displayTimezoneOffsetFromUtc = Duration(hours: 3);

DateTime parseBackendDateTime(String? raw) {
  if (raw == null || raw.isEmpty) return DateTime.now();
  var s = raw.trim();
  if (s.contains(' ') && !s.contains('T')) {
    final t = s.indexOf(' ');
    if (t > 0) {
      s = '${s.substring(0, t)}T${s.substring(t + 1)}';
    }
  }
  final hasTz = s.endsWith('Z') ||
      RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s);
  final toParse = hasTz ? s : '${s}Z';
  final parsed = DateTime.tryParse(toParse);
  if (parsed == null) return DateTime.now();
  final utcInstant = parsed.toUtc();
  return utcInstant.add(_displayTimezoneOffsetFromUtc);
}
