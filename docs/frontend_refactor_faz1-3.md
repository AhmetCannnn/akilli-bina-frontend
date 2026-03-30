# Frontend Refactor Planı — Faz 1-3

Bu doküman, mevcut Feature-First yapıyı toparlamak ve kod kalitesini artırmak için ilk üç fazda yapılacak işleri özetler. Her adım sonunda uygulama derlenebilir durumda olmalı.

## Kapsam ve Varsayımlar
- Hedef platform: Flutter + Fluent UI (Material kalıntıları temizlenecek).
- Devam eden iş: `lib/features` altında feature-first hiyerarşisi korunacak.
- Çalışan routing: `core/router/app_router.dart` (GoRouter).

## Mevcut Başlıca Problemler (referans)
- Çift dosyalar: `lib/providers/theme_provider.dart` ve `lib/core/theme/theme_provider.dart`; `lib/theme/app_theme.dart` ve `lib/core/theme/app_theme.dart`.
- Model kopyası: `features/home/domain/models/building.dart` vs `features/buildings/domain/models/building.dart`.
- Uzun dosya: `features/buildings/presentation/screens/building_detail_screen.dart` (~943 satır).
- Kalan Material importları ve boş/atıl core klasörleri.

## Faz 1 — Temizlik ve Duplicate Kaldırma
**Amaç:** Çakışan theme ve model dosyalarını tekilleştirip importları düzeltmek, Material kalıntılarını temizlemek.

İş Listesi
- Theme tekilleştirme: Fluent temayı kanonik hale getir (`core/theme/app_theme.dart` önerilir), diğer kopyayı kaldır; tüm importları güncelle.
- Theme provider tekilleştirme: Tek dosya (`core/theme/theme_provider.dart` önerilir); diğer kopyayı sil; GoRouter girişleri ve ekran importlarını güncelle.
- Building modeli: Home içindeki modeli kaldır veya `buildings` domain’e yönlendir; ilgili kullanımlarını düzelt.
- Material kalıntıları: Fluent UI kullanılan ekranlarda gereksiz `material.dart` importlarını temizle.

Kontrol Listesi
- `flutter analyze` temiz.
- `flutter run -d chrome` (veya mevcut hedef) ile açılış akışı (login -> shell -> home) çalışıyor.
- GoRouter rotaları theme importlarını doğru görüyor.

Çıktılar
- Güncel tema/provider dosyaları.
- Temizlenmiş importlar ve tekil building model kullanımı.

## Faz 2 — Core Düzenleme
**Amaç:** Core içindeki atıl klasör/dosyaları düzenlemek ve import yollarını standardize etmek.

İş Listesi
- Boş/atıl klasörler: `core/constants`, `core/presentation/widgets`, `core/providers` için ya içerik ekle ya da kaldır.
- Core servislerinin yeri: `core/services/api_service.dart` konumu korunacak, diğer servisler feature’lara taşınmış; doğrulanacak.
- Import standardizasyonu: `belediye_otomasyon/core/...` yolu ile tutarlılık; relatif import kaçınılacak.
- Ortak util’ler: `core/utils/delete_dialog.dart` ve benzerleri için kullanıldığı yerler gözden geçirilecek; Fluent uyumluluğu doğrulanacak.

Kontrol Listesi
- `flutter analyze` temiz.
- Core’dan silinen/taşınan dosyalar için kırık import kalmadı.

Çıktılar
- Temizlenmiş core hiyerarşisi.
- Standartlaştırılmış importlar.

## Faz 3 — Büyük Dosyaların Parçalanması
**Amaç:** Okunabilirlik ve test edilebilirlik için devasa ekranları modülerleştirmek.

Hedef Dosya
- `features/buildings/presentation/screens/building_detail_screen.dart`

İş Listesi
- Ana ekranı incele, alt widget’ları ayrı dosyalara/parçalara taşı (ör. header, tab içerikleri, aksiyon bar).
- İş mantığını (API çağrıları, state yönetimi) ilgili provider/util katmanına çek.
- Küçük, private widget sınıfları oluştur; helper fonksiyonları `presentation/utils` altına taşı.
- Log/print yerine `log` (dart:developer) veya uygun hata gösterimi kullan.

Kontrol Listesi
- Ekran, önceki fonksiyonelliği koruyor (tabs, visitors/employees vs).
- `flutter analyze` ve hızlı manuel akış testi (buildings list -> detail) geçiyor.

Çıktılar
- Parçalanmış widget dosyaları.
- Sadeleşmiş ana ekran.

## Riskler ve Bağımlılıklar
- Tema/provider tekilleştirmesi router ve shell’de kırık import riski taşır; adım adım yapılmalı.
- Building model değişiklikleri home ekranı/harita bileşenlerini etkileyebilir; kullanım noktaları tespit edilmeli.
- Büyük ekran parçalama sonrası regressions riski; hızlı smoke test şart.

## Açık Sorular
- Theme için kanonik konum tercihi: `core/` altında mı yoksa root `lib/theme/` altında mı tutulacak?
- Home’daki building modeli gerçekten kullanılıyor mu, yoksa mock/demo amaçlı mı?
- Test hedefi: web mi (chrome) yoksa masaüstü/mobil mi öncelikli?

