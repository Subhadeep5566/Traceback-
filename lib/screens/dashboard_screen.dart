import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import '../config/map_config.dart';
import '../design/tb_theme.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../services/auth_service.dart';
import '../widgets/tb_widgets.dart';
import 'asset_detail_screen.dart';
import 'found_item_screen.dart';
import 'global_map_screen.dart';
import 'my_belongings_screen.dart';
import 'notifications_screen.dart';
import 'qr_scanner_screen.dart';
import 'register_belonging_screen.dart';
import 'report_item_screen.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const DashboardScreen({
    super.key,
    this.onNavigateTab,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  void _goToItems(BuildContext context) {
    if (onNavigateTab != null) {
      onNavigateTab!(1);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyBelongingsScreen()),
      );
    }
  }

  void _goToMap(BuildContext context) {
    if (onNavigateTab != null) {
      onNavigateTab!(2);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GlobalMapScreen()),
      );
    }
  }

  void _goToSearch(BuildContext context) {
    if (onNavigateTab != null) {
      onNavigateTab!(3);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FoundItemScreen()),
      );
    }
  }

  void _goToProfile(BuildContext context) {
    if (onNavigateTab != null) {
      onNavigateTab!(4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.select<AuthService, String>((a) => a.userName ?? 'Subhadeep');
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: Tb.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER (Logo + Notification + Profile)
              AnimatedCardEntrance(
                index: 0,
                child: _buildTopHeader(context, userName),
              ),

              const SizedBox(height: 20),

              // 2. GREETING SECTION
              AnimatedCardEntrance(
                index: 1,
                child: _buildGreetingSection(greeting, userName),
              ),

              const SizedBox(height: 22),

              // 3. HORIZONTAL STATISTICS CAROUSEL
              AnimatedCardEntrance(
                index: 2,
                child: _buildStatisticsCarousel(context),
              ),

              const SizedBox(height: 26),

              // 4. QUICK ACTIONS SECTION
              AnimatedCardEntrance(
                index: 3,
                child: _buildQuickActionsSection(context),
              ),

              const SizedBox(height: 26),

              // 5. LIVE CAMPUS MAP CARD
              AnimatedCardEntrance(
                index: 4,
                child: _buildLiveMapCard(context),
              ),

              const SizedBox(height: 28),

              // 6. RECENT ITEMS
              AnimatedCardEntrance(
                index: 5,
                child: _buildRecentItemsSection(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Top Header ──────────────────────────────────────────────────────────
  Widget _buildTopHeader(BuildContext context, String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Tb.cardElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Tb.border),
                boxShadow: Tb.cardShadow,
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'TRACEBACK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Selector<AssetProvider, int>(
              selector: (_, p) => p.unreadNotificationCount,
              builder: (context, unreadCount, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Tb.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Tb.border),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Tb.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _goToProfile(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Tb.cardElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Tb.borderStrong),
                ),
                alignment: Alignment.center,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 2. Greeting Section ────────────────────────────────────────────────────
  Widget _buildGreetingSection(String greeting, String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $userName',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your belongings at a glance',
          style: TextStyle(
            color: Tb.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  // ── 3. Horizontal Statistics Carousel ──────────────────────────────────────
  Widget _buildStatisticsCarousel(BuildContext context) {
    return Selector<AssetProvider, (int, int, int, int)>(
      selector: (_, p) {
        final total = p.totalAssetCount;
        final lost = p.lostCount;
        final safe = p.secureCount;
        final found = p.myBelongings.where((a) => a.isFound).length;
        return (total, lost, safe, found);
      },
      builder: (context, stats, _) {
        final (total, lost, safe, found) = stats;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row(
            children: [
              TracebackStatCard(
                count: '$total',
                label: 'Registered',
                icon: Icons.inventory_2_outlined,
                countColor: Colors.white,
                accentColor: Colors.white70,
                onTap: () => _goToItems(context),
              ),
              const SizedBox(width: 12),
              TracebackStatCard(
                count: '$lost',
                label: 'Lost',
                icon: Icons.error_outline_rounded,
                countColor: Tb.error,
                accentColor: Tb.error,
                onTap: () => _goToItems(context),
              ),
              const SizedBox(width: 12),
              TracebackStatCard(
                count: '$safe',
                label: 'Safe',
                icon: Icons.check_circle_outline_rounded,
                countColor: Tb.success,
                accentColor: Tb.success,
                onTap: () => _goToItems(context),
              ),
              const SizedBox(width: 12),
              TracebackStatCard(
                count: '$found',
                label: 'Found',
                icon: Icons.search_rounded,
                countColor: Tb.warning,
                accentColor: Tb.warning,
                onTap: () => _goToItems(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 4. Quick Actions ───────────────────────────────────────────────────────
  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TracebackSectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TracebackActionCard(
                title: 'Add Item',
                description: 'Register belonging',
                icon: Icons.add_rounded,
                iconBg: const Color(0xFF1B1B1E),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterBelongingScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TracebackActionCard(
                title: 'Report Lost',
                description: 'Flag missing item',
                icon: Icons.warning_amber_rounded,
                iconColor: Tb.error,
                iconBg: Tb.errorDim,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportItemScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TracebackActionCard(
                title: 'Scan Tag',
                description: 'Scan Traceback tag',
                icon: Icons.qr_code_scanner_rounded,
                iconBg: const Color(0xFF1B1B1E),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TracebackActionCard(
                title: 'Report Found',
                description: 'Handover found item',
                icon: Icons.handshake_outlined,
                iconColor: Tb.warning,
                iconBg: Tb.warningDim,
                onTap: () => _goToSearch(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 5. Live Campus Map Card ────────────────────────────────────────────────
  Widget _buildLiveMapCard(BuildContext context) {
    const campusCenter = ll.LatLng(
      MapConfig.defaultLatitude,
      MapConfig.defaultLongitude,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TracebackSectionHeader(title: 'Live Campus Map'),
        const SizedBox(height: 12),
        TracebackCard(
          onTap: () => _goToMap(context),
          borderRadius: 24,
          padding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map Banner & Info
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Tb.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Tb.borderSubtle),
                      ),
                      child: const Icon(
                        Icons.radar_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE CAMPUS MAP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Recovery radar • Campus wide',
                            style: TextStyle(
                              color: Tb.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Tb.surface2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Embedded Dark Map Preview
              SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: const MapOptions(
                        initialCenter: campusCenter,
                        initialZoom: 14.2,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: MapConfig.tileUrlTemplate,
                          userAgentPackageName: MapConfig.userAgentPackageName,
                          tileBuilder: MapConfig.darkTileBuilder,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: campusCenter,
                              width: 42,
                              height: 42,
                              child: Center(
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Tb.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Tb.accent.withOpacity(0.6),
                                        blurRadius: 12,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Gradient overlay to blend seamlessly into card
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Tb.card.withOpacity(0.55),
                                Colors.transparent,
                                Tb.card.withOpacity(0.65),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Tb.borderSubtle),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me_rounded, size: 12, color: Tb.success),
                            SizedBox(width: 5),
                            Text(
                              'Radar Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 6. Recent Belongings / Items ───────────────────────────────────────────
  Widget _buildRecentItemsSection(BuildContext context) {
    return Selector<AssetProvider, List<Asset>>(
      selector: (_, p) => p.myBelongings,
      builder: (context, belongings, _) {
        final recentItems = belongings.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TracebackSectionHeader(
              title: 'Recent Items',
              action: recentItems.isNotEmpty ? 'View all' : null,
              onAction: () => _goToItems(context),
            ),
            const SizedBox(height: 12),
            if (recentItems.isEmpty)
              TracebackCard(
                borderRadius: 22,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Tb.surface2,
                          shape: BoxShape.circle,
                          border: Border.all(color: Tb.border),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 26,
                          color: Tb.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No belongings registered yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap "Add Item" above to protect your first belonging',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Tb.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: recentItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TracebackItemCard(
                      icon: item.category.icon,
                      name: item.name,
                      tracebackId: item.tracebackId,
                      status: item.status.name,
                      location: item.address,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssetDetailScreen(assetId: item.id),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }
}