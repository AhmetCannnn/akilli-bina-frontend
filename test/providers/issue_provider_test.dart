import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake controller that does NOT touch real ApiService or dotenv.
class FakeIssueController
    extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  FakeIssueController(this._initial);

  final List<Map<String, dynamic>> _initial;
  late List<Map<String, dynamic>> _items;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    _items = List<Map<String, dynamic>>.from(_initial);
    return _items;
  }

  Future<void> createIssue(Map<String, dynamic> issueData) async {
    _items = [..._items, issueData];
    state = AsyncData(_items);
  }

  Future<void> updateIssue(String id, Map<String, dynamic> issueData) async {
    _items = _items
        .map((e) => e['id'].toString() == id ? {...e, ...issueData} : e)
        .toList();
    state = AsyncData(_items);
  }

  Future<void> deleteIssue(String id) async {
    _items = _items.where((e) => e['id'].toString() != id).toList();
    state = AsyncData(_items);
  }
}

void main() {
  final initialIssues = [
    {'id': '1', 'title': 'A', 'status': 'pending'},
    {'id': '2', 'title': 'B', 'status': 'in_progress'},
  ];

  final fakeIssueProvider =
      AutoDisposeAsyncNotifierProvider<FakeIssueController, List<Map<String, dynamic>>>(
    () => FakeIssueController(initialIssues),
  );

  test('IssueController build returns initial issues', () async {
    final container = ProviderContainer();

    final issues = await container.read(fakeIssueProvider.future);

    expect(issues.length, initialIssues.length);
    expect(issues.first['title'], 'A');
  });

  test('createIssue adds a new issue and updates state', () async {
    final container = ProviderContainer();
    await container.read(fakeIssueProvider.future);
    final notifier = container.read(fakeIssueProvider.notifier);

    await notifier.createIssue({'id': '3', 'title': 'C'});
    final state = container.read(fakeIssueProvider);

    expect(state.asData?.value.length, 3);
    expect(state.asData?.value.last['title'], 'C');
  });

  test('updateIssue updates matching issue', () async {
    final container = ProviderContainer();
    await container.read(fakeIssueProvider.future);
    final notifier = container.read(fakeIssueProvider.notifier);

    await notifier.updateIssue('2', {'status': 'resolved'});
    final state = container.read(fakeIssueProvider);
    final updated =
        state.asData?.value.firstWhere((e) => e['id'].toString() == '2');

    expect(updated?['status'], 'resolved');
  });

  test('deleteIssue removes matching issue', () async {
    final container = ProviderContainer();
    await container.read(fakeIssueProvider.future);
    final notifier = container.read(fakeIssueProvider.notifier);

    await notifier.deleteIssue('1');
    final state = container.read(fakeIssueProvider);

    expect(state.asData?.value.length, 1);
    expect(state.asData?.value.first['id'], '2');
  });
}


