import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../services/location_service.dart';

class LiveTraceScreen extends StatefulWidget {
  final String assetId;

  const LiveTraceScreen({
    super.key,
    required this.assetId,
  });

  @override
  State<LiveTraceScreen> createState() => _LiveTraceScreenState();
}

class _LiveTraceScreenState extends State<LiveTraceScreen> {
  late final MapController _mapController;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _refreshGpsLocation();
    });
  }

  Future<void> _refreshGpsLocation() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final provider = context.read<AssetProvider>();
      if (mounted) {
        await provider.activateTrace(widget.assetId);
        final updated = provider.allAssets.firstWhere((a) => a.id == widget.assetId);
        _mapController.move(updated.latLng, _mapController.camera.zoom);
      }
    } catch (_) {}

    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _showConfirmRecoveryDialog(BuildContext context, AssetProvider provider, Asset asset) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Confirm Recovery', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text('Confirm that you have retrieved "${asset.name}"? Tracking will stop automatically.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              provider.confirmRecovery(asset.id);
              Navigator.pop(context); // Exit map
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item confirmed as recovered!')),
              );
            },
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssetProvider>(
      builder: (context, provider, child) {
        final asset = provider.allAssets.cast<Asset?>().firstWhere(
              (a) => a?.id == widget.assetId,
              orElse: () => null,
            );

        if (asset == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Live Trace')),
            body: const Center(child: Text('Asset not found')),
          );
        }

        final trackingState = _isRefreshing ? TrackingState.updating : asset.trackingState;
        final timeAgo = LocationService.formatTimeAgo(asset.lastLocationUpdatedAt);

        Color stateColor = const Color(0xFF10B981);
        if (trackingState == TrackingState.updating) {
          stateColor = const Color(0xFF0284C7);
        } else if (trackingState == TrackingState.lastSeen) {
          stateColor = const Color(0xFFF59E0B);
        } else if (trackingState == TrackingState.offline) {
          stateColor = const Color(0xFF64748B);
        }

        return Scaffold(
          body: Stack(
            children: [
              // 1. FULL SCREEN MAP (~80% visual focus)
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: asset.latLng,
                    initialZoom: 16.0,
                    minZoom: 11.0,
                    maxZoom: 18.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.traceback.app',
                    ),

                    // Accuracy Circle
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: asset.latLng,
                          radius: (asset.locationAccuracy * 2.2).clamp(18.0, 70.0),
                          useRadiusInMeter: false,
                          color: stateColor.withOpacity(0.18),
                          borderColor: stateColor.withOpacity(0.6),
                          borderStrokeWidth: 1.5,
                        ),
                      ],
                    ),

                    // Live Marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: asset.latLng,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(asset.category.icon, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. TOP FLOATING BAR: ← [Asset Name]
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          asset.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.my_location_rounded, size: 18, color: Colors.black),
                        tooltip: 'Recenter',
                        onPressed: () => _mapController.move(asset.latLng, 16.0),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. BOTTOM FLOATING PANEL: Minimal, uncrowded
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Name & ● LIVE Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              asset.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: stateColor,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                trackingState.displayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: stateColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Metadata: Updated & Accuracy
                      Text(
                        'Updated $timeAgo  ·  Accuracy ±${asset.locationAccuracy.toStringAsFixed(0)}m',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action Row: [ Stop Tracking ] + ⋯
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: asset.trackingEnabled ? Colors.black : const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  if (asset.trackingEnabled) {
                                    provider.stopTrace(asset.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Tracking stopped')),
                                    );
                                  } else {
                                    provider.activateTrace(asset.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Tracking activated')),
                                    );
                                  }
                                },
                                child: Text(
                                  asset.trackingEnabled ? 'Stop Tracking' : 'Activate Tracking',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Secondary actions under ⋯
                          PopupMenuButton<String>(
                            icon: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.more_horiz_rounded, size: 20, color: Colors.black),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            onSelected: (val) {
                              if (val == 'recenter') {
                                _mapController.move(asset.latLng, 16.0);
                              } else if (val == 'refresh') {
                                _refreshGpsLocation();
                              } else if (val == 'copy_coords') {
                                final text = '${asset.latitude.toStringAsFixed(5)}, ${asset.longitude.toStringAsFixed(5)}';
                                Clipboard.setData(ClipboardData(text: text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Coordinates ($text) copied')),
                                );
                              } else if (val == 'recovered') {
                                _showConfirmRecoveryDialog(context, provider, asset);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'recenter',
                                child: Text('Center on Marker', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              ),
                              const PopupMenuItem(
                                value: 'refresh',
                                child: Text('Refresh GPS Ping', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              ),
                              const PopupMenuItem(
                                value: 'copy_coords',
                                child: Text('Copy Coordinates', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'recovered',
                                child: Text('Report Recovered', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
