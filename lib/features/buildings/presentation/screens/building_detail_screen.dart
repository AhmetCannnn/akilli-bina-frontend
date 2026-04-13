import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/api_error.dart';
import 'add_building_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/building_provider.dart';
import '../../../../features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:belediye_otomasyon/features/employees/data/services/employee_api_service.dart';
import '../../data/services/energy_api_service.dart';
import '../../data/services/visitor_api_service.dart';
import '../utils/building_helpers.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart' show showErrorDialog, showDeleteDialog, buildModalConstraints, buildModalTitle, showSuccessInfoBar, showErrorInfoBar;
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';
import 'package:belediye_otomasyon/core/widgets/app_entity_row_actions.dart';
import 'package:belediye_otomasyon/core/widgets/app_scaffold_page.dart';
import 'package:belediye_otomasyon/core/widgets/removable_tag.dart';
import '../widgets/tabs/departments_tab.dart';
import '../widgets/tabs/employees_tab.dart';
import '../widgets/tabs/info_tab.dart';
import '../widgets/tabs/maintenance_tab.dart';
import '../widgets/tabs/sensors_tab.dart';
import '../widgets/tabs/visitors_tab.dart';
import '../widgets/tabs/building_reports_tab.dart';
import '../widgets/tabs/building_issues_tab.dart';
import '../widgets/sensor_card.dart';

class BuildingDetailScreen extends ConsumerWidget {
  const BuildingDetailScreen({
    super.key,
    required this.buildingId,
  });

  final int buildingId;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final horizontalPad = PageHeader.horizontalPadding(context);
    final buildingAsync = ref.watch(buildingDetailControllerProvider(buildingId));

    Widget withPageChrome(Widget child) {
      return AppScaffoldPage(
        content: Container(
          color: theme.scaffoldBackgroundColor,
          padding: EdgeInsets.only(
            left: horizontalPad,
            right: horizontalPad,
            top: AppUiTokens.space8,
            bottom: AppUiTokens.space12,
          ),
          child: child,
        ),
      );
    }

