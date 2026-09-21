import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/incident.dart';

class DemoDataService {
  static const String demoUserName = 'Demo Student';
  static const String demoUserEmail = 'demo@bgu.ac.in';
  static const String demoUserPhone = '+91 90000 00000';

  static List<Asset> getDemoAssets() {
    final now = DateTime.now();

    return [
      Asset(
        id: 'TB-BIKE-001',
        tracebackId: 'TB-BIKE-001',
        name: 'Campus Bike',
        category: AssetCategory.vehicle,
        brand: 'Hero',
        model: 'Sprint Pro',
        color: 'Black',
        description: 'Campus bike registered with BGU security tag.',
        status: AssetStatus.stolen, // LOST
        trackingEnabled: true,
        latitude: 20.2982,
        longitude: 85.7434,
        address: 'BGU Campus, Gothapatna, Bhubaneswar',
        lastPing: now.subtract(const Duration(minutes: 10)),
        locationHistory: [
          LocationPoint(
            latitude: 20.2970,
            longitude: 85.7420,
            timestamp: now.subtract(const Duration(minutes: 25)),
          ),
          LocationPoint(
            latitude: 20.2978,
            longitude: 85.7428,
            timestamp: now.subtract(const Duration(minutes: 18)),
          ),
          LocationPoint(
            latitude: 20.2982,
            longitude: 85.7434,
            timestamp: now.subtract(const Duration(minutes: 10)),
          ),
        ],
      ),
      Asset(
        id: 'TB-LAPTOP-002',
        tracebackId: 'TB-LAPTOP-002',
        name: 'Student Laptop',
        category: AssetCategory.electronics,
        brand: 'Apple',
        model: 'MacBook Pro',
        color: 'Silver',
        description: '14" laptop with BGU CS department sticker.',
        status: AssetStatus.safe, // SECURE
        trackingEnabled: false,
        latitude: 20.2991,
        longitude: 85.7445,
        address: 'BGU Library, Central Academic Block',
        lastPing: now.subtract(const Duration(hours: 1)),
        locationHistory: [
          LocationPoint(
            latitude: 20.2991,
            longitude: 85.7445,
            timestamp: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      Asset(
        id: 'TB-PHONE-003',
        tracebackId: 'TB-PHONE-003',
        name: 'Smartphone',
        category: AssetCategory.phone,
        brand: 'OnePlus',
        model: '12',
        color: 'Black',
        description: 'Smartphone with matte black case.',
        status: AssetStatus.found, // FOUND
        trackingEnabled: false,
        latitude: 20.2974,
        longitude: 85.7426,
        address: 'BGU Cafeteria, Student Activity Centre',
        lastPing: now.subtract(const Duration(hours: 2)),
        locationHistory: [
          LocationPoint(
            latitude: 20.2974,
            longitude: 85.7426,
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),
    ];
  }

  static List<Incident> getDemoIncidents() {
    final now = DateTime.now();

    return [
      Incident(
        id: 'INC-DEMO-001',
        assetId: 'TB-BIKE-001',
        assetName: 'Campus Bike (TB-BIKE-001)',
        timestamp: now.subtract(const Duration(minutes: 10)),
        type: 'Missing / Lost Report',
        status: 'Tracking',
        description: 'Campus Bike reported lost from BGU Campus parking lot. Live beacon active.',
        latitude: 20.2982,
        longitude: 85.7434,
        timeline: [
          IncidentTimelineStep(
            title: 'Campus Bike reported lost',
            description: 'Item reported missing from BGU Campus parking lot.',
            timestamp: now.subtract(const Duration(minutes: 10)),
          ),
          IncidentTimelineStep(
            title: 'Traceback Mesh Activated',
            description: 'High-frequency telemetry & nearby BLE detection enabled.',
            timestamp: now.subtract(const Duration(minutes: 8)),
          ),
        ],
      ),
      Incident(
        id: 'INC-DEMO-002',
        assetId: 'TB-PHONE-003',
        assetName: 'Smartphone (TB-PHONE-003)',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: 'Found Item Report',
        status: 'Found',
        description: 'Smartphone reported found at BGU Cafeteria table.',
        latitude: 20.2974,
        longitude: 85.7426,
        timeline: [
          IncidentTimelineStep(
            title: 'Smartphone reported found',
            description: 'Logged by campus community member at BGU Cafeteria counter.',
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
          IncidentTimelineStep(
            title: 'Location Verified',
            description: 'Item secured at student helpdesk.',
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),
      Incident(
        id: 'INC-DEMO-003',
        assetId: 'TB-LAPTOP-002',
        assetName: 'Student Laptop (TB-LAPTOP-002)',
        timestamp: now.subtract(const Duration(days: 1)),
        type: 'Device Registration',
        status: 'Recovered',
        description: 'Student Laptop registered and secured with Traceback tag.',
        latitude: 20.2991,
        longitude: 85.7445,
        timeline: [
          IncidentTimelineStep(
            title: 'Student Laptop registered',
            description: 'Asset registered to Demo Student account.',
            timestamp: now.subtract(const Duration(days: 1)),
          ),
          IncidentTimelineStep(
            title: 'Item Secured & Safe',
            description: 'Cryptographic tag confirmed active.',
            timestamp: now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
    ];
  }

  static String getRelativeTime(DateTime dateTime) => formatRelativeTime(dateTime);

  static List<Map<String, dynamic>> get demoActivities => [
    {
      'title': 'Campus Bike reported lost',
      'subtitle': 'Near BGU Academic Block',
      'time': '10 minutes ago',
      'icon': Icons.warning_amber_rounded,
      'color': const Color(0xFFE11D48),
    },
    {
      'title': 'Smartphone reported found',
      'subtitle': 'Found at BGU Cafeteria',
      'time': '2 hours ago',
      'icon': Icons.check_circle_outline_rounded,
      'color': const Color(0xFFF59E0B),
    },
    {
      'title': 'Student Laptop registered',
      'subtitle': 'Telemetry active at BGU Library',
      'time': 'Yesterday',
      'icon': Icons.security_rounded,
      'color': const Color(0xFF10B981),
    },
  ];

  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
