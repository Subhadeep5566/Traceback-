import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

enum AssetCategory {
  vehicle,
  electronics,
  belonging,
  phone,
  laptop,
  bike,
  car,
  wallet,
  bag,
  watch,
  camera,
  documents,
  jewellery,
  other;

  String get displayName {
    switch (this) {
      case AssetCategory.vehicle:
        return 'Vehicle';
      case AssetCategory.electronics:
        return 'Electronics';
      case AssetCategory.belonging:
        return 'Personal Belonging';
      case AssetCategory.phone:
        return 'Smartphone / Phone';
      case AssetCategory.laptop:
        return 'Laptop / Tablet';
      case AssetCategory.bike:
        return 'Bike / Motorcycle';
      case AssetCategory.car:
        return 'Car / Automobile';
      case AssetCategory.wallet:
        return 'Wallet / Purse';
      case AssetCategory.bag:
        return 'Bag / Backpack';
      case AssetCategory.watch:
        return 'Watch / Wearable';
      case AssetCategory.camera:
        return 'Camera / Lens';
      case AssetCategory.documents:
        return 'Documents / ID';
      case AssetCategory.jewellery:
        return 'Jewellery / Valuables';
      case AssetCategory.other:
        return 'Other Item';
    }
  }

  IconData get icon {
    switch (this) {
      case AssetCategory.vehicle:
      case AssetCategory.bike:
        return Icons.two_wheeler_rounded;
      case AssetCategory.car:
        return Icons.directions_car_rounded;
      case AssetCategory.electronics:
      case AssetCategory.laptop:
        return Icons.laptop_mac_rounded;
      case AssetCategory.belonging:
      case AssetCategory.bag:
        return Icons.backpack_rounded;
      case AssetCategory.phone:
        return Icons.smartphone_rounded;
      case AssetCategory.wallet:
        return Icons.account_balance_wallet_rounded;
      case AssetCategory.watch:
        return Icons.watch_rounded;
      case AssetCategory.camera:
        return Icons.camera_alt_rounded;
      case AssetCategory.documents:
        return Icons.description_rounded;
      case AssetCategory.jewellery:
        return Icons.diamond_rounded;
      case AssetCategory.other:
        return Icons.category_rounded;
    }
  }

  String get idPrefix {
    switch (this) {
      case AssetCategory.vehicle:
      case AssetCategory.bike:
        return 'BIKE';
      case AssetCategory.car:
        return 'CAR';
      case AssetCategory.electronics:
      case AssetCategory.laptop:
        return 'ELEC';
      case AssetCategory.belonging:
      case AssetCategory.bag:
        return 'ITEM';
      case AssetCategory.phone:
        return 'PHONE';
      case AssetCategory.wallet:
        return 'WALL';
      case AssetCategory.watch:
        return 'WTCH';
      case AssetCategory.camera:
        return 'CAM';
      case AssetCategory.documents:
        return 'DOC';
      case AssetCategory.jewellery:
        return 'JEWL';
      case AssetCategory.other:
        return 'ITEM';
    }
  }
}

enum AssetStatus {
  safe,
  stolen,
  recovered,
  found,
  registered,
  lost,
  matched;

  String get displayName {
    switch (this) {
      case AssetStatus.safe:
      case AssetStatus.registered:
        return 'Registered';
      case AssetStatus.stolen:
      case AssetStatus.lost:
        return 'Lost';
      case AssetStatus.recovered:
        return 'Recovered';
      case AssetStatus.found:
        return 'Found';
      case AssetStatus.matched:
        return 'Matched';
    }
  }

