// lib/models/report.dart
class Report {
  final int id;
  final int reporterId;
  final String reportType; // e.g. "post", "user", "agent"
  final int reportedId;
  final String? reason;
  final String? details;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Report({
    required this.id,
    required this.reporterId,
    required this.reportType,
    required this.reportedId,
    this.reason,
    this.details,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as int,
      reporterId: json['reporter_id'] as int,
      reportType: json['report_type'] ?? '',
      reportedId: json['reported_id'] as int,
      reason: json['reason'],
      details: json['details'],
      status: json['status'] ?? 'open',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'report_type': reportType,
      'reported_id': reportedId,
      'reason': reason,
      'details': details,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
