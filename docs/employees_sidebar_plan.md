## Çalışanlar sekmesi — yol haritası

### Mevcut durum (özet)
- Sidebar `NavigationPane` içinde `Ana Sayfa, Binalar, Arızalar, Bakımlar, Raporlar` var; footer’da AI Asistan, Tema, Ayarlar, Çıkış. Route eşlemeleri `app_router.dart` içinde.
- Çalışanlar UI’si şu an yalnızca bina detayındaki `EmployeesTab` + `employee_modals.dart` üzerinden kullanılıyor; veri kaynağı `EmployeeApiService.getEmployeesByBuildingId`.
- Backend’te genel `/employees` ve `/employees/public` uçları var; bina bazlı uç `/buildings/{id}/employees` da hazır.

### Hedef
Sidebara “Çalışanlar” sekmesi ekleyip tüm çalışanları listeleyen, filtrelenebilir ve bina detayına gitmeden yönetilebilir bir ekran oluşturmak.

### Adım adım plan
- **Routing ve navigation**
  - `app_router.dart` içine `/employees` rotası ekle; ShellRoute altında konumlandır.
  - `app_shell.dart` `NavigationPane` `items` listesine yeni `PaneItem` (ikon: `FluentIcons.contact` veya `people`) ekle; `_calculateSelectedIndex` switch’ini ve `onChanged` routing’ini güncelle.
- **Veri katmanı**
  - Yeni servis: `features/employees/data/employee_api_service.dart` (veya mevcut servisi genişlet) — uçlar: `GET /employees`, opsiyonel query (search, buildingId, is_active), `POST/PUT/DELETE` public rotalar yeniden kullanılabilir.
  - Tip güvenliği için model ekle (Freezed/JsonSerializable): `Employee` dto + `EmployeeFilters`.
- **State management**
  - Riverpod AsyncNotifier: `employeesProvider` (liste + filtre + pagination), `employeeDetailProvider` opsiyonel.
  - Filtreler: search (ad/soyad/e-posta), buildingId, isActive; default page size 20/30.
- **Ekran tasarımı**
  - Yeni ekran: `features/employees/presentation/screens/employees_screen.dart`.
  - Başlık + aksiyonlar: `Yeni Çalışan` butonu (mevcut modal yeniden kullan), filtre barı, toplam çalışan rozeti.
  - Gövde: `PaginatedDataTable` veya `ListView.builder` + `Shimmer/Skeleton` loading; boş durum ve hata durumu `SelectableText.rich` ile.
  - Satır aksiyonları: detay görüntüle (modal), düzenle (modal), sil (confirm).
  - Bina adına göre rozet veya sütun ekle (backend response’tan building adı yoksa `building_id` göster; gerekirse backend’e isim ekleme işi planlanabilir).
- **Reuse / uyarlama**
  - `employee_modals.dart` ve `form_validators.dart` doğrudan kullan; modal API’lerini buildingId opsiyonel olacak şekilde genişlet (zorunlu parametrelerin null olmasına karşı validasyon).
  - `EmployeesTab`’de kullanılan `EmployeeApiService` metotlarını yeni servisle hizala; gerekirse ortak hale getir.
- **Durumlar ve hata yönetimi**
  - Loading için `ProgressRing` + iskelet; hata için `SelectableText.rich` kırmızı ton.
  - CRUD sonrası provider `ref.invalidate(employeesProvider)` ile tazele.
- **Test ve doğrulama**
  - Widget test: filtre + boş durum + hata durumu render.
  - Servis test: `/employees` 200 yanıtı map’leniyor mu.
  - Manuel akış: listeleme, filtre, CRUD, sidebar seçimi doğru route’a gidiyor mu.

### Ek notlar / kararlar
- Performans için sayfalama opsiyonunu açık bırak (backend destekliyorsa query param ekle; yoksa front tarafı client-side sayfalama).
- Tema/ikon tutarlılığı: Fluent `people`/`contact` ikon seti.
- Erişilebilirlik: klavye navigasyonu ve tooltip’ler mevcut modal butonlarında korunacak.

### Yapılacak işler (önerilen sırayla)
1) Routing + sidebar ekle (boş ekranla).  
2) Employee servis + modeller + provider.  
3) `employees_screen` UI + filtre/CRUD entegrasyonu.  
4) Modal parametrelerini genel kullanım için genişlet (buildingId opsiyonel veya select).  
5) Testler (widget + servis) ve manuel doğrulama notları.  

