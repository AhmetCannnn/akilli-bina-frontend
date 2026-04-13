import '../../../../core/services/api_service.dart';

class WaterApiService {
  final ApiService _apiService = ApiService();

  /// Tek zaman için tahmin (POST /water/predict). meter: 1 soğuk, 3 sıcak.
  Future<WaterPredictionResult> predictWater({
    required int buildingId,
    required DateTime timestamp,
    required int meter,
  }) async {
    final body = <String, dynamic>{
      'building_id': buildingId,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'meter': meter,
    };
    final response = await _apiService.post('/water/predict', data: body);
    final data = Map<String, dynamic>.from(response.data);
    return WaterPredictionResult(
      timestamp: DateTime.parse(data['timestamp'] as String),
      predictedM3: (data['predicted_m3'] as num).toDouble(),
      meter: data['meter'] as int? ?? meter,
    );
  }

  /// Gelecek N saat için tahmin listesi (her saat başı).
  Future<List<WaterPredictionResult>> getFutureWaterPredictions({
    required int buildingId,
    int count = 4,
    required int meter,
  }) async {
    final now = DateTime.now().toUtc();
    final results = <WaterPredictionResult>[];
    for (var i = 1; i <= count; i++) {
      final ts = now.add(Duration(hours: i));
      try {
        final r = await predictWater(
          buildingId: buildingId,
          timestamp: ts,
          meter: meter,
        );
        results.add(r);
      } catch (_) {
        break;
      }
    }
    return results;
  }
}

class WaterPredictionResult {
  const WaterPredictionResult({
    required this.timestamp,
    required this.predictedM3,
    required this.meter,
  });
  final DateTime timestamp;
  final double predictedM3;
  final int meter;
}
