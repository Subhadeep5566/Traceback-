import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/asset.dart';

class SimulatedMapWidget extends StatefulWidget {
  final List<Asset> assets;
  final Asset? selectedAsset;
  final ValueChanged<Asset>? onAssetSelected;
  final double height;
  final bool isInteractive;
  final bool showBreadcrumbs;

  const SimulatedMapWidget({
    super.key,
    required this.assets,
    this.selectedAsset,
    this.onAssetSelected,
    this.height = 240,
    this.isInteractive = true,
    this.showBreadcrumbs = true,
  });

  @override
  State<SimulatedMapWidget> createState() => _SimulatedMapWidgetState();
}

class _SimulatedMapWidgetState extends State<SimulatedMapWidget> with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  static const LatLng _bguCenter = LatLng(20.2982, 85.7434);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant SimulatedMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Smoothly pan to the newly selected asset if changed
    if (widget.selectedAsset != null &&
        widget.selectedAsset?.id != oldWidget.selectedAsset?.id) {
      _mapController.move(widget.selectedAsset!.latLng, 15.5);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final centerPos = widget.selectedAsset?.latLng ?? _bguCenter;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Offline-ready Campus Schematic Blueprint Canvas
          Positioned.fill(
            child: CustomPaint(
              painter: CampusMapPainter(),
            ),
          ),

          // 1. Real-world Interactive FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPos,
              initialZoom: 15.0,
              minZoom: 11.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: widget.isInteractive ? InteractiveFlag.all : InteractiveFlag.none,
              ),
            ),
            children: [
              // Standard OpenStreetMap tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.traceback.app',
              ),

              // 2. Breadcrumb Trail / Trajectory Polyline
              if (widget.showBreadcrumbs)
                PolylineLayer(
                  polylines: _buildPolylines(),
                ),

              // 3. Real-life Asset Markers
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),

          // 4. Top Overlay: Minimalist Location Badge
          Positioned(
            top: 12,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF38BDF8)),
                      SizedBox(width: 6),
                      Text(
                        'Bhubaneswar • BGU Campus & Gothapatna',
                        style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(
                    '${widget.assets.length} Assets',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Bottom Overlay: Coordinates Badge & Zoom Controls
          Positioned(
            bottom: 10,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Text(
                    widget.selectedAsset != null
                        ? '${widget.selectedAsset!.latitude.toStringAsFixed(4)}° N, ${widget.selectedAsset!.longitude.toStringAsFixed(4)}° E'
                        : '20.2982° N, 85.7434° E',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.isInteractive)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMapIconButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Recenter on BGU Campus',
                        onTap: () {
                          _mapController.move(centerPos, 15.0);
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildMapIconButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Zoom In',
                        onTap: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildMapIconButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Zoom Out',
                        onTap: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.92),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];

    for (final asset in widget.assets) {
      if (asset.locationHistory.length > 1) {
        final points = asset.locationHistory.map((p) => p.latLng).toList();
        final isStolen = asset.status == AssetStatus.stolen;

        polylines.add(
          Polyline(
            points: points,
            strokeWidth: isStolen ? 3.5 : 2.0,
            color: isStolen ? const Color(0xFFEF4444) : const Color(0xFF38BDF8).withOpacity(0.7),
            borderColor: Colors.black.withOpacity(0.5),
            borderStrokeWidth: 1.0,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        );
      }
    }

    return polylines;
  }

  List<Marker> _buildMarkers() {
    return widget.assets.map((asset) {
      final isStolen = asset.status == AssetStatus.stolen;
      final isSelected = widget.selectedAsset?.id == asset.id;

      return Marker(
        point: asset.latLng,
        width: 100,
        height: 70,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {
            widget.onAssetSelected?.call(asset);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Asset Name Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isStolen
                        ? const Color(0xFFEF4444)
                        : (isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  asset.name.split(' ').first,
                  style: TextStyle(
                    color: isStolen
                        ? const Color(0xFFFCA5A5)
                        : (isSelected ? const Color(0xFF38BDF8) : const Color(0xFFE2E8F0)),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 3),

              // Pin Marker with animated pulse for stolen asset
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isStolen)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final currentRadius = 16.0 + (_pulseController.value * 14.0);
                        final pulseOpacity = (1.0 - _pulseController.value).clamp(0.0, 0.7);

                        return Container(
                          width: currentRadius * 2,
                          height: currentRadius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEF4444).withOpacity(pulseOpacity * 0.4),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(pulseOpacity),
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    ),

                  // Pin Core Circle
                  Container(
                    width: isSelected ? 26 : 22,
                    height: isSelected ? 26 : 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: asset.status.color,
                      border: Border.all(color: Colors.white, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: asset.status.color.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        asset.category.icon,
                        size: isSelected ? 13 : 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class CampusMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final roadPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    // Campus Main Loop
    canvas.drawLine(Offset(size.width * 0.1, size.height * 0.5), Offset(size.width * 0.9, size.height * 0.5), roadPaint);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.1), Offset(size.width * 0.5, size.height * 0.9), roadPaint);

    // Campus building blocks
    final buildingPaint = Paint()..color = const Color(0xFF1E293B);
    final buildingBorder = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final r1 = RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.2, size.height * 0.25, 70, 45), const Radius.circular(8));
    final r2 = RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.65, size.height * 0.22, 80, 50), const Radius.circular(8));
    final r3 = RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.45, size.height * 0.65, 85, 45), const Radius.circular(8));

    for (final r in [r1, r2, r3]) {
      canvas.drawRRect(r, buildingPaint);
      canvas.drawRRect(r, buildingBorder);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