    return buildingAsync.when(
      data: (building) {
        // Eğer employees verisi yoksa, ayrı API çağrısı yap
        if (building['employees'] == null || (building['employees'] as List).isEmpty) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: EmployeeApiService().getEmployeesByBuildingId(buildingId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return withPageChrome(const Center(child: ProgressRing()));
              }

              if (snapshot.hasError) {
                // Hata durumunda employees olmadan devam et
                return withPageChrome(
                  _buildBuildingContent(theme, building, [], context, ref),
                );
              }

              final employees = snapshot.data ?? [];

              // Building verisine employees ekle
              final updatedBuilding = Map<String, dynamic>.from(building);
              updatedBuilding['employees'] = employees;

              return withPageChrome(
                _buildBuildingContent(theme, updatedBuilding, employees, context, ref),
              );
            },
          );
        }

        return withPageChrome(
          _buildBuildingContent(
            theme,
            building,
            building['employees'] as List<Map<String, dynamic>>,
            context,
            ref,
          ),
        );
      },
      loading: () => withPageChrome(const Center(child: ProgressRing())),
      error: (error, stack) => withPageChrome(
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(humanizeError(error)),
              Button(
                child: const Text('Yeniden Dene'),
                onPressed: () =>
                    ref.refresh(buildingDetailControllerProvider(buildingId)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuildingContent(
    FluentThemeData theme,
    Map<String, dynamic> building,
    List<Map<String, dynamic>> employees,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Column(
      children: [
        _BuildingHeader(
          building: building,
          employees: employees,
          ref: ref,
          onEdit: () =>
              AddBuildingModal.showEditBuildingModal(context, ref, buildingId, building),
        ),
        const SizedBox(height: AppUiTokens.space8),
        _LiveSensorsSection(building: building),
        const SizedBox(height: AppUiTokens.space12),
        Expanded(
          child: _BuildingDetailTabs(building: building),
        ),
      ],
    );
  }
}

class _LiveSensorsSection extends StatefulWidget {
  const _LiveSensorsSection({required this.building});

  final Map<String, dynamic> building;

  @override
  State<_LiveSensorsSection> createState() => _LiveSensorsSectionState();
}

class _LiveSensorsSectionState extends State<_LiveSensorsSection> {
  Timer? _updateTimer;
  late Random _random;
  
  // Sensör değerleri
  late double _temperature;
  late double _humidity;
  late int _aqi;
  late double _occupancy;
  late double _light;
  
  // Güncelleme zamanı
  DateTime _lastUpdate = DateTime.now();
  
  // Her bina için farklı başlangıç değerleri (building ID'ye göre)
  void _initializeSensorValues() {
    final buildingId = widget.building['id'] as int? ?? 1;
    _random = Random(buildingId); // Her bina için farklı seed
    
    // Başlangıç değerleri (her bina için farklı)
    _temperature = 20.0 + (_random.nextDouble() * 5.0); // 20-25 arası
    _humidity = 40.0 + (_random.nextDouble() * 15.0); // 40-55 arası
    _aqi = 30 + _random.nextInt(30); // 30-60 arası
    _occupancy = 30.0 + (_random.nextDouble() * 40.0); // 30-70 arası
    _light = 200.0 + (_random.nextDouble() * 300.0); // 200-500 arası
  }
  
  void _updateSensorValues() {
    if (!mounted) return;
    
    setState(() {
      // Sıcaklık: 18-27 arası, yavaşça değişsin
      _temperature = (_temperature + (_random.nextDouble() - 0.5) * 0.3).clamp(18.0, 27.0);
      
      // Nem: %35-60 arası
      _humidity = (_humidity + (_random.nextDouble() - 0.5) * 1.0).clamp(35.0, 60.0);
      
      // AQI: 0-100 arası, yavaşça değişsin
      _aqi = (_aqi + (_random.nextInt(5) - 2)).clamp(0, 100);
      
      // Doluluk: %20-80 arası
      _occupancy = (_occupancy + (_random.nextDouble() - 0.5) * 2.0).clamp(20.0, 80.0);
      
      // Aydınlık: 100-600 lux arası
      _light = (_light + (_random.nextDouble() - 0.5) * 20.0).clamp(100.0, 600.0);
      
      _lastUpdate = DateTime.now();
    });
  }
  
  String _getTimeAgo() {
    final seconds = DateTime.now().difference(_lastUpdate).inSeconds;
    if (seconds < 60) {
      return '$seconds sn';
    }
    final minutes = seconds ~/ 60;
    return '$minutes dk';
  }
  
  String _getAirQualityText(int aqi) {
    if (aqi < 50) return 'İyi';
    if (aqi < 100) return 'Orta';
    return 'Kötü';
  }
  
  Color _getAirQualityColor(int aqi) {
    if (aqi < 50) return Colors.green;
    if (aqi < 100) return Colors.orange;
    return Colors.red;
  }

  @override
  void initState() {
    super.initState();
    _initializeSensorValues();
    
    // Her 3-5 saniyede bir güncelle (rastgele aralık)
    _updateTimer = Timer.periodic(
      Duration(seconds: 3 + _random.nextInt(3)), // 3-5 saniye arası
      (_) => _updateSensorValues(),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo();
    final airQualityText = _getAirQualityText(_aqi);
    final airQualityColor = _getAirQualityColor(_aqi);

    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isXxl = constraints.maxWidth >= 1500;
              final isXl = constraints.maxWidth >= 1200;
              final isLg = constraints.maxWidth >= 900;
              final columns = isXxl ? 5 : (isXl ? 4 : (isLg ? 3 : 2));
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 2.8,
                children: [
                  SensorCard(
                    icon: FluentIcons.circle_shape,
                    title: 'Sıcaklık',
                    value: '${_temperature.toStringAsFixed(1)}°C',
                    color: Colors.orange,
                    minMax: 'min 18 • max 27',
                    updatedAgo: timeAgo,
                  ),
                  SensorCard(
                    icon: FluentIcons.drop,
                    title: 'Nem',
                    value: '%${_humidity.toStringAsFixed(0)}',
                    color: Colors.blue,
                    minMax: 'min %35 • max %60',
                    updatedAgo: timeAgo,
                  ),
                  SensorCard(
                    icon: FluentIcons.airplane,
                    title: 'Hava Kalitesi',
                    value: airQualityText,
                    color: airQualityColor,
                    minMax: 'AQI $_aqi',
                    updatedAgo: timeAgo,
                  ),
                  SensorCard(
                    icon: FluentIcons.people,
                    title: 'Doluluk',
                    value: '%${_occupancy.toStringAsFixed(0)}',
                    color: Colors.purple,
                    minMax: 'min %20 • max %80',
                    updatedAgo: timeAgo,
                  ),
                  SensorCard(
                    icon: FluentIcons.lightbulb,
                    title: 'Aydınlık',
                    value: '${_light.toStringAsFixed(0)} lux',
                    color: Colors.yellow,
                    minMax: 'min 100 • max 600',
                    updatedAgo: timeAgo,
                  ),
                ],
              );
            },
          ),
        ],
    );
  }
}

