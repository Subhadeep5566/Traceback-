import 'user_profile.dart';

enum ReportType {
  lost,
  stolen,
  found;

  String get displayName {
    switch (this) {
      case ReportType.lost:
        return 'LOST';
      case ReportType.stolen:
        return 'STOLEN';
      case ReportType.found:
        return 'FOUND';
    }
  }
}

class RecoveryReport {
  final String reportId;
  final String reporterId;
  final UserRole reporterRole;
  final String reporterName;
  final String reporterContact;
  final String assetId;
  final String tracebackId;
  final ReportType reportType;
  final String location;
  final DateTime timestamp;
  final String description;
  final String? image;
  final String status; // 'Active', 'Investigating', 'Located', 'Resolved'

  const RecoveryReport({
    required this.reportId,
    required this.reporterId,
    required this.reporterRole,
    required this.reporterName,
    required this.reporterContact,
    required this.assetId,
    required this.tracebackId,
    required this.reportType,
    required this.location,
    required this.timestamp,
    required this.description,
    this.image,
    this.status = 'Active',
  });

  bool get isByAdmin => reporterRole == UserRole.admin;
  bool get isByStudent => reporterRole == UserRole.student;

  RecoveryReport copyWith({
    String? reportId,
    String? reporterId,
    UserRole? reporterRole,
    String? reporterName,
    String? reporterContact,
    String? assetId,
    String? tracebackId,
    ReportType? reportType,
    String? location,
    DateTime? timestamp,
    String? description,
    String? image,
    String? status,
  }) {
    return RecoveryReport(
      reportId: reportId ?? this.reportId,
      reporterId: reporterId ?? this.reporterId,
      reporterRole: reporterRole ?? this.reporterRole,
      reporterName: reporterName ?? this.reporterName,
      reporterContact: reporterContact ?? this.reporterContact,
      assetId: assetId ?? this.assetId,
      tracebackId: tracebackId ?? this.tracebackId,
      reportType: reportType ?? this.reportType,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      image: image ?? this.image,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'reporterId': reporterId,
      'reporterRole': reporterRole.name,
      'reporterName': reporterName,
      'reporterContact': reporterContact,
      'assetId': assetId,
      'tracebackId': tracebackId,
      'reportType': reportType.name,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'image': image,
      'status': status,
    };
  }

  factory RecoveryReport.fromJson(Map<String, dynamic> json) {
    return RecoveryReport(
      reportId: json['reportId'] as String? ?? 'REP-${DateTime.now().millisecondsSinceEpoch}',
      reporterId: json['reporterId'] as String? ?? 'reporter_unknown',
      reporterRole: (json['reporterRole'] as String?) == 'admin' ? UserRole.admin : UserRole.student,
      reporterName: json['reporterName'] as String? ?? 'Campus Member',
      reporterContact: json['reporterContact'] as String? ?? '',
      assetId: json['assetId'] as String? ?? '',
      tracebackId: json['tracebackId'] as String? ?? '',
      reportType: _parseReportType(json['reportType'] as String?),
      location: json['location'] as String? ?? 'BGU Campus',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      description: json['description'] as String? ?? '',
      image: json['image'] as String?,
      status: json['status'] as String? ?? 'Active',
    );
  }

  static ReportType _parseReportType(String? str) {
    switch (str?.toLowerCase()) {
      case 'lost':
        return ReportType.lost;
      case 'stolen':
        return ReportType.stolen;
      case 'found':
      default:
        return ReportType.found;
    }
  }
}
