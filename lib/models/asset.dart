import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

enum AssetCategory {
  vehicle,
  electronics,
  belonging,
  phone;

  String get displayName {
    switch (this) {
      case AssetCategory.vehicle:
        return 'Vehicle / Bike';
      case AssetCategory.electronics:
        return 'Electronics / Laptop';
      case AssetCategory.belonging:
        return 'Personal Belonging';
      case AssetCategory.phone:
        return 'Smartphone';
    }
  }

  IconData get icon {
    switch (this) {
      case AssetCategory.vehicle:
        return Icons.two_wheeler_rounded;
      case AssetCategory.electronics:
        return Icons.laptop_mac_rounded;
      case AssetCategory.belonging:
        return Icons.backpack_rounded;
      case AssetCategory.phone:
        return Icons.smartphone_rounded;
    }
  }

  String get idPrefix {
    switch (this) {
      case AssetCategory.vehicle:
        return 'BIKE';
      case AssetCategory.electronics:
        return 'LAPTOP';
      case AssetCategory.belonging:
        return 'ITEM';
      case AssetCategory.phone:
        return 'PHONE';
    }
  }
}

enum AssetStatus {
  safe,
  stolen,
  recovered,
  found;

  String get displayName {
    switch (this) {
      case AssetStatus.safe:
        return 'Secure';
      case AssetStatus.stolen:
        return 'Lost';
      case AssetStatus.recovered:
        return 'Recovered';
      case AssetStatus.found:
        return 'Found';
    }
  }

  Color get color {
    switch (this) {
      case AssetStatus.safe:
        return const Color(0xFF10B981); // Emerald
      case AssetStatus.stolen:
        return const Color(0xFFEF4444); // Crimson
      case AssetStatus.recovered:
        return const Color(0xFF0EA5E9); // Sky / Cyan
      case AssetStatus.found:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  bool get isAlert => this == AssetStatus.stolen || this == AssetStatus.found;
  bool get isLost => this == AssetStatus.stolen;
  bool get isSecure => this == AssetStatus.safe;
  bool get isSafe => this == AssetStatus.safe;
  bool get isFound => this == AssetStatus.found;
  bool get isRecovered => this == AssetStatus.recovered;
}

@immutable
class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
  };

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
  );
}

class Asset {
  final String id;
  final String tracebackId;
  final String ownerId;
  final String name;
  final AssetCategory category;
  final String brand;
  final String model;
  final String color;
  final String description;
  final String? image;
  AssetStatus status;
  bool trackingEnabled;
  final DateTime createdAt;
  DateTime updatedAt;
  double latitude;
  double longitude;
  double locationAccuracy;
  String address;
  DateTime lastPing;
  final List<LocationPoint> locationHistory;

  // Compatibility alias getters
  String get identifier => tracebackId;
  double get lastKnownLatitude => latitude;
  double get lastKnownLongitude => longitude;
  DateTime get lastLocationUpdatedAt => lastPing;
  LatLng get latLng => LatLng(latitude, longitude);

  bool get isLost => status.isLost;
  bool get isSafe => status.isSafe;
  bool get isSecure => status.isSecure;
  bool get isFound => status.isFound;
  bool get isRecovered => status.isRecovered;

  TrackingState get trackingState => LocationService.computeTrackingState(
    trackingEnabled: trackingEnabled,
    lastLocationUpdatedAt: lastPing,
  );

  Asset({
    required this.id,
    required this.tracebackId,
    this.ownerId = 'default_student',
    required this.name,
    required this.category,
    this.brand = '',
    this.model = '',
    this.color = '',
    this.description = '',
    this.image,
    required this.status,
    this.trackingEnabled = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.latitude,
    required this.longitude,
    this.locationAccuracy = 8.0,
    required this.address,
    required this.lastPing,
    List<LocationPoint>? locationHistory,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        locationHistory = locationHistory ?? [];

  Asset copyWith({
    String? id,
    String? tracebackId,
    String? ownerId,
    String? name,
    AssetCategory? category,
    String? brand,
    String? model,
    String? color,
    String? description,
    String? image,
    AssetStatus? status,
    bool? trackingEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    String? address,
    DateTime? lastPing,
    List<LocationPoint>? locationHistory,
    String? identifier, // backward compat
  }) {
    return Asset(
      id: id ?? this.id,
      tracebackId: tracebackId ?? identifier ?? this.tracebackId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      description: description ?? this.description,
      image: image ?? this.image,
      status: status ?? this.status,
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
      address: address ?? this.address,
      lastPing: lastPing ?? this.lastPing,
      locationHistory: locationHistory ?? List.from(this.locationHistory),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tracebackId': tracebackId,
    'ownerId': ownerId,
    'name': name,
    'category': category.index,
    'brand': brand,
    'model': model,
    'color': color,
    'description': description,
    'image': image,
    'status': status.index,
    'trackingEnabled': trackingEnabled,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'locationAccuracy': locationAccuracy,
    'address': address,
    'lastPing': lastPing.toIso8601String(),
    'locationHistory': locationHistory.map((p) => p.toJson()).toList(),
  };

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String? ?? 'AST-UNKNOWN',
      tracebackId: json['tracebackId'] as String? ?? json['identifier'] as String? ?? 'TB-000',
      ownerId: json['ownerId'] as String? ?? 'default_student',
      name: json['name'] as String? ?? 'Unknown Item',
      category: AssetCategory.values[(json['category'] as int?)?.clamp(0, AssetCategory.values.length - 1) ?? 0],
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      color: json['color'] as String? ?? '',
      description: json['description'] as String? ?? '',
      image: json['image'] as String?,
      status: AssetStatus.values[(json['status'] as int?)?.clamp(0, AssetStatus.values.length - 1) ?? 0],
      trackingEnabled: json['trackingEnabled'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 20.2982,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 85.7434,
      locationAccuracy: (json['locationAccuracy'] as num?)?.toDouble() ?? 8.0,
      address: json['address'] as String? ?? 'BGU Campus, Bhubaneswar',
      lastPing: DateTime.tryParse(json['lastPing'] ?? '') ?? DateTime.now(),
      locationHistory: (json['locationHistory'] as List<dynamic>?)
              ?.map((p) => LocationPoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
