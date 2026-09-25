import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/map_config.dart';
import '../design/tb_theme.dart';
import '../models/asset.dart';
import '../models/recovery_report.dart';
import '../providers/asset_provider.dart';
import '../services/auth_service.dart';
import '../widgets/tb_widgets.dart';
import 'global_map_screen.dart';
import 'qr_view_screen.dart';
import 'register_belonging_screen.dart';

class AssetDetailScreen extends StatefulWidget {
  final String assetId;

  const AssetDetailScreen({
    super.key,
    required this.assetId,
  });

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  Future<void> _contactFinder(Asset asset, AssetProvider provider) async {
    final reports = provider.reportsForAsset(asset.id);
    String? finderPhone;
    String? finderName;
    if (reports.isNotEmpty) {
      final foundReport = reports.firstWhere(
        (r) => r.reportType == ReportType.found,
        orElse: () => reports.first,
      );
      finderPhone = foundReport.reporterContact;
      finderName = foundReport.reporterName;
    }

    if (finderPhone != null && finderPhone.trim().isNotEmpty) {
      final cleanPhone = finderPhone.replaceAll(RegExp(r'\D'), '');
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF141416),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: Tb.border),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Finder (${finderName ?? "Campus Peer"})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text('Contact: $finderPhone', style: const TextStyle(fontSize: 13.5, color: Tb.textSecondary)),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Tb.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        launchUrl(Uri.parse('tel:$cleanPhone'));
                      },
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: const Text('Call Finder', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Tb.borderStrong),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        launchUrl(Uri.parse('sms:$cleanPhone'));
                      },
                      icon: const Icon(Icons.message_rounded, size: 18),
                      label: const Text('Message', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            asset.finderNote?.isNotEmpty == true
                ? 'Finder Note: "${asset.finderNote}"'
                : 'Item reported found near: ${asset.foundLocation ?? asset.address}',
          ),
          backgroundColor: Tb.cardElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDelete(AssetProvider provider, Asset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141416),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Tb.border),
        ),
        title: const Text('Delete Belonging?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        content: Text('Remove ${asset.name} from your inventory?', style: const TextStyle(fontSize: 13.5, color: Tb.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Tb.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Tb.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteAsset(asset.id);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${asset.name} deleted'),
                  backgroundColor: Tb.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showRecoverySheet(BuildContext context, AssetProvider provider, Asset asset) {
    final loc = asset.foundLocation ?? asset.address;
    final foundTime = asset.foundAt != null ? DateFormat('MMM d, h:mm a').format(asset.foundAt!) : 'Recently';
    final note = asset.finderNote;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Tb.border),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Tb.warning, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Confirm Item Retrieval',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Tb.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Tb.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, color: Tb.warning, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.isNotEmpty ? loc : 'Campus Drop-off Point',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: Tb.textMuted, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          foundTime,
                          style: const TextStyle(fontSize: 12, color: Tb.textSecondary),
                        ),
                      ],
                    ),
                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Note: "$note"',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: Tb.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Once you have physically retrieved and verified your belonging, confirm recovery below to update your inventory and resolve this case.',
                style: TextStyle(fontSize: 13, color: Tb.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Tb.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await provider.confirmRecovery(asset.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${asset.name} marked as recovered!'),
                          backgroundColor: Tb.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Confirm Safe Retrieval', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final ownerName = auth.userName ?? 'Subhadeep';

    return Consumer<AssetProvider>(
      builder: (context, provider, child) {
        final asset = provider.getAssetById(widget.assetId);

        if (asset == null) {
          return Scaffold(
            backgroundColor: Tb.bg,
            appBar: AppBar(
              backgroundColor: Tb.bg,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Item Details', style: TextStyle(color: Colors.white)),
            ),
            body: const Center(
              child: Text('Item not found', style: TextStyle(color: Tb.textSecondary)),
            ),
          );
        }

        final dateFormat = DateFormat('MMM d, yyyy');
        final registeredDate = dateFormat.format(asset.createdAt);

        return Scaffold(
          backgroundColor: Tb.bg,
          appBar: AppBar(
            backgroundColor: Tb.bg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Item Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 21),
                tooltip: 'View QR Tag',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QrViewScreen(asset: asset)),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Tb.error, size: 21),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(provider, asset),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. [ ITEM OVERVIEW CARD ]
                  AnimatedCardEntrance(
                    index: 0,
                    child: _buildItemOverviewCard(asset),
                  ),

                  const SizedBox(height: 14),

                  // 2. [ TRACE STATUS CARD ]
                  AnimatedCardEntrance(
                    index: 1,
                    child: _buildTraceStatusCard(asset),
                  ),

                  const SizedBox(height: 14),

                  // 3. [ LAST DETECTED LOCATION CARD ]
                  AnimatedCardEntrance(
                    index: 2,
                    child: _buildLocationCard(context, asset),
                  ),

                  const SizedBox(height: 14),

                  // 4. [ TAG INFORMATION CARD ]
                  AnimatedCardEntrance(
                    index: 3,
                    child: _buildTagInfoCard(asset, ownerName, registeredDate),
                  ),

                  // 5. [ RECOVERY ACTIVITY CARD ] (if found or lost)
                  if (asset.isFound || asset.isLost || asset.isRecovered) ...[
                    const SizedBox(height: 14),
                    AnimatedCardEntrance(
                      index: 4,
                      child: _buildRecoveryActivityCard(context, provider, asset),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // 6. [ ACTION CARD SECTION ]
                  AnimatedCardEntrance(
                    index: 5,
                    child: _buildActionCardsSection(context, provider, asset),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── 1. ITEM OVERVIEW CARD ──────────────────────────────────────────────────
  Widget _buildItemOverviewCard(Asset asset) {
    return TracebackCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(22),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Tb.surface2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Tb.borderSubtle),
              ),
              child: Icon(asset.category.icon, size: 30, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(
              asset.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (asset.brand.isNotEmpty || asset.model.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${asset.brand} ${asset.model}'.trim(),
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Tb.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            TracebackStatusBadge(status: asset.status.name, small: false),
          ],
        ),
      ),
    );
  }

  // ── 2. TRACE STATUS CARD ───────────────────────────────────────────────────
  Widget _buildTraceStatusCard(Asset asset) {
    IconData statusIcon;
    Color statusColor;
    String headline;
    String description;

    if (asset.isLost) {
      statusIcon = Icons.warning_amber_rounded;
      statusColor = Tb.error;
      headline = 'Active Lost Alert';
      description = 'This belonging is currently flagged as missing. Campus security and nearby peers are alerted.';
    } else if (asset.isFound) {
      statusIcon = Icons.search_rounded;
      statusColor = Tb.warning;
      headline = 'Reported Located';
      description = 'A peer or security personnel reported finding this item. Review recovery notes below.';
    } else if (asset.isRecovered) {
      statusIcon = Icons.task_alt_rounded;
      statusColor = Tb.recovery;
      headline = 'Successfully Recovered';
      description = 'This belonging was retrieved and safely restored to your possession.';
    } else {
      statusIcon = Icons.shield_rounded;
      statusColor = Tb.success;
      headline = 'Safe & Monitored';
      description = 'This belonging is verified secure. Traceback digital QR protection is active.';
    }

    return TracebackCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Tb.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. LAST DETECTED LOCATION CARD ─────────────────────────────────────────
  Widget _buildLocationCard(BuildContext context, Asset asset) {
    return TracebackCard(
      borderRadius: 22,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LAST DETECTED LOCATION',
                        style: TextStyle(
                          color: Tb.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asset.address.isNotEmpty ? asset.address : 'Main Campus, Bhubaneswar',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GlobalMapScreen(initialAssetId: asset.id)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Tb.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Tb.borderSubtle),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Radar', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Embedded Dark Map
          SizedBox(
            height: 140,
            width: double.infinity,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: asset.latLng,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
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
                      point: asset.latLng,
                      width: 38,
                      height: 38,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Tb.statusColor(asset.status.name),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Tb.statusColor(asset.status.name).withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.place, color: Colors.white, size: 20),
                      ),
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

  // ── 4. TAG INFORMATION CARD ────────────────────────────────────────────────
  Widget _buildTagInfoCard(Asset asset, String ownerName, String registeredDate) {
    return TracebackCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TAG INFORMATION',
            style: TextStyle(
              color: Tb.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow('Traceback ID', asset.tracebackId, isMonospace: true, canCopy: true),
          const Divider(height: 20, color: Tb.borderSubtle),
          _buildInfoRow('Owner', ownerName),
          const Divider(height: 20, color: Tb.borderSubtle),
          _buildInfoRow('Category', asset.category.displayName),
          const Divider(height: 20, color: Tb.borderSubtle),
          _buildInfoRow('Date Registered', registeredDate),
          if (asset.serialNumber.isNotEmpty) ...[
            const Divider(height: 20, color: Tb.borderSubtle),
            _buildInfoRow('Serial Number', asset.serialNumber, isMonospace: true),
          ],
          if (asset.description.isNotEmpty) ...[
            const Divider(height: 20, color: Tb.borderSubtle),
            _buildInfoRow('Description', asset.description),
          ],
        ],
      ),
    );
  }

  // ── 5. RECOVERY ACTIVITY CARD ──────────────────────────────────────────────
  Widget _buildRecoveryActivityCard(BuildContext context, AssetProvider provider, Asset asset) {
    final note = asset.finderNote;
    final loc = asset.foundLocation ?? asset.address;

    return TracebackCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECOVERY ACTIVITY',
            style: TextStyle(
              color: Tb.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          if (asset.isFound) ...[
            Text(
              'Handover Location: $loc',
              style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Finder Note: "$note"',
                style: const TextStyle(color: Tb.textSecondary, fontSize: 12.5, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Tb.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _contactFinder(asset, provider),
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: const Text('Contact Finder', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Tb.warning,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showRecoverySheet(context, provider, asset),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Confirm Safe', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ] else if (asset.isLost) ...[
            const Text(
              'Incident broadcast to campus network. QR tag scans will trigger instant GPS pinpointing.',
              style: TextStyle(color: Tb.textSecondary, fontSize: 13, height: 1.4),
            ),
          ] else ...[
            const Text(
              'Item was safely recovered and verified.',
              style: TextStyle(color: Tb.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  // ── 6. ACTION CARDS SECTION ────────────────────────────────────────────────
  Widget _buildActionCardsSection(BuildContext context, AssetProvider provider, Asset asset) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TracebackSectionHeader(title: 'Actions'),
        const SizedBox(height: 12),

        // Action 1: Track on Radar
        TracebackActionCard(
          title: 'Track Item on Radar',
          description: 'Live campus coordinates and beacons',
          icon: Icons.map_rounded,
          iconBg: const Color(0xFF1B1B1E),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GlobalMapScreen(initialAssetId: asset.id)),
            );
          },
        ),

        const SizedBox(height: 10),

        // Action 2: Report Lost or Re-Secure
        if (!asset.isLost)
          TracebackActionCard(
            title: 'Report Lost',
            description: 'Broadcast lost item alert across campus',
            icon: Icons.warning_amber_rounded,
            iconColor: Tb.error,
            iconBg: Tb.errorDim,
            onTap: () async {
              await provider.markAsLost(asset.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${asset.name} reported lost'),
                    backgroundColor: Tb.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          )
        else
          TracebackActionCard(
            title: 'Mark as Safe',
            description: 'Item is back in your possession',
            icon: Icons.shield_rounded,
            iconColor: Tb.success,
            iconBg: Tb.successDim,
            onTap: () async {
              await provider.markAsSafe(asset.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${asset.name} marked as safe'),
                    backgroundColor: Tb.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),

        const SizedBox(height: 10),

        // Action 3: View QR Tag
        TracebackActionCard(
          title: 'View Traceback QR Tag',
          description: 'Show printable / scannable security tag',
          icon: Icons.qr_code_2_rounded,
          iconBg: const Color(0xFF1B1B1E),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QrViewScreen(asset: asset)),
            );
          },
        ),

        const SizedBox(height: 10),

        // Action 4: Edit Item
        TracebackActionCard(
          title: 'Edit Item Details',
          description: 'Update category, notes, or serial number',
          icon: Icons.edit_outlined,
          iconBg: const Color(0xFF1B1B1E),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RegisterBelongingScreen(editingAsset: asset)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMonospace = false, bool canCopy = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Tb.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontFamily: isMonospace ? 'monospace' : null,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Traceback ID copied'),
                        backgroundColor: Tb.cardElevated,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 14, color: Tb.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
