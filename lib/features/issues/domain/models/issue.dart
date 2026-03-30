import 'dart:ui';

class Issue {
  Issue({
    required this.id,
    this.buildingId,
    this.buildingName,
    this.buildingAddress,
    required this.title,
    required this.description,
    required this.location,
    this.issuePlace,
    required this.category,
    required this.priority,
    required this.status,
    required this.reportDate,
    this.assignedTo,
    this.reporterName,
    this.reporterPhone,
    this.reporterEmail,
    this.interventionNote,
    this.interventionAt,
    this.interventionAssignee,
    this.estimatedCost,
    this.actualCost,
    this.resolvedAt,
  });

  final String id;
  final int? buildingId;
  final String? buildingName;
  final String? buildingAddress;
  final String title;
  final String description;
  final String location;
  final String? issuePlace;
  final String category;
  final IssuePriority priority;
  IssueStatus status;
  final DateTime reportDate;
  String? assignedTo;
  final String? reporterName;
  final String? reporterPhone;
  final String? reporterEmail;
  String? interventionNote;
  DateTime? interventionAt;
  String? interventionAssignee;
  double? estimatedCost;
  double? actualCost;
  DateTime? resolvedAt;

  /// JSON'dan Issue oluşturur
  factory Issue.fromJson(
    Map<String, dynamic> json, {
    Map<int, String>? buildingNameMap,
    Map<int, String>? buildingAddressMap,
  }) {
    int? parseBuildingId(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    final buildingId = parseBuildingId(json['building_id']);
    
    return Issue(
      id: (json['id'] ?? '').toString(),
      buildingId: buildingId,
      buildingName: buildingId != null ? (buildingNameMap?[buildingId]) : null,
      buildingAddress: buildingId != null ? (buildingAddressMap?[buildingId]) : null,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? '-').toString(),
      issuePlace: (json['issue_place'] ?? json['issuePlace'] ?? json['location'])?.toString(),
      category: (json['category'] ?? '-').toString(),
      priority: IssuePriorityX.fromApiValue(json['priority']?.toString() ?? 'medium'),
      status: IssueStatusX.fromApiValue(json['status']?.toString() ?? 'pending'),
      reportDate: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      assignedTo: json['assigned_to']?.toString(),
      reporterName: json['reporter_name']?.toString(),
      reporterPhone: json['reporter_phone']?.toString(),
      reporterEmail: json['reporter_email']?.toString(),
      interventionNote: json['intervention_note']?.toString(),
      interventionAt: json['intervention_at'] != null
          ? DateTime.tryParse(json['intervention_at'].toString())
          : null,
      interventionAssignee: json['intervention_assignee']?.toString(),
      estimatedCost: json['estimated_cost'] != null
          ? double.tryParse(json['estimated_cost'].toString())
          : null,
      actualCost: json['actual_cost'] != null
          ? double.tryParse(json['actual_cost'].toString())
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())
          : null,
    );
  }

  /// Issue'yu JSON'a dönüştürür
  Map<String, dynamic> toJson() {
    return {
      if (buildingId != null) 'building_id': buildingId,
      'title': title,
      'description': description,
      if (location.isNotEmpty) 'location': location,
      if (issuePlace != null) 'issue_place': issuePlace,
      'category': category,
      'priority': priority.apiValue,
      'status': status.apiValue,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (reporterName != null) 'reporter_name': reporterName,
      if (reporterPhone != null) 'reporter_phone': reporterPhone,
      if (reporterEmail != null) 'reporter_email': reporterEmail,
      if (interventionNote != null) 'intervention_note': interventionNote,
      if (interventionAt != null) 'intervention_at': interventionAt!.toIso8601String(),
      if (interventionAssignee != null) 'intervention_assignee': interventionAssignee,
      if (estimatedCost != null) 'estimated_cost': estimatedCost,
      if (actualCost != null) 'actual_cost': actualCost,
      if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
    };
  }
}

enum IssuePriority { critical, high, medium, low }

enum IssueStatus { pending, inProgress, resolved }

extension IssuePriorityX on IssuePriority {
  String get displayName => switch (this) {
        IssuePriority.critical => 'Kritik',
        IssuePriority.high => 'Yüksek',
        IssuePriority.medium => 'Orta',
        IssuePriority.low => 'Düşük',
      };

  Color get color => switch (this) {
        IssuePriority.critical => const Color(0xFFC42B1C),
        IssuePriority.high => const Color(0xFFE81123),
        IssuePriority.medium => const Color(0xFFF7630C),
        IssuePriority.low => const Color(0xFF107C10),
      };

  /// API'den gelen string değerini IssuePriority'a dönüştürür
  static IssuePriority fromApiValue(String? value) {
    return switch (value?.toLowerCase()) {
      'critical' => IssuePriority.critical,
      'high' => IssuePriority.high,
      'low' => IssuePriority.low,
      'medium' => IssuePriority.medium,
      _ => IssuePriority.medium,
    };
  }

  /// Display name'den API değerine dönüştürür
  static String displayNameToApiValue(String label) {
    return switch (label) {
      'Kritik' => 'critical',
      'Yüksek' => 'high',
      'Düşük' => 'low',
      'Orta' => 'medium',
      _ => 'medium',
    };
  }

  /// API'ye gönderilecek string değerini döndürür
  String get apiValue => switch (this) {
        IssuePriority.critical => 'critical',
        IssuePriority.high => 'high',
        IssuePriority.medium => 'medium',
        IssuePriority.low => 'low',
      };
}

extension IssueStatusX on IssueStatus {
  String get displayName => switch (this) {
        IssueStatus.pending => 'Arıza Devam Ediyor',
        IssueStatus.inProgress => 'Üzerine Çalışılıyor',
        IssueStatus.resolved => 'Çözüldü',
      };

  Color get color => switch (this) {
        IssueStatus.pending => const Color(0xFFF7630C),
        IssueStatus.inProgress => const Color(0xFF0078D4),
        IssueStatus.resolved => const Color(0xFF107C10),
      };

  /// API'den gelen string değerini IssueStatus'a dönüştürür
  static IssueStatus fromApiValue(String? value) {
    return switch (value?.toLowerCase()) {
      'in_progress' => IssueStatus.inProgress,
      'resolved' => IssueStatus.resolved,
      'pending' => IssueStatus.pending,
      _ => IssueStatus.pending,
    };
  }

  /// API'ye gönderilecek string değerini döndürür
  String get apiValue => switch (this) {
        IssueStatus.pending => 'pending',
        IssueStatus.inProgress => 'in_progress',
        IssueStatus.resolved => 'resolved',
      };
}

