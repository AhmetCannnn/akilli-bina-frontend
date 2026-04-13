import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:belediye_otomasyon/core/utils/api_error.dart';
import 'package:belediye_otomasyon/features/buildings/presentation/providers/building_provider.dart';
import 'package:belediye_otomasyon/features/buildings/data/services/energy_api_service.dart';
import 'package:belediye_otomasyon/features/maintenance/data/services/maintenance_api_service.dart';
import 'package:belediye_otomasyon/features/issues/data/services/issue_api_service.dart';
import 'package:belediye_otomasyon/features/issues/domain/models/issue.dart';
import 'package:belediye_otomasyon/features/issues/presentation/screens/active_issues_screen.dart';
import 'package:belediye_otomasyon/features/maintenance/presentation/screens/maintenance_suggestions_screen.dart';
import 'package:belediye_otomasyon/features/maintenance/presentation/widgets/maintenance_entity_list_card.dart'
    show maintenanceStatusColorFor, maintenanceStatusLabel, maintenanceTypeLabel;
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';
import 'package:belediye_otomasyon/core/widgets/app_scaffold_page.dart';
import 'package:belediye_otomasyon/core/widgets/entity_list_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 12.0;
  latlng.LatLng _currentCenter = const latlng.LatLng(37.8716, 32.4846);
  final EnergyApiService _energyApiService = EnergyApiService();
  final MaintenanceApiService _maintenanceApiService = MaintenanceApiService();
  final IssueApiService _issueApiService = IssueApiService();
  EnergySummaryTimeseries? _energySummary;
  bool _energyLoading = true;
  String? _energyError;
  double _totalMaintenanceCost = 0;
  double _totalIssueCost = 0;
  /// Kritik arıza + kritik bakım kayıtları (tarihe göre sıralı, yeni üstte).
  List<_CriticalListEntry> _criticalItems = [];

  @override
  void initState() {
    super.initState();
    _loadEnergySummary();
    _loadPortfolioCosts();
  }

  Future<void> _loadEnergySummary() async {
    setState(() {
      _energyLoading = true;
      _energyError = null;
    });
    try {
      final summary = await _energyApiService.getSummaryTimeseries(
        range: 'monthly',
      );
      if (!mounted) return;
      setState(() {
        _energySummary = summary;
        _energyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _energyError = humanizeError(e);
        _energyLoading = false;
      });
    }
  }

  /// Backend `limit` en fazla 100 (issues & maintenance router); aşımı 422 verir, tüm yükleme düşer.
  static const int _portfolioApiPageSize = 100;

  Future<List<Map<String, dynamic>>> _loadAllIssuesForPortfolio() async {
    final all = <Map<String, dynamic>>[];
    for (var offset = 0; ; offset += _portfolioApiPageSize) {
      final page = await _issueApiService.getIssues(
        limit: _portfolioApiPageSize,
        offset: offset,
      );
      all.addAll(page);
      if (page.length < _portfolioApiPageSize) break;
    }
    return all;
  }

  Future<List<Map<String, dynamic>>> _loadAllMaintenancesForPortfolio() async {
    final all = <Map<String, dynamic>>[];
    for (var offset = 0; ; offset += _portfolioApiPageSize) {
      final page = await _maintenanceApiService.getAllMaintenance(
        limit: _portfolioApiPageSize,
        offset: offset,
      );
      all.addAll(page);
      if (page.length < _portfolioApiPageSize) break;
    }
    return all;
  }

  Future<void> _loadPortfolioCosts() async {
    try {
      final results = await Future.wait([
        _loadAllMaintenancesForPortfolio(),
        _loadAllIssuesForPortfolio(),
      ]);
      final maintenances = results[0];
      final issues = results[1];
      if (!mounted) return;

      final maintenanceTotal = maintenances.fold<double>(0, (sum, item) {
        final raw = item['cost'];
        final cost = switch (raw) {
          num v => v.toDouble(),
          String s => double.tryParse(s) ?? 0,
          _ => 0.0,
        };
        return sum + cost;
      });

      final issueTotal = issues.fold<double>(0, (sum, item) {
        final raw = item['actual_cost'] ?? item['estimated_cost'];
        final cost = switch (raw) {
          num v => v.toDouble(),
          String s => double.tryParse(s) ?? 0,
          _ => 0.0,
        };
        return sum + cost;
      });

      final critical = <_CriticalListEntry>[];
      for (final i in issues) {
        final priority = IssuePriorityX.fromApiValue(i['priority']?.toString());
        final st = IssueStatusX.fromApiValue(i['status']?.toString());
        if (priority != IssuePriority.critical || st == IssueStatus.resolved) {
          continue;
        }
        final title = (i['title'] ?? 'Arıza').toString();
        final building = (i['building_name'] ?? '').toString().trim();
        final rawDescription = (i['description'] ?? '').toString();
        final category = (i['category'] ?? '').toString().trim();
        final loc = (i['location'] ?? '').toString().trim();
        final created = DateTime.tryParse((i['created_at'] ?? '').toString());
        final issueExtraParts = <String>[
          if (category.isNotEmpty) 'Kategori: $category',
          if (loc.isNotEmpty) (loc.length <= 80 ? loc : '${loc.substring(0, 77)}…'),
        ];
        final issueExtra = issueExtraParts.join(' · ');
        critical.add(
          _CriticalListEntry(
            recordId: (i['id'] ?? '').toString(),
            kindLabel: 'Arıza',
            title: title,
            buildingLabel: building.isNotEmpty ? building : 'Bina bilgisi yok',
            statusLabel: st.displayName,
            rawDescription: rawDescription,
            extraDetail: issueExtra.isEmpty ? null : issueExtra,
            iconColor: IssuePriority.critical.color,
            statusPillColor: st.color,
            dateLabel: _formatCriticalListDateTime(created),
            sortDate: created,
          ),
        );
      }
      for (final m in maintenances) {
        if ((m['priority'] ?? '').toString() != 'Kritik') continue;
        final st = (m['status'] ?? '').toString().toLowerCase();
        if (st == 'tamamlandı' ||
            st == 'completed' ||
            st == 'cancelled' ||
            st == 'iptal') {
          continue;
        }
        final title = (m['title'] ?? 'Bakım').toString();
        final building = (m['building_name'] ?? '').toString().trim();
        final rawDescription = (m['description'] ?? '').toString();
        final statusRaw = m['status']?.toString();
        final stLabel = maintenanceStatusLabel(statusRaw);
        final typeLabel = maintenanceTypeLabel(m['maintenance_type']?.toString());
        final loc = (m['location'] ?? '').toString().trim();
        final created = DateTime.tryParse((m['created_at'] ?? '').toString());
        final scheduled = DateTime.tryParse((m['scheduled_date'] ?? '').toString());
        final sortDate = created ?? scheduled;
        final maintExtraParts = <String>[
          if (typeLabel.isNotEmpty) 'Tür: $typeLabel',
          if (loc.isNotEmpty) (loc.length <= 60 ? loc : '${loc.substring(0, 57)}…'),
        ];
        final maintExtra = maintExtraParts.join(' · ');
        critical.add(
          _CriticalListEntry(
            recordId: (m['id'] ?? '').toString(),
            kindLabel: 'Bakım',
            title: title,
            buildingLabel: building.isNotEmpty ? building : 'Bina bilgisi yok',
            statusLabel: stLabel,
            rawDescription: rawDescription,
            extraDetail: maintExtra.isEmpty ? null : maintExtra,
            iconColor: const Color(0xFF5A82EA),
            statusPillColor: maintenanceStatusColorFor(statusRaw),
            dateLabel: _formatCriticalListDateTime(sortDate),
            sortDate: sortDate,
          ),
        );
      }

      critical.sort((a, b) {
        final ad = a.sortDate;
        final bd = b.sortDate;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });

      setState(() {
        _totalMaintenanceCost = maintenanceTotal;
        _totalIssueCost = issueTotal;
        _criticalItems = critical;
      });
    } catch (_) {
      // Sessiz geç: kartlar veri yoksa 0 gösterir.
    }
  }

  ({List<FlSpot> spots, List<String> labels}) _buildSeriesData(
    List<EnergySeriesPoint> points,
  ) {
    final spots = <FlSpot>[];
    final labels = <String>[];
    final monthTotals = List<double>.filled(12, 0);
    for (final p in points) {
      final month = p.periodStart.toLocal().month;
      monthTotals[month - 1] += p.total;
    }
    for (var i = 0; i < 12; i++) {
      spots.add(FlSpot(i.toDouble(), monthTotals[i]));
      labels.add('${i + 1}');
    }
    return (spots: spots, labels: labels);
  }

  // Buildings will be loaded from backend via Riverpod

  ({latlng.LatLng point, LocationQuality quality}) _resolveBuildingPosition(
    Map<String, dynamic> buildingData,
  ) {
    final mapLat = double.tryParse((buildingData['map_lat'] ?? '').toString());
    final mapLng = double.tryParse((buildingData['map_lng'] ?? '').toString());
    final qualityRaw = (buildingData['location_quality'] ?? '').toString();
    final quality = switch (qualityRaw) {
      'exact' => LocationQuality.exact,
      'geocoded' => LocationQuality.geocoded,
      'fallback' => LocationQuality.fallback,
      _ => LocationQuality.fallback,
    };

    if (mapLat != null && mapLng != null) {
      return (point: latlng.LatLng(mapLat, mapLng), quality: quality);
    }

    // Beklenmeyen durumda bile UI kırılmasın: tek bir sabit fallback merkez.
    return (
      point: const latlng.LatLng(37.8716, 32.4846),
      quality: LocationQuality.fallback,
    );
  }

  // Helper method to convert backend data to Building model
  List<Building> _convertToBuildings(List<Map<String, dynamic>> buildingsData) {
    return buildingsData.map((buildingData) {
      final resolvedPosition = _resolveBuildingPosition(buildingData);
      
      return Building(
        id: buildingData['id']?.toString() ?? '0',
        name: buildingData['name']?.toString() ?? 'Bilinmeyen Bina',
        position: resolvedPosition.point,
        locationQuality: resolvedPosition.quality,
      );
    }).toList();
  }

  Color _getPositionColor(LocationQuality quality) {
    switch (quality) {
      case LocationQuality.exact:
        return Colors.green;
      case LocationQuality.geocoded:
        return Colors.orange;
      case LocationQuality.fallback:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final buildingsAsync = ref.watch(buildingControllerProvider);

    return buildingsAsync.when(
      data: (buildings) =>
          _buildHomeContent(context, theme, buildings),
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

  Widget _buildHomeContent(
    BuildContext context,
    FluentThemeData theme,
    List<Map<String, dynamic>> buildings,
  ) {
    final mappedBuildings = _convertToBuildings(buildings);
    final horizontalPad = PageHeader.horizontalPadding(context);
    return AppScaffoldPage(
      content: Container(
        color: theme.scaffoldBackgroundColor,
        padding: EdgeInsets.only(
          left: horizontalPad,
          right: horizontalPad,
          top: AppUiTokens.space8,
          bottom: AppUiTokens.space12,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık AppShell içinde yönetiliyor
            // Harita Bölümü (FlutterMap)
            SizedBox(
              width: double.infinity,
              child: Card(
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
                            userAgentPackageName: 'belediye_otomasyon',
                          ),
                          MarkerLayer(
                            markers: mappedBuildings.map((building) {
                              return Marker(
                                point: building.position,
                                width: 12,
                                height: 12,
                                child: GestureDetector(
                                  onTap: () {
                                    displayInfoBar(
                                      context,
                                      builder: (context, close) => InfoBar(
                                        title: Text(building.name),
                                        severity: InfoBarSeverity.info,
                                        onClose: close,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _getPositionColor(
                                        building.locationQuality,
                                      ),
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
                              onPressed: () => _openFullScreenMap(mappedBuildings),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
            SizedBox(height: AppUiTokens.space16),
            _buildSustainabilitySummary(theme, buildings),
            SizedBox(height: AppUiTokens.space16),
            // Enerji grafikleri
            _buildEnergyChartsSection(theme),
            SizedBox(height: AppUiTokens.space16),
            _buildCriticalRecordsSection(theme),
          ],
        ),
      ),
    ),
    );
  }

  void _openFullScreenMap(List<Building> buildings) {
    Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => _FullScreenMapPage(
          initialCenter: _currentCenter,
          initialZoom: _currentZoom,
          buildings: buildings,
          pointColor: _getPositionColor,
        ),
      ),
    );
  }

  ({double avgCo2Kg, double avgGreenScore}) _computePortfolioAverages(
    List<Map<String, dynamic>> buildings,
  ) {
    double co2Sum = 0;
    int co2Count = 0;
    double scoreSum = 0;
    int scoreCount = 0;

    for (final b in buildings) {
      final co2Raw = b['co2_emission'];
      final co2 = switch (co2Raw) {
        num v => v.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
      if (co2 != null) {
        co2Sum += co2;
        co2Count++;
      }

      final scoreRaw = b['green_score'] ?? b['sustainability_score'];
      final rawScore = switch (scoreRaw) {
        num v => v.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
      if (rawScore != null) {
        final normalized = rawScore > 1 ? (rawScore / 100) : rawScore;
        scoreSum += normalized.clamp(0, 1);
        scoreCount++;
      }
    }

    final avgCo2 = co2Count > 0 ? co2Sum / co2Count : 84.0;
    final avgScore = scoreCount > 0 ? scoreSum / scoreCount : 0.72;
    return (avgCo2Kg: avgCo2, avgGreenScore: avgScore);
  }

  Widget _buildSustainabilitySummary(
    FluentThemeData theme,
    List<Map<String, dynamic>> buildings,
  ) {
    final averages = _computePortfolioAverages(buildings);
    final avgCo2Kg = averages.avgCo2Kg;
    final avgGreenScore = averages.avgGreenScore;
    final co2Color = avgCo2Kg < 100
        ? const Color(0xFF2FB06E)
        : (avgCo2Kg < 200 ? const Color(0xFFE6973D) : const Color(0xFFE25757));
    final greenScoreColor = avgGreenScore >= 0.8
        ? const Color(0xFF24A765)
        : (avgGreenScore >= 0.6
              ? const Color(0xFFE6973D)
              : const Color(0xFFE25757));

    final cards = [
      _PortfolioMetricCard(
        title: 'Karbon Ayak İzi',
        value: '${avgCo2Kg.toStringAsFixed(0)} kgCO₂e',
        color: co2Color,
      ),
      _PortfolioMetricCard(
        title: 'Yeşil Skor',
        value: '%${(avgGreenScore * 100).round()}',
        color: greenScoreColor,
      ),
      _PortfolioMetricCard(
        title: 'Toplam Bakım Maliyeti',
        value: _formatCurrency(_totalMaintenanceCost),
        color: const Color(0xFF5A82EA),
      ),
      _PortfolioMetricCard(
        title: 'Toplam Arıza Maliyeti',
        value: _formatCurrency(_totalIssueCost),
        color: const Color(0xFFE25757),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final width = constraints.maxWidth;
        final isWide = width >= 1100;
        final columns = isWide ? 4 : 2;
        final itemWidth = (width - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
        );
      },
    );
  }

  String _formatCurrency(double value) {
    final rounded = value.round();
    final digits = rounded.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final idxFromEnd = digits.length - i;
      buf.write(digits[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buf.write('.');
      }
    }
    return '₺${buf.toString()}';
  }

  String _formatCriticalListDateTime(DateTime? d) {
    if (d == null) return '—';
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _criticalCardBodyText(_CriticalListEntry e) {
    final raw = e.rawDescription.trim();
    if (raw.isNotEmpty) return raw;
    final ex = e.extraDetail?.trim();
    if (ex != null && ex.isNotEmpty) return ex;
    return '—';
  }

  Widget _buildCriticalRecordsSection(FluentThemeData theme) {
    const listMaxHeight = 520.0;
    const criticalAccent = Color(0xFFC42B1C);
    final isDark = theme.brightness == Brightness.dark;
    final subtitleColor = isDark ? const Color(0xFFC8C8C8) : const Color(0xFF5C5C5C);
    final bodyMutedColor = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF404040);

    const titleTextStyle = TextStyle(
      fontWeight: FontWeight.w800,
      color: criticalAccent,
      letterSpacing: 0.2,
      height: 1.25,
      fontSize: 20,
    );

    /// Enerji özeti ile aynı: tek Card + Padding. Sol kırmızı şerit [DecoratedBox] ile (layout riski yok).
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: criticalAccent, width: 5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Kritik Operasyon Kayıtları',
                      textAlign: TextAlign.center,
                      style: titleTextStyle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Öncelikli takip gereken açık arıza ve bakım kayıtları',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
                if (_criticalItems.isEmpty) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  FluentIcons.warning,
                                  size: 48,
                                  color: criticalAccent.withOpacity(0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Henüz kritik kayıt bulunmuyor',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: bodyMutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          height: listMaxHeight,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _criticalItems.length,
                            itemBuilder: (context, index) {
                              final e = _criticalItems[index];
                              final subtitle = e.buildingLabel != 'Bina bilgisi yok'
                                  ? e.buildingLabel
                                  : null;
                              final bodyFromExtraOnly = e.rawDescription.trim().isEmpty &&
                                  (e.extraDetail?.trim().isNotEmpty ?? false);
                              final showExtraInFooter = e.rawDescription.trim().isNotEmpty &&
                                  (e.extraDetail?.trim().isNotEmpty ?? false);
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    if (e.kindLabel == 'Arıza') {
                                      Navigator.push(
                                        context,
                                        FluentPageRoute(
                                          builder: (context) =>
                                              ActiveIssuesScreen(
                                            highlightIssueId: e.recordId
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : e.recordId.trim(),
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        FluentPageRoute(
                                          builder: (context) =>
                                              MaintenanceSuggestionsScreen(
                                            highlightMaintenanceId: e.recordId
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : e.recordId.trim(),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: EntityListCard(
                                    margin: EdgeInsets.only(
                                      bottom: index == _criticalItems.length - 1
                                          ? 0
                                          : 10,
                                    ),
                                    header: EntityListCardHeaderRow(
                                      leading: EntityListCardLeadingIconBox(
                                        icon: e.kindLabel == 'Arıza'
                                            ? FluentIcons.warning
                                            : FluentIcons.build_definition,
                                        color: e.iconColor,
                                      ),
                                      title: e.title,
                                      subtitle: subtitle,
                                      trailing: EntityListCardHeaderPill(
                                        label: e.statusLabel,
                                        color: e.statusPillColor,
                                      ),
                                    ),
                                    description: _criticalCardBodyText(e),
                                    descriptionMaxLines:
                                        bodyFromExtraOnly ? 2 : 3,
                                    footer: Wrap(
                                      spacing: 16,
                                      runSpacing: 8,
                                      children: [
                                        EntityListCardMetaIconText(
                                          icon: FluentIcons.tag,
                                          text: e.kindLabel,
                                        ),
                                        EntityListCardMetaIconText(
                                          icon: FluentIcons.clock,
                                          text: 'Kayıt: ${e.dateLabel}',
                                        ),
                                        if (showExtraInFooter)
                                          EntityListCardMetaIconText(
                                            icon: FluentIcons.location,
                                            text: e.extraDetail!,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyChartsSection(FluentThemeData theme) {
    final chartConfigs = <_EnergyChartConfig>[
      _EnergyChartConfig('Elektrik (kWh)', Colors.orange),
      _EnergyChartConfig('Su (m³)', Colors.blue),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 10),
              child: Center(
                child: Text(
                  'Enerji Tüketim Özeti',
                  textAlign: TextAlign.center,
                  style: theme.typography.subtitle?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (_energyLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: ProgressRing()),
              )
            else if (_energyError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _energyError!,
                        style: theme.typography.body?.copyWith(color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      onPressed: _loadEnergySummary,
                      child: const Text('Yeniden Dene'),
                    ),
                  ],
                ),
              )
            else
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                final electricity = _buildSeriesData(
                  _energySummary?.electricity ?? const [],
                );
                final water = _buildSeriesData(
                  _energySummary?.water ?? const [],
                );
                final charts = chartConfigs
                    .map((c) {
                      final series = c.title.startsWith('Elektrik')
                          ? electricity
                          : water;
                      return _MiniLineChart(
                        title: c.title,
                        color: c.color,
                        spots: series.spots,
                        labels: series.labels,
                      );
                    })
                    .toList();
                if (isNarrow) {
                  return Column(
                    children: [
                      for (var i = 0; i < charts.length; i++) ...[
                        charts[i],
                        if (i != charts.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: charts[0]),
                    const SizedBox(width: 12),
                    Expanded(child: charts[1]),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}

// Bina modeli
class Building {
  final String id;
  final String name;
  final latlng.LatLng position;
  final LocationQuality locationQuality;

  Building({
    required this.id,
    required this.name,
    required this.position,
    required this.locationQuality,
  });
}

enum LocationQuality { exact, geocoded, fallback }

class _EnergyChartConfig {
  const _EnergyChartConfig(this.title, this.color);

  final String title;
  final Color color;
}

class _CriticalListEntry {
  const _CriticalListEntry({
    required this.recordId,
    required this.kindLabel,
    required this.title,
    required this.buildingLabel,
    required this.statusLabel,
    required this.rawDescription,
    this.extraDetail,
    required this.iconColor,
    required this.statusPillColor,
    required this.dateLabel,
    this.sortDate,
  });

  /// API `id`; detay listesinde vurgu için.
  final String recordId;
  final String kindLabel;
  final String title;
  final String buildingLabel;
  final String statusLabel;
  final String rawDescription;
  final String? extraDetail;
  final Color iconColor;
  final Color statusPillColor;
  final String dateLabel;
  final DateTime? sortDate;
}

class _PortfolioMetricCard extends StatelessWidget {
  const _PortfolioMetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.typography.caption?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.typography.caption?.color?.withOpacity(0.78),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: theme.typography.subtitle?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  const _MiniLineChart({
    required this.title,
    required this.color,
    required this.spots,
    required this.labels,
  });

  final String title;
  final Color color;
  final List<FlSpot> spots;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final maxX = spots.isEmpty ? 1.0 : (spots.length - 1).toDouble();
    final maxY = spots.isEmpty ? 0.0 : spots.map((s) => s.y).reduce(math.max);
    double niceStep(double raw) {
      if (raw <= 0) return 1;
      final exponent = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
      final fraction = raw / exponent;
      final niceFraction = fraction <= 1
          ? 1
          : fraction <= 2
          ? 2
          : fraction <= 5
          ? 5
          : 10;
      return niceFraction * exponent;
    }

    final yInterval = maxY <= 0 ? 1.0 : niceStep(maxY / 4);
    final roundedMaxY = maxY <= 0 ? 4.0 : ((maxY / yInterval).ceil() * yInterval);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.typography.bodyStrong,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 170,
              child: spots.isEmpty
                  ? Center(
                      child: Text(
                        'Veri yok',
                        style: theme.typography.caption,
                      ),
                    )
                  : LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.10),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final v = value.toInt();
                          final label = v >= 0 && v < labels.length ? labels[v] : '';
                          return Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: maxX,
                  minY: 0,
                  maxY: roundedMaxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.9),
                          color.withOpacity(0.6),
                        ],
                      ),
                      barWidth: 2.8,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 2.2,
                          color: color,
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withOpacity(0.18),
                            color.withOpacity(0.03),
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
                          '$v',
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
    required this.pointColor,
  });

  final latlng.LatLng initialCenter;
  final double initialZoom;
  final List<Building> buildings;
  final Color Function(LocationQuality) pointColor;

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
                userAgentPackageName: 'belediye_otomasyon',
              ),
              MarkerLayer(
                markers: widget.buildings.map((b) {
                  return Marker(
                    point: b.position,
                    width: 28,
                    height: 28,
                    child: GestureDetector(
                      onTap: () {
                        displayInfoBar(
                          context,
                          builder: (context, close) => InfoBar(
                            title: Text(b.name),
                            severity: InfoBarSeverity.info,
                            onClose: close,
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.pointColor(b.locationQuality),
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

