import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/api_error.dart';

class IssueApiService {
  final ApiService _apiService = ApiService();
  
  // Get all issues
  Future<List<Map<String, dynamic>>> getIssues({
    int? buildingId,
    String? status,
    String? priority,
    String? category,
    int limit = 10,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    
    if (buildingId != null) queryParams['building_id'] = buildingId;
    if (status != null) queryParams['status'] = status;
    if (priority != null) queryParams['priority'] = priority;
    if (category != null) queryParams['category'] = category;
    
    try {
      final response = await _apiService.get('/issues/', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
  
  // Get issue by ID
  Future<Map<String, dynamic>> getIssue(String id) async {
    try {
      final response = await _apiService.get('/issues/$id');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
  
  // Create new issue
  Future<Map<String, dynamic>> createIssue(Map<String, dynamic> issueData) async {
    try {
      final response = await _apiService.post('/issues/', data: issueData);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
  
  // Update issue
  Future<Map<String, dynamic>> updateIssue(String id, Map<String, dynamic> issueData) async {
    try {
      final response = await _apiService.put('/issues/$id', data: issueData);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
  
  // Delete issue
  Future<void> deleteIssue(String id) async {
    try {
      await _apiService.delete('/issues/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

