import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/maintenance_api_service.dart';

part 'maintenance_provider.g.dart';

/// Tüm bakım kayıtları controller'ı
@riverpod
class MaintenanceController extends _$MaintenanceController {
  final MaintenanceApiService _apiService = MaintenanceApiService();

  @override
  Future<List<Map<String, dynamic>>> build() => _apiService.getAllMaintenance();

  /// Bakım kayıtlarını yeniler
  Future<void> refreshMaintenance() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _apiService.getAllMaintenance());
  }

  /// Helper: Mutation işlemlerini handle eder (create, update, delete)
  Future<void> _handleMutation(Future<void> Function() mutation) async {
    try {
      await mutation();
      await refreshMaintenance();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Yeni bakım kaydı oluşturur
  Future<void> createMaintenance(Map<String, dynamic> maintenanceData) =>
      _handleMutation(() async {
        await _apiService.createMaintenance(maintenanceData);
      });

  /// Bakım kaydını günceller
  Future<void> updateMaintenance(
    String maintenanceId,
    Map<String, dynamic> updateData,
  ) =>
      _handleMutation(() async {
        await _apiService.updateMaintenance(maintenanceId, updateData);
      });

  /// Bakım kaydını siler
  Future<void> deleteMaintenance(String maintenanceId) =>
      _handleMutation(() async {
        await _apiService.deleteMaintenance(maintenanceId);
      });

  /// Bakım durumunu günceller
  Future<void> updateMaintenanceStatus(String maintenanceId, String status) =>
      _handleMutation(() async {
        await _apiService.updateMaintenanceStatus(maintenanceId, status);
      });
}

/// Tüm bakım kayıtları provider'ı (geriye dönük uyumluluk için)
final allMaintenanceProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(maintenanceControllerProvider.future);
});

/// Bakım kayıtları provider'ı (bina bazında)
final maintenanceByBuildingProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, buildingId) {
  return MaintenanceApiService().getMaintenanceByBuilding(buildingId);
});

/// Bakım özeti provider'ı
final maintenanceSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, buildingId) async {
  final summary =
      await MaintenanceApiService().getMaintenanceSummary(buildingId);
  return summary ?? {};
});

/// Bakım türleri provider'ı
final maintenanceTypesProvider = Provider<List<String>>((ref) {
  return ['rutin', 'acil', 'planlı'];
});

/// Bakım durumları provider'ı
final maintenanceStatusesProvider = Provider<List<String>>((ref) {
  return ['scheduled', 'in_progress', 'completed', 'cancelled'];
});
