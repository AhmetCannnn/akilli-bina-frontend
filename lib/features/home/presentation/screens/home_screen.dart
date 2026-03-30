import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:belediye_otomasyon/core/utils/api_error.dart';
import 'package:belediye_otomasyon/features/auth/presentation/screens/login_screen.dart';
import 'package:belediye_otomasyon/features/buildings/presentation/screens/buildings_screen.dart';
import 'package:belediye_otomasyon/features/buildings/presentation/screens/add_building_modal.dart';
import 'package:belediye_otomasyon/features/issues/presentation/screens/report_issue_modal.dart';
import 'package:belediye_otomasyon/features/issues/presentation/screens/active_issues_screen.dart';
import 'package:belediye_otomasyon/features/maintenance/presentation/screens/maintenance_suggestions_screen.dart';
import 'package:belediye_otomasyon/features/reports/presentation/screens/reports_screen.dart';
import '../widgets/ai_assistant_modal.dart';
import 'package:belediye_otomasyon/theme/theme_provider.dart';
import 'package:belediye_otomasyon/features/buildings/presentation/providers/building_provider.dart';
import 'package:belediye_otomasyon/features/navigation/presentation/widgets/app_shell.dart';
import 'package:belediye_otomasyon/features/settings/presentation/screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0; // NavigationView için seçili sayfa indeksi
  final MapController _mapController = MapController();
  double _currentZoom = 12.0;
  latlng.LatLng _currentCenter = const latlng.LatLng(37.8716, 32.4846);
  EnergyRange _range = EnergyRange.daily;

  // Buildings will be loaded from backend via Riverpod

  // Helper method to convert backend data to Building model
  List<Building> _convertToBuildings(List<Map<String, dynamic>> buildingsData) {
    return buildingsData.map((buildingData) {
      // Generate random position for map display
      final random = DateTime.now().millisecondsSinceEpoch + (buildingData['id']?.hashCode ?? 0);
      final dx = (random % 100) / 100.0;
      final dy = ((random ~/ 100) % 100) / 100.0;
      
      // Determine status based on building data or use default
      BuildingStatus status = BuildingStatus.normal;
      if (buildingData['building_type']?.toString().toLowerCase().contains('komek') == true) {
        status = BuildingStatus.normal;
      } else if (buildingData['building_type']?.toString().toLowerCase().contains('müze') == true) {
        status = BuildingStatus.warning;
      } else if (buildingData['building_type']?.toString().toLowerCase().contains('hizmet') == true) {
        status = BuildingStatus.critical;
      }
      
      return Building(
        id: buildingData['id']?.toString() ?? '0',
        name: buildingData['name']?.toString() ?? 'Bilinmeyen Bina',
        status: status,
        position: Offset(dx, dy),
      );
    }).toList();
  }

  String _getStatusText(BuildingStatus status) {
    switch (status) {
      case BuildingStatus.normal:
        return 'Normal';
      case BuildingStatus.warning:
        return 'Uyarı';
      case BuildingStatus.critical:
        return 'Kritik';
      case BuildingStatus.maintenance:
        return 'Bakımda';
    }
  }

  void _showAIAssistant(BuildContext context) {
    AIAssistantModal.show(context);
  }

  Color _getStatusColor(BuildingStatus status) {
    switch (status) {
      case BuildingStatus.normal:
        return Colors.green;
      case BuildingStatus.warning:
        return Colors.yellow;
      case BuildingStatus.critical:
        return Colors.red;
      case BuildingStatus.maintenance:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final buildingsAsync = ref.watch(buildingControllerProvider);

    return buildingsAsync.when(
      data: (buildings) => _buildHomeContent(theme, isDarkMode, buildings),
      loading: () => const Center(child: ProgressRing()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(humanizeError(error)),
            Button(
              child: const Text('Yeniden Dene'),
              onPressed: () => ref.refresh(buildingControllerProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(FluentThemeData theme, bool isDarkMode, List<Map<String, dynamic>> buildings) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Container(
        color: theme.scaffoldBackgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık AppShell içinde yönetiliyor
            const SizedBox(height: 16),
            // Harita Bölümü (FlutterMap)
            Card(
              child: SizedBox(
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: const latlng.LatLng(37.8716, 32.4846),
                          initialZoom: 12.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                          onMapEvent: (event) {
                            setState(() {
                              _currentZoom = event.camera.zoom;
                              _currentCenter = event.camera.center;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                            userAgentPackageName: 'belediye_otomasyon',
                          ),
                          MarkerLayer(
                            markers: _convertToBuildings(buildings).map((building) {
                              final baseLat = 37.8716;
                              final baseLng = 32.4846;
                              final latOffset = (building.position.dx - 0.5) * 0.02;
                              final lngOffset = (building.position.dy - 0.5) * 0.02;
                              final pos = latlng.LatLng(baseLat + latOffset, baseLng + lngOffset);
                              return Marker(
                                point: pos,
                                width: 12,
                                height: 12,
                                child: GestureDetector(
                                  onTap: () {
                                    displayInfoBar(
                                      context,
                                      builder: (context, close) => InfoBar(
                                        title: Text(building.name),
                                        content: Text(_getStatusText(building.status)),
                                        severity: _getInfoBarSeverity(building.status),
                                        onClose: close,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(building.status),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton(
                              child: const Icon(FluentIcons.remove, size: 14),
                              onPressed: () {
                                final center = _currentCenter;
                                final next = (_currentZoom - 1).clamp(3.0, 18.0);
                                _mapController.move(center, next);
                              },
                            ),
                            const SizedBox(width: 6),
                            FilledButton(
                              child: const Icon(FluentIcons.add, size: 14),
                              onPressed: () {
                                final center = _currentCenter;
                                final next = (_currentZoom + 1).clamp(3.0, 18.0);
                                _mapController.move(center, next);
                              },
                            ),
                            const SizedBox(width: 6),
                            FilledButton(
                              child: const Icon(FluentIcons.full_screen, size: 14),
                              onPressed: () => _openFullScreenMap(buildings),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Zaman aralığı seçici + kompakt grafikler
            _buildEnergyChartsSection(theme),
            const SizedBox(height: 24),
            _buildOverviewCards(theme),
          ],
        ),
      ),
    ),
    // Alt komut çubuğu kaldırıldı; eylem üst sağda
    );
  }

  InfoBarSeverity _getInfoBarSeverity(BuildingStatus status) {
    switch (status) {
      case BuildingStatus.normal:
        return InfoBarSeverity.success;
      case BuildingStatus.warning:
        return InfoBarSeverity.warning;
      case BuildingStatus.critical:
        return InfoBarSeverity.error;
      case BuildingStatus.maintenance:
        return InfoBarSeverity.info;
    }
  }

  void _openFullScreenMap(List<Map<String, dynamic>> buildings) {
    Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => _FullScreenMapPage(
          initialCenter: _currentCenter,
          initialZoom: _currentZoom,
          buildings: _convertToBuildings(buildings),
          statusText: _getStatusText,
          statusColor: _getStatusColor,
          statusSeverity: _getInfoBarSeverity,
        ),
      ),
    );
  }

  Widget _buildOverviewCards(FluentThemeData theme) {
    final cards = [
      _buildOverviewCard(
        theme,
        'Arızalar',
        'Asansör Arızası',
        'B Blok - 2. Asansör',
        'Yüksek Öncelik',
        FluentIcons.warning,
        Colors.red,
      ),
      _buildOverviewCard(
        theme,
        'Bakımlar',
        'Jeneratör Bakımı',
        'Gelecek bakım',
        '3 gün içinde',
        FluentIcons.build_definition,
        Colors.purple,
      ),
      _buildOverviewCard(
        theme,
        'Binalar',
        'Toplam 42 Bina',
        '15 Site, 27 Tekil Bina',
        'Son eklenen: A Sitesi',
        FluentIcons.city_next,
        Colors.blue,
      ),
      _buildOverviewCard(
        theme,
        'Raporlar',
        '12 Yeni Rapor',
        'Bu ay oluşturulan',
        'Son rapor: 2 saat önce',
        FluentIcons.analytics_report,
        Colors.green,
      ),
    ];

    const spacing = 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = (width - spacing) / 2; // 2 sütun
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((c) => SizedBox(width: itemWidth, child: c))
              .toList(),
        );
      },
    );
  }

  Widget _buildEnergyChartsSection(FluentThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enerji Tüketimi',
                  style: theme.typography.subtitle,
                ),
                _EnergyRangeSelector(
                  selected: _range,
                  onChanged: (r) => setState(() => _range = r),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                final charts = [
                  _MiniLineChart(title: 'Elektrik (kWh)', color: Colors.orange, range: _range),
                  _MiniLineChart(title: 'Su (m³)', color: Colors.blue, range: _range),
                  _MiniLineChart(title: 'Doğalgaz (m³)', color: Colors.green, range: _range),
                ];
                if (isNarrow) {
                  return Column(
                    children: [
                      for (final c in charts) ...[c, const SizedBox(height: 12)],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: charts[0]),
                    const SizedBox(width: 12),
                    Expanded(child: charts[1]),
                    const SizedBox(width: 12),
                    Expanded(child: charts[2]),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    FluentThemeData theme,
    String title,
    String mainText,
    String location,
    String subText,
    IconData icon,
    Color color,
  ) {
    return Button(
      onPressed: () {
        switch (title) {
          case 'Arızalar':
            Navigator.push(
              context,
              FluentPageRoute(builder: (context) => const ActiveIssuesScreen()),
            );
            break;
          case 'Bakımlar':
            Navigator.push(
              context,
              FluentPageRoute(builder: (context) => const MaintenanceSuggestionsScreen()),
            );
            break;
          case 'Binalar':
            Navigator.push(
              context,
              FluentPageRoute(builder: (context) => const BuildingsScreen()),
            );
            break;
          case 'Raporlar':
            Navigator.push(
              context,
              FluentPageRoute(builder: (context) => const ReportsScreen()),
            );
            break;
        }
      },
      style: ButtonStyle(
        padding: ButtonState.all(EdgeInsets.zero),
        backgroundColor: ButtonState.all(Colors.transparent),
      ),
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.typography.bodyStrong,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mainText,
                      style: theme.typography.subtitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: theme.typography.caption?.copyWith(
                        color: theme.typography.caption?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subText,
                        style: theme.typography.caption?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                FluentIcons.chevron_right,
                color: theme.iconTheme.color?.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActionsDialog(BuildContext context, FluentThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.of(context).size.width - 96)
              .clamp(0.0, 1400.0)
              .toDouble(),
        ),
        title: const Center(child: Text('Yeni İşlem')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQuickActionTile(
              theme,
              'Yeni Bina Ekle',
              'Sisteme yeni bir bina ekleyin',
              FluentIcons.add_home,
              Colors.blue,
              () {
                Navigator.pop(context);
                AddBuildingModal.showAddBuildingModal(context, ref);
              },
            ),
            const SizedBox(height: 8),
            _buildQuickActionTile(
              theme,
              'Arıza Bildirimi',
              'Yeni bir arıza kaydı oluşturun',
              FluentIcons.report_hacked,
              Colors.orange,
              () {
                Navigator.pop(context);
                showReportIssueModal(context, ref);
              },
            ),
          ],
        ),
        actions: [
          FilledButton(
            child: const Text('Kapat'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(
    FluentThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: theme.typography.bodyStrong,
      ),
      subtitle: Text(
        subtitle,
        style: theme.typography.caption,
      ),
      trailing: Icon(
        FluentIcons.chevron_right,
        color: theme.iconTheme.color?.withOpacity(0.5),
        size: 16,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildStatusIndicator(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}

// Bina durumları için enum
enum BuildingStatus {
  normal,
  warning,
  critical,
  maintenance,
}

// Bina modeli
class Building {
  final String id;
  final String name;
  final BuildingStatus status;
  final Offset position;

  Building({
    required this.id,
    required this.name,
    required this.status,
    required this.position,
  });
}

enum EnergyRange { daily, weekly, monthly }

class _EnergyRangeSelector extends StatelessWidget {
  const _EnergyRangeSelector({required this.onChanged, required this.selected});

  final ValueChanged<EnergyRange> onChanged;
  final EnergyRange selected;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(FluentIcons.calendar, size: 16, color: theme.accentColor),
        const SizedBox(width: 6),
        ComboBox<EnergyRange>(
          value: selected,
          items: const [
            ComboBoxItem(value: EnergyRange.daily, child: Text('Günlük')),
            ComboBoxItem(value: EnergyRange.weekly, child: Text('Haftalık')),
            ComboBoxItem(value: EnergyRange.monthly, child: Text('Aylık')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  const _MiniLineChart({required this.title, required this.color, required this.range});

  final String title;
  final Color color;
  final EnergyRange range;

  List<FlSpot> _generateData() {
    final count = switch (range) { EnergyRange.daily => 24, EnergyRange.weekly => 7, EnergyRange.monthly => 30 };
    // Ölçek faktörü: haftalık > günlük, aylık > haftalık
    final scale = switch (range) { EnergyRange.daily => 1.0, EnergyRange.weekly => 1.4, EnergyRange.monthly => 1.9 };
    return List.generate(count, (i) {
      final x = i.toDouble();
      // Daha doğal dalgalanma: trend + periyodik bileşen + gürültü
      final trend = (i / count) * 20.0; // zamanla hafif artış
      final periodic = 10 * (i % 6) / 6; // periyodik küçük tepe
      final noise = (i % 2 == 0 ? 3 : -2).toDouble();
      final base = 55.0; // günlük taban
      final y = (base + trend + periodic + noise) * scale;
      return FlSpot(x, y);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final data = _generateData();
    final maxX = (data.length - 1).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.typography.bodyStrong,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (data.length / 4).ceilToDouble().clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final v = value.toInt();
                          final step = (data.length / 4).ceil();
                          if (v % step != 0) return const SizedBox.shrink();
                          String label;
                          switch (range) {
                            case EnergyRange.daily:
                              label = '${v}:00';
                              break;
                            case EnergyRange.weekly:
                              const days = ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz'];
                              label = v >= 0 && v < days.length ? days[v] : '';
                              break;
                            case EnergyRange.monthly:
                              label = '${v + 1}';
                              break;
                          }
                          return Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: maxX,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.9),
                          color.withOpacity(0.6),
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withOpacity(0.20),
                            color.withOpacity(0.06),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final v = s.y.toStringAsFixed(0);
                        return LineTooltipItem(
                          v,
                          TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenMapPage extends StatefulWidget {
  const _FullScreenMapPage({
    required this.initialCenter,
    required this.initialZoom,
    required this.buildings,
    required this.statusText,
    required this.statusColor,
    required this.statusSeverity,
  });

  final latlng.LatLng initialCenter;
  final double initialZoom;
  final List<Building> buildings;
  final String Function(BuildingStatus) statusText;
  final Color Function(BuildingStatus) statusColor;
  final InfoBarSeverity Function(BuildingStatus) statusSeverity;

  @override
  State<_FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<_FullScreenMapPage> {
  final MapController _controller = MapController();
  late double _zoom = widget.initialZoom;
  late latlng.LatLng _center = widget.initialCenter;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              onMapEvent: (event) {
                setState(() {
                  _zoom = event.camera.zoom;
                  _center = event.camera.center;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'belediye_otomasyon',
              ),
              MarkerLayer(
                markers: widget.buildings.map((b) {
                  final baseLat = widget.initialCenter.latitude;
                  final baseLng = widget.initialCenter.longitude;
                  final latOffset = (b.position.dx - 0.5) * 0.02;
                  final lngOffset = (b.position.dy - 0.5) * 0.02;
                  final pos = latlng.LatLng(baseLat + latOffset, baseLng + lngOffset);
                  return Marker(
                    point: pos,
                    width: 28,
                    height: 28,
                    child: GestureDetector(
                      onTap: () {
                        displayInfoBar(
                          context,
                          builder: (context, close) => InfoBar(
                            title: Text(b.name),
                            content: Text(widget.statusText(b.status)),
                            severity: widget.statusSeverity(b.status),
                            onClose: close,
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.statusColor(b.status),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  child: const Icon(FluentIcons.remove, size: 14),
                  onPressed: () {
                    final next = (_zoom - 1).clamp(3.0, 18.0);
                    _controller.move(_center, next);
                  },
                ),
                const SizedBox(width: 8),
                FilledButton(
                  child: const Icon(FluentIcons.add, size: 14),
                  onPressed: () {
                    final next = (_zoom + 1).clamp(3.0, 18.0);
                    _controller.move(_center, next);
                  },
                ),
                const SizedBox(width: 8),
                FilledButton(
                  child: const Icon(FluentIcons.chrome_close, size: 14),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

