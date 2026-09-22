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
  static const double bhubaneswarLatitude = 20.2961;
  static const double bhubaneswarLongitude = 85.8245;
  static const LatLng bhubaneswarCenter = LatLng(20.2961, 85.8245);
  static const LatLng bguCampusCenter = LatLng(20.2982, 85.7434);
  static const String defaultCampusAddress = 'Birla Global University, Gothapatna, Bhubaneswar';
  static const String defaultCityAddress = 'Bhubaneswar, Odisha, India';

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
    return reverseGeocodeLabel(lat, lng);
  }

  static String reverseGeocodeLabel(double lat, double lng) {
    if ((lat - 20.2982).abs() < 0.03 && (lng - 85.7434).abs() < 0.03) {
      return 'BGU Campus, Gothapatna, Bhubaneswar';
    } else if ((lat - 20.2961).abs() < 0.04 && (lng - 85.8245).abs() < 0.04) {
      return 'Bhubaneswar Central, Odisha';
    } else if ((lat - 20.3533).abs() < 0.04 && (lng - 85.8189).abs() < 0.04) {
      return 'Patia Area, Bhubaneswar';
    } else if ((lat - 20.3010).abs() < 0.04 && (lng - 85.8180).abs() < 0.04) {
      return 'Jayadev Vihar, Bhubaneswar';
    } else if ((lat - 20.2666).abs() < 0.04 && (lng - 85.8440).abs() < 0.04) {
      return 'Bhubaneswar Station Area';
    }
    return '${lat.toStringAsFixed(4)}°N, ${lng.toStringAsFixed(4)}°E (Bhubaneswar)';
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

  // ──────────────────────────────────────────────
  // Navigation / Directions
  // ──────────────────────────────────────────────

  /// Returns a standard [geo:] URI that the OS will route to whatever
  /// mapping/navigation app the user has installed (Google Maps, OsmAnd,
  /// Apple Maps, Here WeGo, etc.). No Google Maps SDK required.
  ///
  /// Usage:
  ///   final uri = LocationService.getDirectionsUri(20.2961, 85.8245);
  ///   await launchUrl(uri, mode: LaunchMode.externalApplication);
  static Uri getDirectionsUri(double latitude, double longitude, {String? label}) {
    // geo: URI is the standard cross-platform deep-link for map apps.
    // Android and iOS both handle it natively.
    final latStr = latitude.toStringAsFixed(6);
    final lngStr = longitude.toStringAsFixed(6);
    final query = label != null
        ? '$latStr,$lngStr($Uri.encodeComponent(label))'
        : '$latStr,$lngStr';
    return Uri.parse('geo:$latStr,$lngStr?q=$query');
  }

  /// Returns a human-readable directions URL string.
  static String getDirectionsUrl(double latitude, double longitude) =>
      getDirectionsUri(latitude, longitude).toString();
}