class _BuildingDetailTabs extends StatefulWidget {
  const _BuildingDetailTabs({required this.building});

  final Map<String, dynamic> building;

  @override
  State<_BuildingDetailTabs> createState() => _BuildingDetailTabsState();
}

class _BuildingDetailTabsState extends State<_BuildingDetailTabs> {
  int _currentIndex = 0;

  Text _tabLabel(
    BuildContext context,
    String label,
    int tabIndex,
  ) {
    final theme = FluentTheme.of(context);
    final isActive = _currentIndex == tabIndex;
    return Text(
      label,
      style: theme.typography.body?.copyWith(
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
        color: isActive
            ? theme.accentColor
            : theme.typography.body?.color?.withOpacity(0.78),
        letterSpacing: 0.2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Expanded(
            child: TabView(
              currentIndex: _currentIndex,
              onChanged: (index) => setState(() => _currentIndex = index),
              tabs: [
                Tab(
                  icon: const Icon(FluentIcons.info),
                  text: _tabLabel(context, 'Bilgiler', 0),
                  body: InfoTab(building: widget.building),
                ),
                Tab(
                  icon: const Icon(FluentIcons.city_next),
                  text: _tabLabel(context, 'Birimler', 1),
                  body: DepartmentsTab(building: widget.building),
                ),
                Tab(
                  icon: const Icon(FluentIcons.contact),
                  text: _tabLabel(context, 'Çalışanlar', 2),
                  body: EmployeesTab(building: widget.building),
                ),
                Tab(
                  icon: const Icon(FluentIcons.activity_feed),
                  text: _tabLabel(context, 'Enerji', 3),
                  body: SensorsTab(building: widget.building),
            ),
                Tab(
                  icon: const Icon(FluentIcons.group),
                  text: _tabLabel(context, 'Ziyaretçiler', 4),
                  body: VisitorsTab(building: widget.building),
                ),
                Tab(
                  icon: const Icon(FluentIcons.settings),
                  text: _tabLabel(context, 'Bakım', 5),
                  body: MaintenanceTab(building: widget.building),
                ),
                Tab(
                  icon: const Icon(FluentIcons.report_hacked),
                  text: _tabLabel(context, 'Arızalar', 6),
                  body: BuildingIssuesTab(building: widget.building),
                ),
                Tab(
                  icon: const Icon(FluentIcons.analytics_report),
                  text: _tabLabel(context, 'Raporlar', 7),
                  body: BuildingReportsTab(building: widget.building),
                ),
              ],
            ),
          ),
        ],
    );
  }
}

class _BuildingHeader extends StatelessWidget {
  const _BuildingHeader({
    required this.building,
    required this.employees,
    required this.ref,
    this.onEdit,
  });

  final Map<String, dynamic> building;
  final List<Map<String, dynamic>> employees;
  final WidgetRef ref;
  final VoidCallback? onEdit;

