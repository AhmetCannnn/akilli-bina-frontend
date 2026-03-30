import '../../../../core/services/api_service.dart';

class EnergyApiService {
  final ApiService _apiService = ApiService();

  /// Mevcut tüketim (DB): elektrik, su, gaz
  Future<Map<String, dynamic>> getEnergyConsumptionByBuildingId(int buildingId) async {
    final response = await _apiService.get('/buildings/$buildingId/energy-consumption');
    return Map<String, dynamic>.from(response.data);
  }

  /// Tek zaman için tahmin (POST /energy/predict)
  Future<EnergyPredictionResult> predictEnergy({
    required int buildingId,
    required DateTime timestamp,
    int meter = 0,
    bool? hasChiller,
  }) async {
    final body = <String, dynamic>{
      'building_id': buildingId,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'meter': meter,
    };
    if (hasChiller != null) body['has_chiller'] = hasChiller;
    final response = await _apiService.post('/energy/predict', data: body);
    final data = Map<String, dynamic>.from(response.data);
    return EnergyPredictionResult(
      timestamp: DateTime.parse(data['timestamp'] as String),
      predictedKwh: (data['predicted_kwh'] as num).toDouble(),
      meter: data['meter'] as int? ?? meter,
    );
  }

  /// Gelecek N saat için tahmin listesi (her saat başı)
  Future<List<EnergyPredictionResult>> getFuturePredictions({
    required int buildingId,
    int count = 4,
    int meter = 0,
    bool? hasChiller,
  }) async {
    final now = DateTime.now().toUtc();
    final results = <EnergyPredictionResult>[];
    for (var i = 1; i <= count; i++) {
      final ts = now.add(Duration(hours: i));
      try {
        final r = await predictEnergy(
          buildingId: buildingId,
          timestamp: ts,
          meter: meter,
          hasChiller: hasChiller,
        );
        results.add(r);
      } catch (_) {
        break;
      }
    }
    return results;
  }
}

class EnergyPredictionResult {
  const EnergyPredictionResult({
    required this.timestamp,
    required this.predictedKwh,
    this.meter = 0,
  });
  final DateTime timestamp;
  final double predictedKwh;
  final int meter;
}
