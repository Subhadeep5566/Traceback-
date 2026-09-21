import 'dart:async';
import '../models/asset.dart';
import '../models/incident.dart';

class TelematicsService {
  StreamController<List<Asset>>? _telemetryController;

  Stream<List<Asset>> get telemetryStream {
    _telemetryController ??= StreamController<List<Asset>>.broadcast();
    return _telemetryController!.stream;
  }

  List<Asset> getInitialAssets() {
    final now = DateTime.now();

    return [
      Asset(
        id: 'AST-001',
        tracebackId: 'TB-BIKE-001',
        ownerId: 'student_current',
        name: 'Campus Bike',
        category: AssetCategory.vehicle,
        brand: 'Hero',
        model: 'Sprint Pro',
        color: 'Matte Black',
        description: 'Black hybrid bicycle with BGU registration sticker on frame.',
        status: AssetStatus.safe,
        trackingEnabled: false,
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        latitude: 20.2982,
        longitude: 85.7434,
        locationAccuracy: 6.5,
        address: 'BGU Campus Cycle Stand, Bhubaneswar',
        lastPing: now.subtract(const Duration(minutes: 15)),
        locationHistory: [
          LocationPoint(latitude: 20.2982, longitude: 85.7434, timestamp: now.subtract(const Duration(minutes: 15))),
        ],
      ),
      Asset(
        id: 'AST-002',
        tracebackId: 'TB-LAPTOP-002',
        ownerId: 'student_current',
        name: 'Student Laptop',
        category: AssetCategory.electronics,
        brand: 'Apple',
        model: 'MacBook Pro M2 14"',
        color: 'Space Gray',
        description: 'Includes BGU CS sticker and blue protective sleeve.',
        status: AssetStatus.stolen,
        trackingEnabled: true,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(minutes: 4)),
        latitude: 20.2995,
        longitude: 85.7410,
        locationAccuracy: 8.0,
        address: 'Near Central Library & Academic Block, BGU Campus',
        lastPing: now.subtract(const Duration(seconds: 14)),
        locationHistory: [
          LocationPoint(latitude: 20.2991, longitude: 85.7445, timestamp: now.subtract(const Duration(hours: 1))),
          LocationPoint(latitude: 20.2995, longitude: 85.7410, timestamp: now.subtract(const Duration(seconds: 14))),
        ],
      ),
      Asset(
        id: 'AST-003',
        tracebackId: 'TB-PHONE-003',
        ownerId: 'student_current',
        name: 'Smartphone',
        category: AssetCategory.phone,
        brand: 'OnePlus',
        model: '12 256GB',
        color: 'Flowy Emerald',
        description: 'Clear bumper case with student ID card inserted inside back.',
        status: AssetStatus.recovered,
        trackingEnabled: false,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 1)),
        latitude: 20.2974,
        longitude: 85.7426,
        locationAccuracy: 5.0,
        address: 'Hostel Block A, BGU Campus, Gothapatna',
        lastPing: now.subtract(const Duration(hours: 3)),
        locationHistory: [
          LocationPoint(latitude: 20.2974, longitude: 85.7426, timestamp: now.subtract(const Duration(hours: 3))),
        ],
      ),
      Asset(
        id: 'AST-004',
        tracebackId: 'TB-ITEM-004',
        ownerId: 'student_current',
        name: 'Smart Backpack',
        category: AssetCategory.belonging,
        brand: 'Wildcraft',
        model: 'Pulse 32L',
        color: 'Navy Blue',
        description: 'Contains semester study notes, scientific calculator, and charger.',
        status: AssetStatus.safe,
        trackingEnabled: false,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(hours: 5)),
        latitude: 20.2988,
        longitude: 85.7438,
        locationAccuracy: 10.0,
        address: 'BGU Cafeteria Complex, Bhubaneswar',
        lastPing: now.subtract(const Duration(minutes: 45)),
        locationHistory: [
          LocationPoint(latitude: 20.2988, longitude: 85.7438, timestamp: now.subtract(const Duration(minutes: 45))),
        ],
      ),
    ];
  }

  List<Incident> getInitialIncidents() {
    final now = DateTime.now();

    return [
      Incident(
        id: 'INC-BGU-002',
        assetId: 'AST-002',
        assetName: 'Student Laptop (TB-LAPTOP-002)',
        timestamp: now.subtract(const Duration(hours: 1)),
        type: 'Theft / Missing Report',
        status: 'Tracking',
        description: 'Reported missing near Library Study Hall. Traceback tag beacon active.',
        latitude: 20.2995,
        longitude: 85.7410,
        timeline: [
          IncidentTimelineStep(
            title: 'Registered',
            description: 'Item registered with unique ID TB-LAPTOP-002.',
            timestamp: now.subtract(const Duration(days: 30)),
          ),
          IncidentTimelineStep(
            title: 'Reported Stolen',
            description: 'Missing from BGU Central Library table.',
            timestamp: now.subtract(const Duration(hours: 1)),
          ),
          IncidentTimelineStep(
            title: 'Trace Activated',
            description: 'GPS telemetry enabled (Accuracy ±8m).',
            timestamp: now.subtract(const Duration(minutes: 58)),
          ),
          IncidentTimelineStep(
            title: 'Location Ping Received',
            description: 'Latest beacon spotted near Academic Block.',
            timestamp: now.subtract(const Duration(seconds: 14)),
          ),
        ],
      ),
      Incident(
        id: 'INC-BGU-003',
        assetId: 'AST-003',
        assetName: 'Smartphone (TB-PHONE-003)',
        timestamp: now.subtract(const Duration(days: 2)),
        type: 'Misplaced Belonging',
        status: 'Recovered',
        description: 'Misplaced in campus cafeteria. Reported found and recovered by student.',
        latitude: 20.2974,
        longitude: 85.7426,
        timeline: [
          IncidentTimelineStep(
            title: 'Registered',
            description: 'Registered with Traceback ID TB-PHONE-003.',
            timestamp: now.subtract(const Duration(days: 45)),
          ),
          IncidentTimelineStep(
            title: 'Reported Lost',
            description: 'Misplaced in cafeteria after lunch.',
            timestamp: now.subtract(const Duration(days: 2)),
          ),
          IncidentTimelineStep(
            title: 'Found Report Received',
            description: 'Handed to hostel security desk by community finder.',
            timestamp: now.subtract(const Duration(days: 1, hours: 2)),
          ),
          IncidentTimelineStep(
            title: 'Recovered & Verified',
            description: 'Owner confirmed possession and verified tag identity.',
            timestamp: now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
      Incident(
        id: 'INC-BGU-001',
        assetId: 'AST-001',
        assetName: 'Campus Bike (TB-BIKE-001)',
        timestamp: now.subtract(const Duration(days: 14)),
        type: 'Asset Registration',
        status: 'Secure',
        description: 'Registered into personal inventory.',
        latitude: 20.2982,
        longitude: 85.7434,
        timeline: [
          IncidentTimelineStep(
            title: 'Registered',
            description: 'Unique tag TB-BIKE-001 generated.',
            timestamp: now.subtract(const Duration(days: 14)),
          ),
          IncidentTimelineStep(
            title: 'Tag Verified',
            description: 'Traceback physical tag attached and active.',
            timestamp: now.subtract(const Duration(days: 14)),
          ),
        ],
      ),
    ];
  }

  void stopSimulation() {}

  void startSimulation(List<Asset> Function() getAssets, void Function(List<Asset>) onUpdate) {}

  void dispose() {
    _telemetryController?.close();
  }
}
