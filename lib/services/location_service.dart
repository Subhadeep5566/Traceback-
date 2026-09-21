import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum TrackingState {
  live,
  updating,
  lastSeen,
  offline,
  disabled;

  String get displayName {
    switch (this) {
      case TrackingState.live:
        return 'LIVE';
      case TrackingState.updating:
        return 'UPDATING';
      case TrackingState.lastSeen:
        return 'LAST SEEN';
      case TrackingState.offline:
        return 'OFFLINE';
      case TrackingState.disabled:
        return 'DISABLED';
    }
  }
}

class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String address;
  final bool isRealGps;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.address,
    this.isRealGps = true,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}

class LocationService {
  static const LatLng bguCampusCenter = LatLng(20.2982, 85.7434);
  static const String defaultCampusAddress = 'Birla Global University, Gothapatna, Bhubaneswar';

  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  static Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  static Future<LocationPermission> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission;
    } catch (e) {
      debugPrint('LocationService requestPermission error: $e');
      return LocationPermission.denied;
    }
  }

  static Future<LocationResult> getCurrentLocation({
    String fallbackAddress = defaultCampusAddress,
    LatLng? fallbackLatLng,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallbackResult(fallbackAddress, fallbackLatLng);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallbackResult(fallbackAddress, fallbackLatLng);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _fallbackResult(fallbackAddress, fallbackLatLng);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final address = _formatCoordinatesAsCampusAddress(position.latitude, position.longitude);

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
        address: address,
        isRealGps: true,
      );
    } catch (e) {
      debugPrint('LocationService getCurrentLocation error: $e');
      return _fallbackResult(fallbackAddress, fallbackLatLng);
    }
  }

  static LocationResult _fallbackResult(String address, LatLng? latLng) {
    final target = latLng ?? bguCampusCenter;
    return LocationResult(
      latitude: target.latitude,
      longitude: target.longitude,
      accuracy: 12.0,
      timestamp: DateTime.now(),
      address: address.isNotEmpty ? address : defaultCampusAddress,
      isRealGps: false,
    );
  }

  static String _formatCoordinatesAsCampusAddress(double lat, double lng) {
    // If coordinates are in/near BGU Bhubaneswar
    if ((lat - 20.2982).abs() < 0.05 && (lng - 85.7434).abs() < 0.05) {
      return 'BGU Campus Area, Bhubaneswar';
    }
    return '${lat.toStringAsFixed(4)}°N, ${lng.toStringAsFixed(4)}°E';
  }

  static TrackingState computeTrackingState({
    required bool trackingEnabled,
    DateTime? lastLocationUpdatedAt,
  }) {
    if (!trackingEnabled) return TrackingState.disabled;
    if (lastLocationUpdatedAt == null) return TrackingState.offline;

    final difference = DateTime.now().difference(lastLocationUpdatedAt);
    if (difference.inSeconds < 30) {
      return TrackingState.live;
    } else if (difference.inHours < 24) {
      return TrackingState.lastSeen;
    } else {
      return TrackingState.offline;
    }
  }

  static String formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds} sec ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
