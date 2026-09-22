import 'package:cloud_firestore/cloud_firestore.dart';

enum FoundItemStatus {
  reported,
  matched,
  claimed,
  returned,
}

class FoundItem {
  final String foundItemId;
  final String finderId;
  final String finderName;
  final String finderContact;
  final String itemName;
  final String category;
  final String? brand;
  final String? model;
  final String? color;
  final String? description;
  final String? serialNumber;
  final String? registrationNumber;
  final String? photoUrl;
  final String foundLocation;
  final double? latitude;
  final double? longitude;
  final DateTime foundAt;
  final FoundItemStatus status;
  final String? matchedItemId;
  final String? matchedOwnerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get id => foundItemId;
  String? get matchedAssetId => matchedItemId;

  FoundItem({
    required this.foundItemId,
    required this.finderId,
    required this.finderName,
    this.finderContact = '',
    required this.itemName,
    required this.category,
    this.brand,
    this.model,
    this.color,
    this.description,
    this.serialNumber,
    this.registrationNumber,
    this.photoUrl,
    String? foundLocation,
    this.latitude,
    this.longitude,
    DateTime? foundAt,
    this.status = FoundItemStatus.reported,
    this.matchedItemId,
    this.matchedOwnerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : foundLocation = (foundLocation != null && foundLocation.isNotEmpty) ? foundLocation : 'Bhubaneswar, Odisha',
        foundAt = foundAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get statusName {
    switch (status) {
      case FoundItemStatus.reported:
        return 'reported';
      case FoundItemStatus.matched:
        return 'matched';
      case FoundItemStatus.claimed:
        return 'claimed';
      case FoundItemStatus.returned:
        return 'returned';
    }
  }

  static FoundItemStatus parseStatus(dynamic value) {
    if (value is FoundItemStatus) return value;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'matched':
          return FoundItemStatus.matched;
        case 'claimed':
          return FoundItemStatus.claimed;
        case 'returned':
        case 'recovered':
          return FoundItemStatus.returned;
        case 'reported':
        default:
          return FoundItemStatus.reported;
      }
    }
    return FoundItemStatus.reported;
  }

  factory FoundItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return FoundItem(
      foundItemId: json['foundItemId']?.toString() ?? json['id']?.toString() ?? '',
      finderId: json['finderId']?.toString() ?? '',
      finderName: json['finderName']?.toString() ?? 'Anonymous Finder',
      finderContact: json['finderContact']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      color: json['color']?.toString(),
      description: json['description']?.toString(),
      serialNumber: json['serialNumber']?.toString(),
      registrationNumber: json['registrationNumber']?.toString(),
      photoUrl: json['photoUrl']?.toString() ?? json['imagePath']?.toString(),
      foundLocation: json['foundLocation']?.toString() ?? json['location']?.toString() ?? 'Unknown Location',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      foundAt: parseDate(json['foundAt']),
      status: parseStatus(json['status']),
      matchedItemId: json['matchedItemId']?.toString(),
      matchedOwnerId: json['matchedOwnerId']?.toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foundItemId': foundItemId,
      'finderId': finderId,
      'finderName': finderName,
      'finderContact': finderContact,
      'itemName': itemName,
      'category': category,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (color != null) 'color': color,
      if (description != null) 'description': description,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (registrationNumber != null) 'registrationNumber': registrationNumber,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'foundLocation': foundLocation,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'foundAt': foundAt.toIso8601String(),
      'status': statusName,
      if (matchedItemId != null) 'matchedItemId': matchedItemId,
      if (matchedOwnerId != null) 'matchedOwnerId': matchedOwnerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FoundItem copyWith({
    String? foundItemId,
    String? finderId,
    String? finderName,
    String? finderContact,
    String? itemName,
    String? category,
    String? brand,
    String? model,
    String? color,
    String? description,
    String? serialNumber,
    String? registrationNumber,
    String? photoUrl,
    String? foundLocation,
    double? latitude,
    double? longitude,
    DateTime? foundAt,
    FoundItemStatus? status,
    String? matchedItemId,
    String? matchedOwnerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoundItem(
      foundItemId: foundItemId ?? this.foundItemId,
      finderId: finderId ?? this.finderId,
      finderName: finderName ?? this.finderName,
      finderContact: finderContact ?? this.finderContact,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      description: description ?? this.description,
      serialNumber: serialNumber ?? this.serialNumber,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      foundLocation: foundLocation ?? this.foundLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      foundAt: foundAt ?? this.foundAt,
      status: status ?? this.status,
      matchedItemId: matchedItemId ?? this.matchedItemId,
      matchedOwnerId: matchedOwnerId ?? this.matchedOwnerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
