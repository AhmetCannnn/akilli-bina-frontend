import '../../../../core/services/api_service.dart';

class BuildingApiService {
  final ApiService _apiService = ApiService();
  
  // Get all buildings
  Future<List<Map<String, dynamic>>> getBuildings({
    String? city,
    String? district,
    String? buildingType,
    String? status,
    int limit = 10,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    
    if (city != null) queryParams['city'] = city;
    if (district != null) queryParams['district'] = district;
    if (buildingType != null) queryParams['building_type'] = buildingType;
    if (status != null) queryParams['status'] = status;
    
    final response = await _apiService.get('/buildings/', queryParameters: queryParams);
    return List<Map<String, dynamic>>.from(response.data);
  }
  
  // Get building by ID
  Future<Map<String, dynamic>> getBuilding(int id) async {
    final response = await _apiService.get('/buildings/$id');
    return Map<String, dynamic>.from(response.data);
  }
  
  // Create new building
  Future<Map<String, dynamic>> createBuilding(Map<String, dynamic> buildingData) async {
    final response = await _apiService.post('/buildings/', data: buildingData);
    return Map<String, dynamic>.from(response.data);
  }
  
  // Update building
  Future<Map<String, dynamic>> updateBuilding(int id, Map<String, dynamic> buildingData) async {
    final response = await _apiService.put('/buildings/$id', data: buildingData);
    return Map<String, dynamic>.from(response.data);
  }
  
  // Delete building
  Future<void> deleteBuilding(int id) async {
    await _apiService.delete('/buildings/$id');
  }
}
