Bakım Önerileri Ekranı – Refaktör Yol Haritası

Kapsam: lib/screens/maintenance_suggestions_screen.dart

1) Yardımcıları Ayır (Tekrarlayan Kodları Kaldır)
- Durum/öncelik/tür eşlemesini core/utils/maintenance_utils.dart dosyasına taşı.
  - getStatusText, getStatusColor, getPriorityColor, getMaintenanceTypeText
- Tarih formatlamayı mevcut format_utils.dart altında tekilleştir.

2) Standart Modal Çerçevesi
- showAppDialog(ctx, {title, content, maxWidth}) yardımcı fonksiyonunu oluştur.
  - Material Dialog + ClipRRect + theme.resources.solidBackgroundFillColorBase
- 3 diyaloğu bu yardımcı ile değiştir:
  - Detay Göster (maxWidth: 820)
  - Bakım Düzenle (maxWidth: 700)
  - Bakım Ekle (maxWidth: 700)

3) Chip Bileşenlerini Bileşenleştir
- widgets/chips/ altında küçük yeniden kullanılabilir widget’lar:
  - StatusChip, PriorityChip, CategoryChip, BuildingChip

4) Bina Adı Etiketinin Hesaplanmasını Sadeleştir
- Sadece ref.watch(buildingControllerProvider) kullan; etiketi tek noktada hesapla.
- Yinelenen read/watch yollarını kaldır.

5) Tip Güvenliği Temizliği
- cost alanını model/servis katmanında double olarak netleştir; ekrandaki parse dallarını kaldır.

6) Sabitler
- constants/ui.dart: kDialogMaxWDetail=820, kDialogMaxWForm=700,
  kSpaceSm=8, kSpaceMd=12.

7) Diyalog Bazında Uygulama
- Adım A: “Detay Göster”i yeni yardımcı ve chip’lerle dönüştür.
- Adım B: “Düzenle”yi dönüştür.
- Adım C: “Ekle”yi dönüştür.

8) QA Kontrol Listesi
- Aç/Kapat, klavye ile gönderme, doğrulama, kaydet/güncelle akışları,
  liste yenileme (ref.invalidate), koyu/açık tema görünümü, küçük ekranda sığma.

