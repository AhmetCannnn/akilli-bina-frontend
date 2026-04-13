import 'package:fluent_ui/fluent_ui.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:belediye_otomasyon/features/buildings/data/services/energy_api_service.dart';
import 'package:belediye_otomasyon/features/buildings/data/services/water_api_service.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';

/// Akıllı Plaza teması: yumuşak maviler ve gri tonları
const _kEnergyPrimary = Color(0xFFF59E0B); // sarı-turuncu
const _kEnergyGray = Color(0xFF6B7280);
const _kWaterPrimary = Color(0xFF2563EB); // mavi (soğuk su)
const _kHotWaterPrimary = Color(0xFFEF476F); // kırmızı-pembe (sıcak su)

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
  List<EnergyPredictionResult>? _futurePredictions;
  List<WaterPredictionResult>? _futureWaterColdPredictions;
  List<WaterPredictionResult>? _futureWaterHotPredictions;
  bool _loading = true;
  bool _customLoading = false;
  DateTime _customDate = DateTime.now();
  int _customHour = DateTime.now().hour;
  EnergyPredictionResult? _customEnergy;
  WaterPredictionResult? _customWaterCold;
  WaterPredictionResult? _customWaterHot;
  String? _customError;

  int get _buildingId => widget.building['id'] as int? ?? 0;
  bool get _hasChiller => widget.building['has_chiller'] == true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = EnergyApiService();
    List<EnergyPredictionResult> predictions = [];
    try {
      predictions = await api.getFuturePredictions(
        buildingId: _buildingId,
        count: 4,
        meter: 0,
        hasChiller: _hasChiller,
      );
    } catch (_) {}
    List<WaterPredictionResult> waterColdPreds = [];
    List<WaterPredictionResult> waterHotPreds = [];
    try {
      waterColdPreds = await WaterApiService().getFutureWaterPredictions(
        buildingId: _buildingId,
        count: 4,
        meter: 1,
      );
    } catch (_) {}
    try {
      waterHotPreds = await WaterApiService().getFutureWaterPredictions(
        buildingId: _buildingId,
        count: 4,
        meter: 3,
      );
    } catch (_) {}
    if (mounted) {
      setState(() {
        _futurePredictions = predictions;
        _futureWaterColdPredictions = waterColdPreds;
        _futureWaterHotPredictions = waterHotPreds;
        _loading = false;
      });
    }
  }

  DateTime _customTargetUtc() {
    final local = DateTime(
      _customDate.year,
      _customDate.month,
      _customDate.day,
      _customHour,
    );
    return local.toUtc();
  }

  Future<void> _runCustomPrediction() async {
    final nowUtc = DateTime.now().toUtc();
    final targetUtc = _customTargetUtc();
    final maxUtc = nowUtc.add(const Duration(hours: 96));
    if (targetUtc.isBefore(nowUtc)) {
      setState(() => _customError = 'Geçmiş saat seçilemez.');
      return;
    }
    if (targetUtc.isAfter(maxUtc)) {
      setState(() => _customError = 'En fazla 96 saat sonrası seçilebilir.');
      return;
    }

    setState(() {
      _customLoading = true;
      _customError = null;
    });
    try {
      final energy = await EnergyApiService().predictEnergy(
        buildingId: _buildingId,
        timestamp: targetUtc,
        meter: 0,
        hasChiller: _hasChiller,
      );
      final waterCold = await WaterApiService().predictWater(
        buildingId: _buildingId,
        timestamp: targetUtc,
        meter: 1,
      );
      final waterHot = await WaterApiService().predictWater(
        buildingId: _buildingId,
        timestamp: targetUtc,
        meter: 3,
      );
      if (!mounted) return;
      setState(() {
        _customEnergy = energy;
        _customWaterCold = waterCold;
        _customWaterHot = waterHot;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _customError = 'Tahmin üretilemedi. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _customLoading = false);
    }
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

  List<_ChartPoint> _buildFutureWaterColdData() {
    if (_futureWaterColdPredictions == null || _futureWaterColdPredictions!.isEmpty) {
      return [];
    }
    return _futureWaterColdPredictions!
        .map((r) {
          final local = r.timestamp.toLocal();
          return _ChartPoint(
            '${local.hour.toString().padLeft(2, '0')}:00',
            r.predictedM3,
          );
        })
        .toList();
  }

  List<_ChartPoint> _buildFutureWaterHotData() {
    if (_futureWaterHotPredictions == null || _futureWaterHotPredictions!.isEmpty) {
      return [];
    }
    return _futureWaterHotPredictions!
        .map((r) {
          final local = r.timestamp.toLocal();
          return _ChartPoint(
            '${local.hour.toString().padLeft(2, '0')}:00',
            r.predictedM3,
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final gray = _kEnergyGray;

    if (_loading) {
      return const Center(child: ProgressRing());
    }

    final futureData = _buildFutureData();
    final futureWaterCold = _buildFutureWaterColdData();
    final futureWaterHot = _buildFutureWaterHotData();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppUiTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            padding: const EdgeInsets.all(AppUiTokens.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spesifik zaman dilimi tahmini',
                  style: theme.typography.bodyStrong?.copyWith(color: gray),
                ),
                const SizedBox(height: AppUiTokens.space8),
                Wrap(
                  spacing: AppUiTokens.space8,
                  runSpacing: AppUiTokens.space8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 170,
                      child: DatePicker(
                        selected: _customDate,
                        onChanged: (d) => setState(() => _customDate = d),
                      ),
                    ),
                    SizedBox(
                      width: 95,
                      child: ComboBox<int>(
                        value: _customHour,
                        items: List.generate(
                          24,
                          (h) => ComboBoxItem<int>(
                            value: h,
                            child: Text('${h.toString().padLeft(2, '0')}:00'),
                          ),
                        ),
                        onChanged: (h) {
                          if (h != null) setState(() => _customHour = h);
                        },
                      ),
                    ),
                    FilledButton(
                      onPressed: _customLoading ? null : _runCustomPrediction,
                      child: _customLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: ProgressRing(strokeWidth: 2),
                            )
                          : const Text('Tahmin Üret'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppUiTokens.space16),
          if (_customError != null) ...[
            Text(
              _customError!,
              style: theme.typography.caption?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: AppUiTokens.space10),
          ],
          if (_customEnergy != null &&
              _customWaterCold != null &&
              _customWaterHot != null) ...[
            Card(
              padding: const EdgeInsets.all(AppUiTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tahmin Sonuçları',
                    style: theme.typography.subtitle?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: gray,
                    ),
                  ),
                  const SizedBox(height: AppUiTokens.space8),
                  Wrap(
                    spacing: AppUiTokens.space10,
                    runSpacing: AppUiTokens.space10,
                    children: [
                      SizedBox(
                        width: 220,
                        child: _StatCard(
                          title: 'Elektrik Tahmini',
                          value: '${_customEnergy!.predictedKwh.toStringAsFixed(1)} kWh',
                          icon: FluentIcons.lightning_bolt,
                          color: _kEnergyPrimary,
                          bgColor: Colors.white,
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: _StatCard(
                          title: 'Soğuk Su Tahmini',
                          value: '${_customWaterCold!.predictedM3.toStringAsFixed(2)} m³',
                          icon: FluentIcons.drop,
                          color: _kWaterPrimary,
                          bgColor: Colors.white,
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: _StatCard(
                          title: 'Sıcak Su Tahmini',
                          value: '${_customWaterHot!.predictedM3.toStringAsFixed(2)} m³',
                          icon: FluentIcons.drop,
                          color: _kHotWaterPrimary,
                          bgColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppUiTokens.space20),
          ],
          // Elektrik + su tahminlerini aynı satırda göster
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ForecastPanel(
                  title: 'Elektrik Tahmini',
                  unit: 'kWh',
                  color: _kEnergyPrimary,
                  chartData: futureData,
                ),
              ),
              const SizedBox(width: AppUiTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ForecastPanel(
                      title: 'Su Tahmini',
                      unit: 'm³',
                      color: _kWaterPrimary,
                      chartData: futureWaterCold,
                      chartDataSecondary: futureWaterHot,
                      secondaryColor: _kHotWaterPrimary,
                      legendPrimary: 'Soğuk Su',
                      legendSecondary: 'Sıcak Su',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUiTokens.space16),
        ],
      ),
    );
  }
}

class _ForecastPanel extends StatelessWidget {
  const _ForecastPanel({
    required this.title,
    required this.unit,
    required this.color,
    required this.chartData,
    this.chartDataSecondary,
    this.secondaryColor,
    this.legendPrimary = 'Gelecek (Tahmin)',
    this.legendSecondary = 'İkincil',
  });

  final String title;
  final String unit;
  final Color color;
  final List<_ChartPoint> chartData;
  final List<_ChartPoint>? chartDataSecondary;
  final Color? secondaryColor;
  final String legendPrimary;
  final String legendSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final gray = _kEnergyGray;
    final avg = chartData.isEmpty
        ? 0.0
        : chartData.map((e) => e.value).reduce((a, b) => a + b) / chartData.length;
    final avgSecondary = (chartDataSecondary == null || chartDataSecondary!.isEmpty)
        ? null
        : chartDataSecondary!.map((e) => e.value).reduce((a, b) => a + b) /
            chartDataSecondary!.length;
    final decimals = unit == 'm³' ? 2 : 1;
    return Card(
      padding: const EdgeInsets.all(AppUiTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.typography.subtitle?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: gray,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppUiTokens.space10,
                  vertical: AppUiTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppUiTokens.radius16),
                ),
                child: Text(
                  'Ort: ${avg.toStringAsFixed(decimals)} $unit',
                  style: theme.typography.caption?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (avgSecondary != null) ...[
                const SizedBox(width: AppUiTokens.space8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppUiTokens.space10,
                    vertical: AppUiTokens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: (secondaryColor ?? color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppUiTokens.radius16),
                  ),
                  child: Text(
                    'Ort: ${avgSecondary.toStringAsFixed(decimals)} $unit',
                    style: theme.typography.caption?.copyWith(
                      color: secondaryColor ?? color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppUiTokens.space8),
          SizedBox(
            height: 220,
            child: SfCartesianChart(
              margin: const EdgeInsets.all(0),
              plotAreaBorderWidth: 0,
              legend: const Legend(isVisible: true, position: LegendPosition.top),
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(fontSize: 11, color: gray),
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(text: unit, textStyle: TextStyle(fontSize: 10, color: gray)),
                majorGridLines: MajorGridLines(color: _kEnergyGray.withOpacity(0.15), width: 1),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(fontSize: 10, color: gray),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: [
                LineSeries<_ChartPoint, String>(
                  dataSource: chartData,
                  xValueMapper: (d, _) => d.label,
                  yValueMapper: (d, _) => d.value,
                  color: color.withOpacity(0.55),
                  width: 2.5,
                  name: legendPrimary,
                  markerSettings: const MarkerSettings(isVisible: true, height: 6, width: 6),
                ),
                if (chartDataSecondary != null)
                  LineSeries<_ChartPoint, String>(
                    dataSource: chartDataSecondary!,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.value,
                    color: (secondaryColor ?? color).withOpacity(0.55),
                    width: 2.5,
                    name: legendSecondary,
                    markerSettings: const MarkerSettings(isVisible: true, height: 6, width: 6),
                  ),
              ],
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

    return Card(
      padding: const EdgeInsets.all(AppUiTokens.space16),
      backgroundColor: bgColor,
      borderColor: _kEnergyGray.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppUiTokens.space8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppUiTokens.radius10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppUiTokens.space10),
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
          const SizedBox(height: AppUiTokens.space12),
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

