import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/api_error.dart';

class MaintenanceApiService {
  final ApiService _apiService = ApiService();

  /// Tüm bakım kayıtlarını getirir (tüm binalar)
  Future<List<Map<String, dynamic>>> getAllMaintenance({
    String? statusFilter,
    String? maintenanceType,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (statusFilter != null) queryParams['status_filter'] = statusFilter;
    if (maintenanceType != null) queryParams['maintenance_type'] = maintenanceType;

    try {
      final response = await _apiService.get(
        '/maintenance/',
        queryParameters: queryParams,
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Belirli bir binaya ait bakım kayıtlarını getirir
  Future<List<Map<String, dynamic>>> getMaintenanceByBuilding(
    int buildingId, {
    String? statusFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (statusFilter != null) queryParams['status_filter'] = statusFilter;

    try {
      final response = await _apiService.get(
        '/maintenance/building/$buildingId',
        queryParameters: queryParams,
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Belirli bir binaya ait bakım özetini getirir
  Future<Map<String, dynamic>?> getMaintenanceSummary(int buildingId) async {
    try {
      final response = await _apiService.get('/maintenance/building/$buildingId/summary');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Yeni bakım kaydı oluşturur
  Future<Map<String, dynamic>?> createMaintenance(Map<String, dynamic> maintenanceData) async {
    try {
      final response = await _apiService.post('/maintenance/', data: maintenanceData);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Mevcut bakım kaydını günceller
  Future<Map<String, dynamic>?> updateMaintenance(
    String maintenanceId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _apiService.put('/maintenance/$maintenanceId', data: updateData);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Bakım kaydını siler (soft delete)
  Future<bool> deleteMaintenance(String maintenanceId) async {
    try {
      await _apiService.delete('/maintenance/$maintenanceId');
      return true;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Bakım durumunu günceller
  Future<bool> updateMaintenanceStatus(String maintenanceId, String status) async {
    try {
      await _apiService.put('/maintenance/$maintenanceId', data: {'status': status});
      return true;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
