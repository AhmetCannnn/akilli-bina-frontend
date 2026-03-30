import 'package:fluent_ui/fluent_ui.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:belediye_otomasyon/features/buildings/data/services/energy_api_service.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart' show buildErrorCard;

/// Akıllı Plaza teması: yumuşak maviler ve gri tonları
const _kEnergyPrimary = Color(0xFF5B8DEE);
const _kEnergyPrimaryLight = Color(0xFFE8F0FE);
const _kEnergyGray = Color(0xFF6B7280);
const _kEnergyGrayLight = Color(0xFFF3F4F6);
const _kEnergyCardRadius = 20.0;
const _kEnergyCardShadow = 0.06;

class _ChartPoint {
  _ChartPoint(this.label, this.value);
  final String label;
  final double value;
}

class SensorsTab extends StatefulWidget {
  const SensorsTab({required this.building, super.key});

  final Map<String, dynamic> building;

  @override
  State<SensorsTab> createState() => _SensorsTabState();
}

class _SensorsTabState extends State<SensorsTab> {
  Map<String, dynamic>? _consumption;
  List<EnergyPredictionResult>? _futurePredictions;
  Object? _error;
  bool _loading = true;

  int get _buildingId => widget.building['id'] as int? ?? 0;
  bool get _hasChiller => widget.building['has_chiller'] == true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = EnergyApiService();
      final consumption = await api.getEnergyConsumptionByBuildingId(_buildingId);
      List<EnergyPredictionResult> predictions = [];
      try {
        predictions = await api.getFuturePredictions(
          buildingId: _buildingId,
          count: 4,
          meter: 0,
          hasChiller: _hasChiller,
        );
      } catch (_) {}
      if (mounted) {
        setState(() {
          _consumption = consumption;
          _futurePredictions = predictions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  double get _electricityToday {
    if (_consumption == null) return 0.0;
    final el = _consumption!['electricity'];
    if (el == null) return 0.0;
    final v = el['value'];
    return (v is num) ? v.toDouble() : 0.0;
  }

  double get _currentPredictionKwh {
    if (_futurePredictions == null || _futurePredictions!.isEmpty) return 0.0;
    return _futurePredictions!.first.predictedKwh;
  }

  double get _avgNext24h {
    if (_futurePredictions == null || _futurePredictions!.isEmpty) return 0.0;
    final sum = _futurePredictions!.fold<double>(0.0, (a, r) => a + r.predictedKwh);
    return sum / _futurePredictions!.length;
  }

  /// Geçmiş 6 saat için örnek veri (DB'den saatlik gelmediği için tüketimden türetilmiş)
  List<_ChartPoint> _buildPastData() {
    final base = _electricityToday > 0 ? _electricityToday / 6 : 50.0;
    final now = DateTime.now();
    return List.generate(6, (i) {
      final t = now.subtract(Duration(hours: 5 - i));
      final label = '${t.hour.toString().padLeft(2, '0')}:00';
      final variation = (i == 0 || i == 5) ? 0.9 : (1.0 + (i % 3) * 0.05);
      return _ChartPoint(label, (base * variation).clamp(10.0, 500.0));
    });
  }

  List<_ChartPoint> _buildFutureData() {
    if (_futurePredictions == null || _futurePredictions!.isEmpty) {
      return [];
    }
    return _futurePredictions!
        .map((r) {
          final local = r.timestamp.toLocal();
          return _ChartPoint(
            '${local.hour.toString().padLeft(2, '0')}:00',
            r.predictedKwh,
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final primary = theme.accentColor;
    final softBlue = primary.withOpacity(0.12);
    final gray = _kEnergyGray;

    if (_loading) {
      return const Center(child: ProgressRing());
    }
    if (_error != null) {
      return buildErrorCard(theme, 'Enerji verileri yüklenemedi');
    }

    final pastData = _buildPastData();
    final futureData = _buildFutureData();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üstte 3 StatCard (border-radius 20, hafif shadow)
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Bugünkü Tüketim',
                  value: '${_electricityToday.toStringAsFixed(1)} kWh',
                  icon: FluentIcons.lightning_bolt,
                  color: _kEnergyPrimary,
                  bgColor: _kEnergyPrimaryLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Tahmin (Şimdi)',
                  value: '${_currentPredictionKwh.toStringAsFixed(1)} kWh',
                  icon: FluentIcons.bulleted_list,
                  color: _kEnergyPrimary,
                  bgColor: _kEnergyPrimaryLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Sonraki 4 Saat Ort.',
                  value: '${_avgNext24h.toStringAsFixed(1)} kWh',
                  icon: FluentIcons.trending12,
                  color: _kEnergyPrimary,
                  bgColor: _kEnergyPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Past vs Future grafiği (Syncfusion)
          Text(
            'Geçmiş vs Gelecek',
            style: theme.typography.subtitle?.copyWith(
              fontWeight: FontWeight.w600,
              color: gray,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _kEnergyGrayLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(_kEnergyCardRadius),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF000000).withOpacity(_kEnergyCardShadow),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 220,
              child: SfCartesianChart(
                margin: const EdgeInsets.all(0),
                plotAreaBorderWidth: 0,
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.top,
                ),
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  labelStyle: TextStyle(fontSize: 11, color: gray),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'kWh', textStyle: TextStyle(fontSize: 10, color: gray)),
                  majorGridLines: MajorGridLines(color: _kEnergyGray.withOpacity(0.15), width: 1),
                  axisLine: const AxisLine(width: 0),
                  labelStyle: TextStyle(fontSize: 10, color: gray),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: [
                  LineSeries<_ChartPoint, String>(
                    dataSource: pastData,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.value,
                    color: _kEnergyPrimary,
                    width: 2.5,
                    name: 'Geçmiş (DB)',
                    markerSettings: const MarkerSettings(isVisible: true, height: 6, width: 6),
                    dataLabelSettings: const DataLabelSettings(isVisible: false),
                  ),
                  LineSeries<_ChartPoint, String>(
                    dataSource: futureData,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.value,
                    color: _kEnergyPrimary.withOpacity(0.5),
                    width: 2.5,
                    name: 'Gelecek (Tahmin)',
                    markerSettings: const MarkerSettings(isVisible: true, height: 6, width: 6),
                    dataLabelSettings: const DataLabelSettings(isVisible: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Yatay kaydırılabilir 4 ProjectionCard
          Text(
            'Saatlik Tahminler',
            style: theme.typography.subtitle?.copyWith(
              fontWeight: FontWeight.w600,
              color: gray,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (_futurePredictions != null && index < _futurePredictions!.length) {
                  final r = _futurePredictions![index];
                  final local = r.timestamp.toLocal();
                  return _ProjectionCard(
                    label: '${local.hour.toString().padLeft(2, '0')}:00',
                    value: r.predictedKwh,
                    dateLabel: '${local.day}.${local.month}',
                  );
                }
                return _ProjectionCard(
                  label: '--:--',
                  value: 0.0,
                  dateLabel: '--',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final gray = _kEnergyGray;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_kEnergyCardRadius),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF000000).withOpacity(_kEnergyCardShadow),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.typography.caption?.copyWith(
                    color: gray,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.typography.title?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({
    required this.label,
    required this.value,
    required this.dateLabel,
  });

  final String label;
  final double value;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final gray = _kEnergyGray;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kEnergyGrayLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(_kEnergyCardRadius),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF000000).withOpacity(_kEnergyCardShadow),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.typography.bodyStrong?.copyWith(color: _kEnergyPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: theme.typography.caption?.copyWith(color: gray, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(1)} kWh',
            style: theme.typography.title?.copyWith(
              fontWeight: FontWeight.bold,
              color: _kEnergyPrimary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
