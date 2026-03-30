import '../../../../core/services/api_service.dart';

class VisitorApiService {
  final ApiService _apiService = ApiService();

  /// Belirli bir binanın ziyaretçilerini getirir
  Future<List<Map<String, dynamic>>> getVisitorsByBuilding(
    int buildingId, {
    DateTime? visitDate,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (visitDate != null) {
      queryParameters['visit_date'] =
          visitDate.toIso8601String().split('T')[0];
    }

    final response = await _apiService.get(
      '/visitors/building/$buildingId',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Günlük ziyaretçi özetini getirir
  Future<Map<String, dynamic>> getDailyVisitorSummary(
    int buildingId,
    DateTime visitDate,
  ) async {
    final dateStr = visitDate.toIso8601String().split('T')[0];
    final response = await _apiService.get(
      '/visitors/building/$buildingId/daily',
      queryParameters: {'visit_date': dateStr},
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// Yeni ziyaretçi kaydı oluşturur
  Future<Map<String, dynamic>?> createVisitor(Map<String, dynamic> visitorData) async {
    final response = await _apiService.post('/visitors/', data: visitorData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Ziyaretçi çıkış işlemi yapar
  Future<bool> checkoutVisitor(String visitorId, DateTime exitTime) async {
    final checkoutData = {
      'exit_time': exitTime.toIso8601String().split('T')[1].substring(0, 8), // HH:MM:SS format
    };

    await _apiService.put('/visitors/$visitorId/checkout', data: checkoutData);
    return true;
  }

  /// Ziyaretçi bilgilerini günceller
  Future<Map<String, dynamic>?> updateVisitor(
    String visitorId,
    Map<String, dynamic> updateData,
  ) async {
    final response = await _apiService.put('/visitors/$visitorId', data: updateData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Ziyaretçi kaydını siler
  Future<bool> deleteVisitor(String visitorId) async {
    await _apiService.delete('/visitors/$visitorId');
    return true;
  }
}