  /// Modal başlığı oluştur (kapatma butonu ile)
  Widget _buildModalTitle(String title, BuildContext ctx) {
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

  /// Bina silme dialog'u
  void _showDeleteBuildingDialog(BuildContext context) {
    final buildingName = building['name'] ?? 'Bu bina';
    final theme = FluentTheme.of(context);

    showDeleteDialog(
      context: context,
      theme: theme,
      title: 'Bina Sil',
      message: '\'$buildingName\' binasını silmek istediğinize emin misiniz?',
      onDelete: () async {
        try {
          await ref.read(buildingControllerProvider.notifier).deleteBuilding(building['id'] as int);
          // Silme başarılıysa ana sayfaya (bina listesine) yönlendir
          if (context.mounted) {
            context.go('/buildings');
          }
          return true;
        } catch (e) {
          // Yetki hatası veya başka bir API hatası: yeşil toast yerine kırmızı hata barı göster.
          if (context.mounted) {
            // Backend'den gelen okunabilir hata mesajını kullan
            final msg = humanizeError(e);
            showErrorInfoBar(context, msg);
          }
          return false;
        }
      },
      successMessage: '$buildingName silindi.',
      onSuccess: null, // Zaten context.go ile yönlendirme yapılıyor
    );
  }

  // Yönetici bulma fonksiyonu - direkt manager_id FK ile
  Map<String, dynamic>? _getManager() {
    try {
      final managerId = building['manager_id']?.toString();
      if (managerId == null || managerId.isEmpty) {
        return null;
      }
      
      // Employees listesinden manager_id ile eşleşen çalışanı bul
      for (var employee in employees) {
        final employeeId = employee['id']?.toString();
        if (employeeId == managerId) {
          return employee;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _resolveManager() async {
    final localManager = _getManager();
    if (localManager != null) {
      return localManager;
    }

    final managerId = building['manager_id']?.toString();
    if (managerId == null || managerId.isEmpty) {
      return null;
    }

    return EmployeeApiService().getEmployeeById(managerId);
  }

  Widget _buildPhoto({
    required String photoUrl,
    required double width,
    required double height,
    double radius = 10,
    BoxFit fit = BoxFit.cover,
  }) {
    final hasUrl = photoUrl.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: hasUrl
          ? Image.network(
              photoUrl,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) {
                return _buildPhotoFallback(width, height, radius);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildPhotoFallback(width, height, radius, isLoading: true);
              },
            )
          : _buildPhotoFallback(width, height, radius),
    );
  }

  Widget _buildPhotoFallback(double width, double height, double radius, {bool isLoading = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: isLoading
            ? const ProgressRing()
            : Icon(
                FluentIcons.home,
                color: Colors.blue,
                size: width * 0.5,
              ),
      ),
    );
  }

  // Çalışma saatlerini formatlama fonksiyonu
  String _getWorkingHoursText() {
    try {
      final workingHours = building['working_hours'];
      if (workingHours == null) return '';
      
      final weekdays = workingHours['weekdays'];
      if (weekdays != null) {
        final open = weekdays['open']?.toString() ?? '';
        final close = weekdays['close']?.toString() ?? '';
        if (open.isEmpty || close.isEmpty) return '';
        
        final weekend = workingHours['weekend'] == true;
        if (weekend) {
          return 'Hafta içi $open–$close (Hafta sonu açık)';
        }
        return 'Hafta içi $open–$close';
      }
    } catch (_) {}
    return '';
  }

  // Bina açık mı kontrolü
  bool _isOpenNow() {
    try {
      final now = DateTime.now();
      final weekday = now.weekday; // 1=Monday, 7=Sunday
      
      final workingHours = building['working_hours'];
      if (workingHours == null) {
        return false;
      }
      
      // Hafta sonu kontrolü
      if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
        return workingHours['weekend'] == true;
      }
      
      // Hafta içi kontrolü
      final weekdays = workingHours['weekdays'];
      if (weekdays != null) {
        final openStr = weekdays['open']?.toString();
        final closeStr = weekdays['close']?.toString();
        
        if (openStr == null || closeStr == null) {
          return false;
        }
        
        final openParts = openStr.split(':');
        final closeParts = closeStr.split(':');
        
        if (openParts.length == 2 && closeParts.length == 2) {
          final openHour = int.tryParse(openParts[0]);
          final openMin = int.tryParse(openParts[1]);
          final closeHour = int.tryParse(closeParts[0]);
          final closeMin = int.tryParse(closeParts[1]);
          
          if (openHour == null || openMin == null || closeHour == null || closeMin == null) {
            return false;
          }
          
          final currentMinutes = now.hour * 60 + now.minute;
          final openMinutes = openHour * 60 + openMin;
          final closeMinutes = closeHour * 60 + closeMin;
          
          return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
        }
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final workingHoursText = _getWorkingHoursText();
    final isOpen = _isOpenNow();

    return Stack(
      children: [
        Card(
        child: Padding(
      padding: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.only(left: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) {
                              return ContentDialog(
                                constraints: const BoxConstraints(maxWidth: 900),
                                content: SizedBox(
                                  width: 800,
                                  child: _buildPhoto(
                                    photoUrl: building['photo_url']?.toString() ?? '',
                                    width: 800,
                                    height: 400,
                                    radius: 8,
                                    fit: BoxFit.contain,
                                  ),
              ),
                                actions: [
                                  FilledButton(
                                    child: const Text('Kapat'),
                                    onPressed: () => Navigator.pop(ctx),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Container(
            decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                ),
              ],
            ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildPhoto(
                              photoUrl: building['photo_url']?.toString() ?? '',
                              width: 160,
                              height: 160,
                              radius: 10,
                            ),
                          ),
      ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                          building['name'] ?? 'Bina Adı',
                          style: theme.typography.title?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Text(
                          building['address'] ?? 'Adres',
                                    softWrap: false,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.typography.caption?.copyWith(
                                      color: theme.typography
                                          .caption?.color
                                          ?.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(FluentIcons.map_pin, size: 14),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => ContentDialog(
                                        title: const Text('Harita'),
                                        content: const Text('Harita bağlantısı daha sonra eklenecek.'),
                                        actions: [
                                          FilledButton(
                                            child: const Text('Kapat'),
                                            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
                                  },
          ),
        ],
      ),
                                // Şehir ve İlçe bilgisi
                                if ((building['city'] != null && building['city'].toString().isNotEmpty) ||
                                    (building['district'] != null && building['district'].toString().isNotEmpty))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      [
                                        if (building['district'] != null && building['district'].toString().isNotEmpty)
                                          building['district'].toString(),
                                        if (building['city'] != null && building['city'].toString().isNotEmpty)
                                          building['city'].toString(),
                                      ].join(' / '),
                                      style: theme.typography.caption?.copyWith(
                                        color: theme.typography.caption?.color?.withOpacity(0.6),
                                        fontSize: 11,
                                      ),
                                    ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              RemovableTag(
                                label: isOpen ? 'Şimdi: Açık' : 'Şimdi: Kapalı',
                                color: isOpen ? Colors.green : Colors.red,
                              ),
                              if (workingHoursText.isNotEmpty)
                                RemovableTag(
                                  label: workingHoursText,
                                  color: Colors.blue,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
      children: [
        Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
          decoration: BoxDecoration(
                                  color: theme.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
                                  FluentIcons.contact,
                                  color: theme.accentColor,
                                  size: 16,
          ),
        ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder<Map<String, dynamic>?>(
                                      future: _resolveManager(),
                                      builder: (context, snapshot) {
                                        final manager = snapshot.data;
                                        final fullName =
                                            '${manager?['first_name'] ?? ''} ${manager?['last_name'] ?? ''}'.trim();
                                        final hasManager = manager != null && fullName.isNotEmpty;

                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              snapshot.connectionState == ConnectionState.waiting
                                                  ? 'Bina Yöneticisi: Yükleniyor...'
                                                  : (hasManager
                                                      ? 'Bina Yöneticisi: $fullName'
                                                      : 'Bina Yöneticisi: Belirtilmemiş'),
                                              style: theme.typography.body,
                                            ),
                                            if (hasManager) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                [
                                                  manager['phone'] ?? '',
                                                  manager['email'] ?? '',
                                                ].where((e) => e.toString().isNotEmpty).join(' • '),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.typography.caption?.copyWith(
                                                  color: theme.typography.caption?.color?.withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
      ],
                        ),
              ),
            ],
          ),
        ],
      ),
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: 13,
          child: IconButton(
            icon: const Icon(FluentIcons.back, size: 20),
            onPressed: () {
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                context.go('/buildings');
    }
            },
          ),
        ),
        Positioned(
          top: 20,
          right: 16,
          child: Builder(
            builder: (context) {
              // CO₂e değeri backend'den gelecek
              final dynamic co2Raw = building['co2_emission'];
              final double co2TodayKg = switch (co2Raw) {
                num v => v.toDouble(),
                String s => double.tryParse(s) ?? 84.0,
                _ => 84.0,
              };
              final Color co2Color = co2TodayKg < 100
                  ? const Color(0xFF2FB06E)
                  : (co2TodayKg < 200
                        ? const Color(0xFFE6973D)
                        : const Color(0xFFE25757));
              const greenScoreProgress = 0.72;
              final greenScorePct = (greenScoreProgress * 100).round();
              final Color greenScoreColor = greenScoreProgress >= 0.8
                  ? const Color(0xFF24A765)
                  : (greenScoreProgress >= 0.6
                        ? const Color(0xFFE6973D)
                        : const Color(0xFFE25757));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Karbon Ayak İzi',
                style: FluentTheme.of(context).typography.caption?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: FluentTheme.of(context).typography.caption?.color?.withOpacity(0.78),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: co2Color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${co2TodayKg.toStringAsFixed(0)} kgCO₂e',
                    style: FluentTheme.of(context).typography.bodyStrong?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: co2Color.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.black.withOpacity(0.08),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Yeşil Skor',
                style: FluentTheme.of(context).typography.caption?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: FluentTheme.of(context).typography.caption?.color?.withOpacity(0.78),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: greenScoreColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '%$greenScorePct',
                    style: FluentTheme.of(context).typography.bodyStrong?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: greenScoreColor.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        ),
      ),
    );
            },
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Builder(builder: (ctx) {
            final theme = FluentTheme.of(ctx);
            final accent = theme.accentColor;
            return AppEntityRowActions(
              onEdit: onEdit ?? () {},
              onDelete: () => _showDeleteBuildingDialog(context),
              editColor: accent,
              deleteColor: Colors.red,
            );
          }),
        ),
      ],
    );
  }
}

