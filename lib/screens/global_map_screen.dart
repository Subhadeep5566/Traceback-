import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/map_config.dart';
import '../models/asset.dart';
import '../models/found_item.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'asset_detail_screen.dart';
import 'found_item_screen.dart';
import '../design/tb_theme.dart';

// ────────────────────────────────────────────────
// Data model used by the map to represent a pin
// ────────────────────────────────────────────────
enum _PinType { lostAsset, foundItem, recoveredAsset }

class _MapPin {
  final LatLng position;
  final _PinType type;
  final String title;
  final String subtitle;   // status / category
  final String location;   // address label
  final String timeAgo;
  final String? assetId;
  final String? foundItemId;
  final IconData icon;
  final Color color;

  const _MapPin({
    required this.position,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.timeAgo,
    this.assetId,
    this.foundItemId,
    required this.icon,
    required this.color,
  });
}

// ────────────────────────────────────────────────
// Screen
// ────────────────────────────────────────────────
class GlobalMapScreen extends StatefulWidget {
  final String? initialAssetId;

  const GlobalMapScreen({
    super.key,
    this.initialAssetId,
  });

  @override
  State<GlobalMapScreen> createState() => _GlobalMapScreenState();
}

class _GlobalMapScreenState extends State<GlobalMapScreen>
    with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();

  // Filter: 'ALL' | 'LOST' | 'FOUND' | 'RECOVERED'
  String _activeFilter = 'ALL';

  // Live Firestore data
  List<Asset> _assets = [];
  List<FoundItem> _foundItems = [];
  StreamSubscription<List<Asset>>? _assetsSub;
  StreamSubscription<List<FoundItem>>? _foundSub;

  // Selected pin for bottom card
  _MapPin? _selectedPin;

  // GPS state
  bool _isLocating = false;

  static const LatLng _defaultCenter = LatLng(
    MapConfig.defaultLatitude,
    MapConfig.defaultLongitude,
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _subscribeToFirestore();

    if (widget.initialAssetId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpToAsset(widget.initialAssetId!);
      });
    }
  }

  @override
  void dispose() {
    _assetsSub?.cancel();
    _foundSub?.cancel();
    super.dispose();
  }

  // ── Firestore real-time listeners ───────────────
  void _subscribeToFirestore() {
    // Lost / recovered assets that have valid coordinates
    _assetsSub = _firestoreService.streamAllItems().listen((assets) {
      if (mounted) setState(() => _assets = assets);
    }, onError: (e) => debugPrint('Map assets stream error: $e'));

    // Found items with coordinates
    _foundSub = _firestoreService.streamAllFoundItems().listen((items) {
      if (mounted) setState(() => _foundItems = items);
    }, onError: (e) => debugPrint('Map found items stream error: $e'));
  }

  // ── Jump to a specific asset on open ────────────
  void _jumpToAsset(String assetId) {
    final asset = _assets.cast<Asset?>().firstWhere(
      (a) => a?.id == assetId,
      orElse: () => null,
    );
    if (asset != null && _hasCoords(asset.latitude, asset.longitude)) {
      _mapController.move(LatLng(asset.latitude, asset.longitude), MapConfig.detailZoom);
    }
  }

  // ── GPS ─────────────────────────────────────────
  Future<void> _moveToUserLocation() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled on your device');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _showSnack('Location permission is required');
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _showSnack('Location permission permanently denied — enable in Settings');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _mapController.move(LatLng(pos.latitude, pos.longitude), MapConfig.detailZoom);
    } catch (e) {
      debugPrint('GPS error: $e');
      _showSnack('Could not obtain GPS location');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _resetToDefault() {
    _mapController.move(_defaultCenter, MapConfig.defaultZoom);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Get Directions ───────────────────────────────
  Future<void> _openDirections(double lat, double lng, String? label) async {
    final uri = LocationService.getDirectionsUri(lat, lng, label: label);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: open OSM in browser
        final webUri = Uri.parse(
          'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng&zoom=16',
        );
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showSnack('Could not open navigation app');
    }
  }

  // ── Pin builder ──────────────────────────────────
  bool _hasCoords(double lat, double lng) =>
      lat != 0.0 || lng != 0.0;

  List<_MapPin> _buildPins() {
    final pins = <_MapPin>[];

    for (final asset in _assets) {
      if (!_hasCoords(asset.latitude, asset.longitude)) continue;

      if (_activeFilter == 'LOST' && !asset.isLost) continue;
      if (_activeFilter == 'FOUND' && !asset.isFound) continue;
      if (_activeFilter == 'RECOVERED' && !asset.isRecovered) continue;
      if (_activeFilter == 'ALL' && asset.status == AssetStatus.safe) continue; // safe items not on map

      final type = asset.isLost
          ? _PinType.lostAsset
          : asset.isFound
              ? _PinType.foundItem
              : _PinType.recoveredAsset;

      final color = asset.isLost
          ? const Color(MapConfig.lostMarkerColor)
          : asset.isFound
              ? const Color(MapConfig.foundMarkerColor)
              : const Color(MapConfig.recoveredMarkerColor);

      pins.add(_MapPin(
        position: LatLng(asset.latitude, asset.longitude),
        type: type,
        title: asset.name,
        subtitle: asset.status.displayName,
        location: asset.address.isNotEmpty ? asset.address : 'Bhubaneswar, Odisha',
        timeAgo: LocationService.formatTimeAgo(asset.updatedAt),
        assetId: asset.id,
        icon: asset.category.icon,
        color: color,
      ));
    }

    // Found items (only if filter is ALL or FOUND)
    if (_activeFilter == 'ALL' || _activeFilter == 'FOUND') {
      for (final item in _foundItems) {
        if (item.latitude == null || item.longitude == null) continue;
        if (!_hasCoords(item.latitude!, item.longitude!)) continue;

        pins.add(_MapPin(
          position: LatLng(item.latitude!, item.longitude!),
          type: _PinType.foundItem,
          title: item.itemName,
          subtitle: 'Found Item',
          location: item.foundLocation.isNotEmpty ? item.foundLocation : 'Unknown',
          timeAgo: LocationService.formatTimeAgo(item.foundAt),
          foundItemId: item.foundItemId,
          icon: Icons.search_rounded,
          color: const Color(MapConfig.foundMarkerColor),
        ));
      }
    }

    return pins;
  }

  List<Marker> _buildMarkers(List<_MapPin> pins) {
    return pins.map((pin) => Marker(
      point: pin.position,
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => setState(() => _selectedPin = pin),
        child: _MarkerWidget(color: pin.color, icon: pin.icon),
      ),
    )).toList();
  }

  // ── Build ────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final pins = _buildPins();
    final markers = _buildMarkers(pins);

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: MapConfig.defaultZoom,
              minZoom: MapConfig.minZoom,
              maxZoom: MapConfig.maxZoom,
              onTap: (_, _) {
                if (_selectedPin != null) setState(() => _selectedPin = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrlTemplate,
                userAgentPackageName: MapConfig.userAgentPackageName,
                maxZoom: MapConfig.maxZoom,
                tileBuilder: MapConfig.darkTileBuilder,
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // ── Filter bar ─────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141416),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TbColors.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: _FilterBar(
                      active: _activeFilter,
                      onChange: (v) => setState(() {
                        _activeFilter = v;
                        _selectedPin = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Floating controls ──────────────────
          Positioned(
            right: 16,
            bottom: _selectedPin != null ? 200 : 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapFab(
                  heroTag: 'reset_map',
                  icon: Icons.location_city_rounded,
                  light: true,
                  tooltip: 'Center on Bhubaneswar',
                  onTap: _resetToDefault,
                ),
                const SizedBox(height: 10),
                _MapFab(
                  heroTag: 'gps_me',
                  icon: Icons.my_location_rounded,
                  light: false,
                  tooltip: 'My Location',
                  loading: _isLocating,
                  onTap: _isLocating ? null : _moveToUserLocation,
                ),
              ],
            ),
          ),

          // ── Bottom info card ───────────────────
          if (_selectedPin != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _PinInfoCard(
                pin: _selectedPin!,
                onClose: () => setState(() => _selectedPin = null),
                onView: () => _onViewPin(_selectedPin!),
                onDirections: () => _openDirections(
                  _selectedPin!.position.latitude,
                  _selectedPin!.position.longitude,
                  _selectedPin!.title,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onViewPin(_MapPin pin) {
    if (pin.assetId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AssetDetailScreen(assetId: pin.assetId!)),
      );
    } else if (pin.foundItemId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FoundItemScreen()),
      );
    }
  }
}

