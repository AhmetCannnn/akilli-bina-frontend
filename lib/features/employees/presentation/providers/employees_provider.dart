import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:belediye_otomasyon/features/employees/data/services/employee_api_service.dart';

final employeesProvider = AutoDisposeAsyncNotifierProvider<
    EmployeesNotifier, List<Map<String, dynamic>>>(
  EmployeesNotifier.new,
);

class EmployeesNotifier
    extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  final EmployeeApiService _apiService = EmployeeApiService();

  String? _search;
  int? _buildingId;
  bool? _isActive;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    return _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() {
    return _apiService.getEmployees(
      search: _search,
      buildingId: _buildingId,
      isActive: _isActive,
    );
  }

  Future<void> applyFilters({
    String? search,
    int? buildingId,
    bool? isActive,
  }) async {
    _search = search;
    _buildingId = buildingId;
    _isActive = isActive;

    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

