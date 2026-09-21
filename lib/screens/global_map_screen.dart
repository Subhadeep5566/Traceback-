import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../services/location_service.dart';
import 'asset_detail_screen.dart';
import 'live_trace_screen.dart';

class GlobalMapScreen extends StatefulWidget {
  final String? initialAssetId;

  const GlobalMapScreen({
    super.key,
    this.initialAssetId,
  });

  @override
  State<GlobalMapScreen> createState() => _GlobalMapScreenState();
}

class _GlobalMapScreenState extends State<GlobalMapScreen> {
  late final MapController _mapController;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedId = widget.initialAssetId;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssetProvider>(
      builder: (context, provider, child) {
        final assets = provider.myBelongings;
        if (assets.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No registered belongings yet.')),
          );
        }

        // Active tracked items or defaults
        final trackedItems = provider.activeTrackedAssets;
        final displayItems = trackedItems.isNotEmpty ? trackedItems : assets;

        // Select first item if not set
        _selectedId ??= displayItems.first.id;
        final currentAsset = assets.cast<Asset?>().firstWhere(
              (a) => a?.id == _selectedId,
              orElse: () => displayItems.first,
            )!;

        final targetCenter = currentAsset.latLng;
        final timeAgo = LocationService.formatTimeAgo(currentAsset.lastLocationUpdatedAt);

        Color stateColor = const Color(0xFF10B981);
        if (currentAsset.isLost) {
          stateColor = const Color(0xFFEF4444);
        } else if (currentAsset.isFound) {
          stateColor = const Color(0xFFF59E0B);
        } else if (currentAsset.isRecovered) {
          stateColor = const Color(0xFF0EA5E9);
        }

        return Scaffold(
          body: Stack(
            children: [
              // Full Screen Map
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: targetCenter,
                    initialZoom: 15.5,
                    minZoom: 11.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.traceback.app',
                    ),

                    // Accuracy circle for selected asset
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: currentAsset.latLng,
                          radius: (currentAsset.locationAccuracy * 2.0).clamp(16.0, 60.0),
                          useRadiusInMeter: false,
                          color: stateColor.withOpacity(0.18),
                          borderColor: stateColor.withOpacity(0.5),
                          borderStrokeWidth: 1.5,
                        ),
                      ],
                    ),

                    // Markers for user's tracked belongings
                    MarkerLayer(
                      markers: displayItems.map((asset) {
                        final isSelected = asset.id == currentAsset.id;
                        final color = asset.isLost
                            ? const Color(0xFFEF4444)
                            : (asset.isFound ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

                        return Marker(
                          point: asset.latLng,
                          width: isSelected ? 54 : 42,
                          height: isSelected ? 54 : 42,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedId = asset.id);
                              _mapController.move(asset.latLng, 16.0);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                                border: Border.all(
                                  color: color,
                                  width: isSelected ? 3.5 : 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: isSelected ? 10 : 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  asset.category.icon,
                                  size: isSelected ? 22 : 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Top Bar with Compact Belonging Selectors (Section 23)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // Screen Title Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.radar_rounded, size: 16, color: Colors.black),
                          const SizedBox(width: 6),
                          const Text(
                            'CAMPUS ASSET RADAR',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${displayItems.length} Tracked',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Compact Selectors Row (Campus Bike, Laptop, Phone...)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: displayItems.map((asset) {
                          final isSelected = asset.id == currentAsset.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() => _selectedId = asset.id);
                                _mapController.move(asset.latLng, 16.0);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.black : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      asset.category.icon,
                                      size: 14,
                                      color: isSelected ? Colors.white : Colors.black,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      asset.name,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: asset.status.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Recenter Button
              Positioned(
                right: 16,
                bottom: 210,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.my_location_rounded, color: Colors.black, size: 20),
                    tooltip: 'Center on selected item',
                    onPressed: () => _mapController.move(targetCenter, 16.0),
                  ),
                ),
              ),

              // Bottom Info Card for Selected Asset
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentAsset.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${currentAsset.tracebackId} • $timeAgo • ${currentAsset.address}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: stateColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: stateColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              currentAsset.status.displayName.toUpperCase(),
                              style: TextStyle(
                                color: stateColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AssetDetailScreen(assetId: currentAsset.id),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Item Details',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LiveTraceScreen(assetId: currentAsset.id),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Live Trace',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
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
