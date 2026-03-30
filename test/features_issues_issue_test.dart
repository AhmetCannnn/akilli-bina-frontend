import 'package:belediye_otomasyon/features/issues/domain/models/issue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue.fromJson', () {
    test('parses basic fields and enums correctly', () {
      final json = {
        'id': '123',
        'building_id': 10,
        'title': 'Test arıza',
        'description': 'Açıklama',
        'location': 'Kat 1',
        'category': 'Elektrik',
        'priority': 'high',
        'status': 'in_progress',
        'created_at': '2024-01-01T12:00:00Z',
      };

      final issue = Issue.fromJson(json);

      expect(issue.id, '123');
      expect(issue.buildingId, 10);
      expect(issue.title, 'Test arıza');
      expect(issue.description, 'Açıklama');
      expect(issue.location, 'Kat 1');
      expect(issue.category, 'Elektrik');
      expect(issue.priority, IssuePriority.high);
      expect(issue.status, IssueStatus.inProgress);
      expect(issue.reportDate.year, 2024);
    });

    test('uses buildingNameMap and buildingAddressMap when provided', () {
      final json = {
        'id': '1',
        'building_id': 5,
        'title': 'Test',
        'description': '',
        'location': '',
        'category': '',
        'priority': 'medium',
        'status': 'pending',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final issue = Issue.fromJson(
        json,
        buildingNameMap: {5: 'Bina A'},
        buildingAddressMap: {5: 'Adres A'},
      );

      expect(issue.buildingName, 'Bina A');
      expect(issue.buildingAddress, 'Adres A');
    });
  });

  group('IssuePriorityX', () {
    test('displayNameToApiValue maps correctly', () {
      expect(IssuePriorityX.displayNameToApiValue('Kritik'), 'critical');
      expect(IssuePriorityX.displayNameToApiValue('Yüksek'), 'high');
      expect(IssuePriorityX.displayNameToApiValue('Orta'), 'medium');
      expect(IssuePriorityX.displayNameToApiValue('Düşük'), 'low');
    });

    test('fromApiValue parses correctly', () {
      expect(IssuePriorityX.fromApiValue('critical'), IssuePriority.critical);
      expect(IssuePriorityX.fromApiValue('high'), IssuePriority.high);
      expect(IssuePriorityX.fromApiValue('medium'), IssuePriority.medium);
      expect(IssuePriorityX.fromApiValue('low'), IssuePriority.low);
    });
  });

  group('IssueStatusX', () {
    test('fromApiValue parses correctly', () {
      expect(IssueStatusX.fromApiValue('pending'), IssueStatus.pending);
      expect(IssueStatusX.fromApiValue('in_progress'), IssueStatus.inProgress);
      expect(IssueStatusX.fromApiValue('resolved'), IssueStatus.resolved);
    });

    test('apiValue returns correct strings', () {
      expect(IssueStatus.pending.apiValue, 'pending');
      expect(IssueStatus.inProgress.apiValue, 'in_progress');
      expect(IssueStatus.resolved.apiValue, 'resolved');
    });
  });
}


