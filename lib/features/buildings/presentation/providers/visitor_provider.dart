import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/services/visitor_api_service.dart';
import '../utils/building_helpers.dart';

part 'visitor_provider.g.dart';

@riverpod
class VisitorController extends _$VisitorController {
  final VisitorApiService _apiService = VisitorApiService();

  @override
  Future<List<Map<String, dynamic>>> build() async {
    return [];
  }

  /// Belirli bir binanın ziyaretçilerini getirir
  Future<void> loadVisitorsForBuilding(int buildingId, {DateTime? visitDate}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final visitors = await _apiService.getVisitorsByBuilding(buildingId, visitDate: visitDate);
      return visitors;
    });
  }

  /// Günlük ziyaretçi özetini getirir
  Future<Map<String, dynamic>> getDailySummary(int buildingId, DateTime visitDate) async {
    return await _apiService.getDailyVisitorSummary(buildingId, visitDate);
  }

  /// Yeni ziyaretçi oluşturur
  Future<bool> createVisitor(Map<String, dynamic> visitorData) async {
    try {
      final visitor = await _apiService.createVisitor(visitorData);
      if (visitor != null) {
        // Mevcut listeye ekle
        final currentVisitors = state.valueOrNull ?? [];
        state = AsyncValue.data([visitor, ...currentVisitors]);
        return true;
      }
      return false;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Ziyaretçi çıkış işlemi yapar
  Future<bool> checkoutVisitor(String visitorId, DateTime exitTime, int buildingId, {DateTime? visitDate}) async {
    try {
      final success = await _apiService.checkoutVisitor(visitorId, exitTime);
      if (success) {
        // Listeyi API'den yeniden yükle
        await loadVisitorsForBuilding(buildingId, visitDate: visitDate);
      }
      return success;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Ziyaretçi günceller
  Future<bool> updateVisitor(String visitorId, Map<String, dynamic> updateData) async {
    try {
      final visitor = await _apiService.updateVisitor(visitorId, updateData);
      if (visitor != null) {
        // Listeyi güncelle
        final currentVisitors = state.valueOrNull ?? [];
        final updatedVisitors = currentVisitors.map((v) {
          if (v['id'] == visitorId) {
            return visitor;
          }
          return v;
        }).toList();
        state = AsyncValue.data(updatedVisitors);
        return true;
      }
      return false;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Ziyaretçi siler
  Future<bool> deleteVisitor(String visitorId) async {
    try {
      final success = await _apiService.deleteVisitor(visitorId);
      if (success) {
        // Listeden kaldır
        final currentVisitors = state.valueOrNull ?? [];
        final updatedVisitors = currentVisitors.where((v) => v['id'] != visitorId).toList();
        state = AsyncValue.data(updatedVisitors);
      }
      return success;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

}

/// Belirli bir binanın günlük ziyaretçi özeti için provider
@riverpod
Future<Map<String, dynamic>> dailyVisitorSummary(
  DailyVisitorSummaryRef ref,
  int buildingId,
  DateTime visitDate,
) async {
  final apiService = VisitorApiService();
  return await apiService.getDailyVisitorSummary(buildingId, visitDate);
}

/// Ziyaretçi amacı seçenekleri için provider
@riverpod
List<String> visitPurposes(VisitPurposesRef ref) {
  return getVisitPurposes();
}
