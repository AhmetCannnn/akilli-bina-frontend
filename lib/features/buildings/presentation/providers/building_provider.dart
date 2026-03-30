import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/services/building_api_service.dart';

part 'building_provider.g.dart';

@riverpod
class BuildingController extends _$BuildingController {
  final BuildingApiService _apiService = BuildingApiService();
  
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final buildings = await _apiService.getBuildings();
    return buildings;
  }
  
  // Refresh buildings
  Future<void> refreshBuildings() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _apiService.getBuildings());
  }
  
  // Create new building
  Future<void> createBuilding(Map<String, dynamic> buildingData) async {
    try {
      await _apiService.createBuilding(buildingData);
      await refreshBuildings(); // Refresh the list
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  // Update building
  Future<void> updateBuilding(int id, Map<String, dynamic> buildingData) async {
    try {
      await _apiService.updateBuilding(id, buildingData);
      await refreshBuildings(); // Refresh the list
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  // Delete building
  Future<void> deleteBuilding(int id) async {
    // Hata durumunda exception'ı yukarı fırlatıyoruz; UI tarafı (dialog) bunu ele alacak.
    await _apiService.deleteBuilding(id);
    await refreshBuildings(); // Silme başarılıysa listeyi yenile
  }
}

// Single building detail provider
@riverpod
class BuildingDetailController extends _$BuildingDetailController {
  final BuildingApiService _apiService = BuildingApiService();
  
  @override
  Future<Map<String, dynamic>> build(int buildingId) async {
    final building = await _apiService.getBuilding(buildingId);
    return building;
  }
  
  // Refresh single building
  Future<void> refreshBuilding(int buildingId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _apiService.getBuilding(buildingId));
  }
  
  // Update building and directly update state (optimized - no API reload needed)
  Future<void> updateBuilding(int buildingId, Map<String, dynamic> buildingData) async {
    try {
      final updatedBuilding = await _apiService.updateBuilding(buildingId, buildingData);
      
      // Direkt state'i güncelle - API'ye tekrar istek atmaya gerek yok
      final currentState = state.valueOrNull;
      if (currentState != null) {
        state = AsyncValue.data(updatedBuilding);
      } else {
        // Eğer state yoksa refresh et
        await refreshBuilding(buildingId);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
