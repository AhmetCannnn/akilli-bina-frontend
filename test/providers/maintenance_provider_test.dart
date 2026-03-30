import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake controller that does NOT touch real ApiService or dotenv.
class FakeMaintenanceController
    extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  FakeMaintenanceController(this._initial);

  final List<Map<String, dynamic>> _initial;
  late List<Map<String, dynamic>> _items;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    _items = List<Map<String, dynamic>>.from(_initial);
    return _items;
  }

  Future<void> createMaintenance(Map<String, dynamic> maintenanceData) async {
    _items = [..._items, maintenanceData];
    state = AsyncData(_items);
  }

  Future<void> updateMaintenance(
    String maintenanceId,
    Map<String, dynamic> updateData,
  ) async {
    _items = _items
        .map((e) => e['id'].toString() == maintenanceId ? {...e, ...updateData} : e)
        .toList();
    state = AsyncData(_items);
  }

  Future<void> deleteMaintenance(String maintenanceId) async {
    _items = _items.where((e) => e['id'].toString() != maintenanceId).toList();
    state = AsyncData(_items);
  }

  Future<void> updateMaintenanceStatus(String maintenanceId, String status) async {
    await updateMaintenance(maintenanceId, {'status': status});
  }
}

void main() {
  final initialMaintenance = [
    {'id': 'm1', 'title': 'Bakım A', 'status': 'pending'},
    {'id': 'm2', 'title': 'Bakım B', 'status': 'scheduled'},
  ];

  final fakeMaintenanceProvider = AutoDisposeAsyncNotifierProvider<
      FakeMaintenanceController, List<Map<String, dynamic>>>(
    () => FakeMaintenanceController(initialMaintenance),
  );

  test('MaintenanceController build returns initial list', () async {
    final container = ProviderContainer();

    final items = await container.read(fakeMaintenanceProvider.future);

    expect(items.length, initialMaintenance.length);
    expect(items.first['title'], 'Bakım A');
  });

  test('createMaintenance adds item and updates state', () async {
    final container = ProviderContainer();
    await container.read(fakeMaintenanceProvider.future);
    final notifier = container.read(fakeMaintenanceProvider.notifier);

    await notifier.createMaintenance({'id': 'm3', 'title': 'Bakım C'});
    final state = container.read(fakeMaintenanceProvider);

    expect(state.asData?.value.length, 3);
    expect(state.asData?.value.last['title'], 'Bakım C');
  });

  test('updateMaintenance updates matching item', () async {
    final container = ProviderContainer();
    await container.read(fakeMaintenanceProvider.future);
    final notifier = container.read(fakeMaintenanceProvider.notifier);

    await notifier.updateMaintenance('m2', {'status': 'completed'});
    final state = container.read(fakeMaintenanceProvider);
    final updated =
        state.asData?.value.firstWhere((e) => e['id'].toString() == 'm2');

    expect(updated?['status'], 'completed');
  });

  test('deleteMaintenance removes matching item', () async {
    final container = ProviderContainer();
    await container.read(fakeMaintenanceProvider.future);
    final notifier = container.read(fakeMaintenanceProvider.notifier);

    await notifier.deleteMaintenance('m1');
    final state = container.read(fakeMaintenanceProvider);

    expect(state.asData?.value.length, 1);
    expect(state.asData?.value.first['id'], 'm2');
  });

  test('updateMaintenanceStatus delegates to updateMaintenance', () async {
    final container = ProviderContainer();
    await container.read(fakeMaintenanceProvider.future);
    final notifier = container.read(fakeMaintenanceProvider.notifier);

    await notifier.updateMaintenanceStatus('m1', 'scheduled');
    final state = container.read(fakeMaintenanceProvider);
    final updated =
        state.asData?.value.firstWhere((e) => e['id'].toString() == 'm1');

    expect(updated?['status'], 'scheduled');
  });
}