// ────────────────────────────────────────────────
// Sub-widgets (kept in the same file for locality)
// ────────────────────────────────────────────────

class _MarkerWidget extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _MarkerWidget({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 17),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String active;
  final ValueChanged<String> onChange;
  const _FilterBar({required this.active, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TbColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _Chip('ALL', 'All', null, active, onChange),
          const SizedBox(width: 4),
          _Chip('LOST', 'Lost', const Color(MapConfig.lostMarkerColor), active, onChange),
          const SizedBox(width: 4),
          _Chip('FOUND', 'Found', const Color(MapConfig.foundMarkerColor), active, onChange),
          const SizedBox(width: 4),
          _Chip('RECOVERED', 'Recovered', const Color(MapConfig.recoveredMarkerColor), active, onChange),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String key2;
  final String label;
  final Color? dot;
  final String active;
  final ValueChanged<String> onChange;
  const _Chip(this.key2, this.label, this.dot, this.active, this.onChange);

  @override
  Widget build(BuildContext context) {
    final selected = active == key2;
    return GestureDetector(
      onTap: () => onChange(key2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (dot != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.black : TbColors.textMuted,
            ),
          ),
        ]),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final bool light;
  final String tooltip;
  final bool loading;
  final VoidCallback? onTap;
  const _MapFab({
    required this.heroTag,
    required this.icon,
    required this.light,
    required this.tooltip,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TbColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _PinInfoCard extends StatelessWidget {
  final _MapPin pin;
  final VoidCallback onClose;
  final VoidCallback onView;
  final VoidCallback onDirections;

  const _PinInfoCard({
    required this.pin,
    required this.onClose,
    required this.onView,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: pin.type == _PinType.lostAsset
              ? const Color(0x66EF4444)
              : TbColors.cardBorder,
          width: pin.type == _PinType.lostAsset ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ──────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: pin.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: pin.color.withOpacity(0.3)),
                ),
                child: Icon(pin.icon, size: 22, color: pin.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pin.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: pin.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pin.subtitle.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: pin.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pin.timeAgo,
                        style: const TextStyle(fontSize: 11, color: TbColors.textMuted),
                      ),
                    ]),
                  ],
                ),
              ),
              // Close button
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222226),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TbColors.cardBorder),
                  ),
                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Location row ────────────
          Row(children: [
            const Icon(Icons.place_rounded, size: 13, color: TbColors.textMuted),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                pin.location,
                style: const TextStyle(
                  fontSize: 12,
                  color: TbColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),

          const SizedBox(height: 14),

          // ── Action buttons ──────────
          Row(children: [
            Expanded(
              child: _CardButton(
                label: 'View Item',
                icon: Icons.open_in_new_rounded,
                primary: false,
                onTap: onView,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CardButton(
                label: 'Directions',
                icon: Icons.navigation_rounded,
                primary: true,
                onTap: onDirections,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;
  const _CardButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: primary ? Colors.white : const Color(0xFF222226),
          borderRadius: BorderRadius.circular(12),
          border: primary ? null : Border.all(color: TbColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: primary ? Colors.black : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: primary ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
