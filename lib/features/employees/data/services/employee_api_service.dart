import 'package:belediye_otomasyon/core/services/api_service.dart';

class EmployeeApiService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getEmployees({
    String? search,
    int? buildingId,
    bool? isActive,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    if (buildingId != null) {
      queryParameters['building_id'] = buildingId;
    }
    if (isActive != null) {
      queryParameters['is_active'] = isActive;
    }

    final response = await _apiService.get(
      '/employees',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getEmployeesByBuildingId(
    int buildingId,
  ) async {
    final response = await _apiService.get('/buildings/$buildingId/employees');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>?> getEmployeeByUserId(String userId) async {
    try {
      final response = await _apiService.get('/employees/user/$userId');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return null; // 404 vs durumunda null dönelim
    }
  }

  Future<Map<String, dynamic>?> getEmployeeById(String employeeId) async {
    try {
      final response = await _apiService.get('/employees/$employeeId');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createEmployee(
    Map<String, dynamic> employeeData,
  ) async {
    final response = await _apiService.post('/employees/', data: employeeData);
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>?> updateEmployee(
    String employeeId,
    Map<String, dynamic> employeeData,
  ) async {
    final response = await _apiService.put(
      '/employees/$employeeId',
      data: employeeData,
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<bool> deleteEmployee(String employeeId) async {
    await _apiService.delete('/employees/$employeeId');
    return true;
  }

  Future<Map<String, dynamic>> createInvite(String employeeId) async {
    final response = await _apiService.post('/employees/$employeeId/invite');
    return Map<String, dynamic>.from(response.data);
  }
}

