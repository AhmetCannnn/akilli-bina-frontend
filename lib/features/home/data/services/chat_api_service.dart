import '../../../../core/services/api_service.dart';

class ChatApiService {
  final ApiService _apiService = ApiService();

  /// RAG tabanlı sohbet endpoint'ine soru gönderir
  Future<Map<String, dynamic>> sendMessage(String question) async {
    final response = await _apiService.post(
      '/api/v1/rag/chat',
      data: {
        'question': question,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }
}

