import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/services/issue_api_service.dart';

part 'issue_provider.g.dart';

@riverpod
class IssueController extends _$IssueController {
  final IssueApiService _apiService = IssueApiService();
  
  @override
  Future<List<Map<String, dynamic>>> build() => _apiService.getIssues();
  
  // Refresh issues
  Future<void> refreshIssues() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _apiService.getIssues());
  }
  
  // Helper: Mutation işlemlerini handle eder (create, update, delete)
  Future<void> _handleMutation(Future<void> Function() mutation) async {
    try {
      await mutation();
      await refreshIssues();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  // Create new issue
  Future<void> createIssue(Map<String, dynamic> issueData) =>
      _handleMutation(() => _apiService.createIssue(issueData));
  
  // Update issue
  Future<void> updateIssue(String id, Map<String, dynamic> issueData) =>
      _handleMutation(() => _apiService.updateIssue(id, issueData));
  
  // Delete issue
  Future<void> deleteIssue(String id) =>
      _handleMutation(() => _apiService.deleteIssue(id));
}

