import 'user_profile.dart';

class IncidentTimelineStep {
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;
  final String? actor;
  final UserRole actorRole;
  final String? action;
  final String? location;
  final String? note;

  IncidentTimelineStep({
    required this.title,
    required this.description,
    required this.timestamp,
    this.isCompleted = true,
    this.actor,
    this.actorRole = UserRole.student,
    this.action,
    this.location,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'isCompleted': isCompleted,
    'actor': actor,
    'actorRole': actorRole.name,
    'action': action,
    'location': location,
    'note': note,
  };

  factory IncidentTimelineStep.fromJson(Map<String, dynamic> json) => IncidentTimelineStep(
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    isCompleted: json['isCompleted'] as bool? ?? true,
    actor: json['actor'] as String?,
    actorRole: (json['actorRole'] as String?) == 'admin' ? UserRole.admin : UserRole.student,
    action: json['action'] as String?,
    location: json['location'] as String?,
    note: json['note'] as String?,
  );
}

class Incident {
  final String id;
  final String assetId;
  final String assetName;
  final DateTime timestamp;
  final String type;
  final String status; // 'Reported', 'Tracking', 'Found', 'Recovered'
  final String description;
  final double latitude;
  final double longitude;
  final List<IncidentTimelineStep> timeline;

  Incident({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.timestamp,
    required this.type,
    required this.status,
    required this.description,
    required this.latitude,
    required this.longitude,
    List<IncidentTimelineStep>? timeline,
  }) : timeline = timeline ?? [];

  Incident copyWith({
    String? id,
    String? assetId,
    String? assetName,
    DateTime? timestamp,
    String? type,
    String? status,
    String? description,
    double? latitude,
    double? longitude,
    List<IncidentTimelineStep>? timeline,
  }) {
    return Incident(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timeline: timeline ?? List.from(this.timeline),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'assetId': assetId,
    'assetName': assetName,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'status': status,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'timeline': timeline.map((s) => s.toJson()).toList(),
  };

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
    id: json['id'] as String? ?? '',
    assetId: json['assetId'] as String? ?? '',
    assetName: json['assetName'] as String? ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    type: json['type'] as String? ?? 'Lost Report',
    status: json['status'] as String? ?? 'Reported',
    description: json['description'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 20.2982,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 85.7434,
    timeline: (json['timeline'] as List<dynamic>?)
            ?.map((s) => IncidentTimelineStep.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