  Color get color {
    switch (this) {
      case AssetStatus.safe:
      case AssetStatus.registered:
        return const Color(0xFF10B981); // Emerald
      case AssetStatus.stolen:
      case AssetStatus.lost:
        return const Color(0xFFEF4444); // Crimson
      case AssetStatus.recovered:
        return const Color(0xFF0EA5E9); // Sky / Cyan
      case AssetStatus.found:
        return const Color(0xFFF59E0B); // Amber
      case AssetStatus.matched:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  bool get isAlert => isLost || isFound || isMatched;
  bool get isLost => this == AssetStatus.stolen || this == AssetStatus.lost;
  bool get isSecure => this == AssetStatus.safe || this == AssetStatus.registered;
  bool get isSafe => isSecure;
  bool get isRegistered => isSecure;
  bool get isFound => this == AssetStatus.found;
  bool get isMatched => this == AssetStatus.matched;
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
  final String ownerName;
  final String name;
  final AssetCategory category;
  final String brand;
  final String model;
  final String color;
  final String description;
  final String serialNumber;
  final String registrationNumber;
  final String? photoUrl;
  final String? image;
  AssetStatus status;
  bool trackingEnabled;
  final DateTime createdAt;
  DateTime updatedAt;
  double latitude;
  double longitude;
  double locationAccuracy;
  String address;
  String lastSeenLocation;
  DateTime lastPing;
  final List<LocationPoint> locationHistory;
  final DateTime? lostAt;
  final DateTime? foundAt;
  final DateTime? recoveredAt;
  final String? foundLocation;
  final String? finderNote;
  final String? finderPhoto;
  final String? matchedFoundItemId;

  // Compatibility alias getters
  String get itemId => id;
  String get itemName => name;
  String get categoryName => category.name;
  String? get photo => photoUrl ?? image;
  String get identifier => tracebackId;
  String get qrIdentifier => tracebackId;
  double get lastKnownLatitude => latitude;
  double get lastKnownLongitude => longitude;
  DateTime get lastLocationUpdatedAt => lastPing;
  LatLng get latLng => LatLng(latitude, longitude);

  bool get isLost => status.isLost;
  bool get isSafe => status.isSafe;
  bool get isSecure => status.isSecure;
  bool get isRegistered => status.isRegistered;
  bool get isFound => status.isFound;
  bool get isMatched => status.isMatched;
  bool get isRecovered => status.isRecovered;

  TrackingState get trackingState => LocationService.computeTrackingState(
    trackingEnabled: trackingEnabled,
    lastLocationUpdatedAt: lastPing,
  );

  Asset({
    required this.id,
    required this.tracebackId,
    this.ownerId = 'default_user',
    this.ownerName = '',
    required this.name,
    required this.category,
    this.brand = '',
    this.model = '',
    this.color = '',
    this.description = '',
    this.serialNumber = '',
    this.registrationNumber = '',
    this.photoUrl,
    this.image,
    required this.status,
    this.trackingEnabled = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    this.locationAccuracy = 8.0,
    String? address,
    this.lastSeenLocation = '',
    DateTime? lastPing,
    List<LocationPoint>? locationHistory,
    this.lostAt,
    this.foundAt,
    this.recoveredAt,
    this.foundLocation,
    this.finderNote,
    this.finderPhoto,
    this.matchedFoundItemId,
  })  : latitude = latitude ?? LocationService.bhubaneswarLatitude,
        longitude = longitude ?? LocationService.bhubaneswarLongitude,
        address = address ?? 'Bhubaneswar, Odisha',
        lastPing = lastPing ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        locationHistory = locationHistory ?? [];

  Asset copyWith({
    String? id,
    String? tracebackId,
    String? ownerId,
    String? ownerName,
    String? name,
    AssetCategory? category,
    String? brand,
    String? model,
    String? color,
    String? description,
    String? serialNumber,
    String? registrationNumber,
    String? photoUrl,
    String? image,
    AssetStatus? status,
    bool? trackingEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    String? address,
    String? lastSeenLocation,
    DateTime? lastPing,
    List<LocationPoint>? locationHistory,
    String? identifier,
    DateTime? lostAt,
    DateTime? foundAt,
    DateTime? recoveredAt,
    String? foundLocation,
    String? finderNote,
    String? finderPhoto,
    String? matchedFoundItemId,
  }) {
    return Asset(
      id: id ?? this.id,
      tracebackId: tracebackId ?? identifier ?? this.tracebackId,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      description: description ?? this.description,
      serialNumber: serialNumber ?? this.serialNumber,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      image: image ?? this.image,
      status: status ?? this.status,
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
      address: address ?? this.address,
      lastSeenLocation: lastSeenLocation ?? this.lastSeenLocation,
      lastPing: lastPing ?? this.lastPing,
      locationHistory: locationHistory ?? List.from(this.locationHistory),
      lostAt: lostAt ?? this.lostAt,
      foundAt: foundAt ?? this.foundAt,
      recoveredAt: recoveredAt ?? this.recoveredAt,
      foundLocation: foundLocation ?? this.foundLocation,
      finderNote: finderNote ?? this.finderNote,
      finderPhoto: finderPhoto ?? this.finderPhoto,
      matchedFoundItemId: matchedFoundItemId ?? this.matchedFoundItemId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': id,
    'tracebackId': tracebackId,
    'ownerId': ownerId,
    'ownerName': ownerName,
    'name': name,
    'itemName': name,
    'category': category.index,
    'categoryName': category.name,
    'brand': brand,
    'model': model,
    'color': color,
    'description': description,
    'serialNumber': serialNumber,
    'registrationNumber': registrationNumber,
    'photoUrl': photoUrl ?? image,
    'image': image ?? photoUrl,
    'status': status.index,
    'statusName': status.name,
    'trackingEnabled': trackingEnabled,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'locationAccuracy': locationAccuracy,
    'address': address,
    'lastSeenLocation': lastSeenLocation,
    'lastPing': lastPing.toIso8601String(),
    'locationHistory': locationHistory.map((p) => p.toJson()).toList(),
    if (lostAt != null) 'lostAt': lostAt!.toIso8601String(),
    if (foundAt != null) 'foundAt': foundAt!.toIso8601String(),
    if (recoveredAt != null) 'recoveredAt': recoveredAt!.toIso8601String(),
    if (foundLocation != null) 'foundLocation': foundLocation,
    if (finderNote != null) 'finderNote': finderNote,
    if (finderPhoto != null) 'finderPhoto': finderPhoto,
  };

  factory Asset.fromJson(Map<String, dynamic> json) {
    // Parse category gracefully
    AssetCategory cat = AssetCategory.belonging;
    if (json['category'] is int) {
      final idx = json['category'] as int;
      if (idx >= 0 && idx < AssetCategory.values.length) {
        cat = AssetCategory.values[idx];
      }
    } else if (json['category'] is String) {
      cat = AssetCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == (json['category'] as String).toLowerCase(),
        orElse: () => AssetCategory.belonging,
      );
    }

    // Parse status gracefully
    AssetStatus stat = AssetStatus.safe;
    if (json['status'] is int) {
      final idx = json['status'] as int;
      if (idx >= 0 && idx < AssetStatus.values.length) {
        stat = AssetStatus.values[idx];
      }
    } else if (json['status'] is String) {
      final s = (json['status'] as String).toLowerCase();
      stat = AssetStatus.values.firstWhere(
        (st) => st.name.toLowerCase() == s,
        orElse: () {
          if (s == 'registered') return AssetStatus.registered;
          if (s == 'lost') return AssetStatus.lost;
          if (s == 'found') return AssetStatus.found;
          if (s == 'matched') return AssetStatus.matched;
          if (s == 'recovered') return AssetStatus.recovered;
          return AssetStatus.safe;
        },
      );
    }

    return Asset(
      id: json['id'] as String? ?? json['itemId'] as String? ?? '',
      tracebackId: json['tracebackId'] as String? ?? json['identifier'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      name: json['name'] as String? ?? json['itemName'] as String? ?? 'Item',
      category: cat,
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      color: json['color'] as String? ?? '',
      description: json['description'] as String? ?? '',
      serialNumber: json['serialNumber'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      image: json['image'] as String? ?? json['photoUrl'] as String?,
      status: stat,
      trackingEnabled: json['trackingEnabled'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? LocationService.bhubaneswarLatitude,
      longitude: (json['longitude'] as num?)?.toDouble() ?? LocationService.bhubaneswarLongitude,
      locationAccuracy: (json['locationAccuracy'] as num?)?.toDouble() ?? 8.0,
      address: json['address'] as String? ?? 'Bhubaneswar, Odisha',
      lastSeenLocation: json['lastSeenLocation'] as String? ?? '',
      lastPing: json['lastPing'] != null
          ? DateTime.tryParse(json['lastPing']) ?? DateTime.now()
          : DateTime.now(),
      locationHistory: (json['locationHistory'] as List<dynamic>?)
              ?.map((e) => LocationPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lostAt: json['lostAt'] != null ? DateTime.tryParse(json['lostAt']) : null,
      foundAt: json['foundAt'] != null ? DateTime.tryParse(json['foundAt']) : null,
      recoveredAt: json['recoveredAt'] != null ? DateTime.tryParse(json['recoveredAt']) : null,
      foundLocation: json['foundLocation'] as String?,
      finderNote: json['finderNote'] as String?,
      finderPhoto: json['finderPhoto'] as String?,
    );
  }
}
