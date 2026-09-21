import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../models/incident.dart';
import '../models/user_profile.dart';
import '../providers/asset_provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../widgets/contact_card.dart';
import '../widgets/tag_details_modal.dart';
import 'live_trace_screen.dart';
import 'report_item_screen.dart';

class AssetDetailScreen extends StatelessWidget {
  final String assetId;

  const AssetDetailScreen({
    super.key,
    required this.assetId,
  });

  void _showHistorySheet(BuildContext context, List<Incident> incidents, Asset asset) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECOVERY HISTORY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    asset.tracebackId,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: _buildVerticalTimeline(incidents, asset),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, AssetProvider provider, Asset asset) {
    final nameCtrl = TextEditingController(text: asset.name);
    final brandCtrl = TextEditingController(text: asset.brand);
    final modelCtrl = TextEditingController(text: asset.model);
    final colorCtrl = TextEditingController(text: asset.color);
    final descCtrl = TextEditingController(text: asset.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Belonging', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Item Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: brandCtrl,
                decoration: const InputDecoration(labelText: 'Brand'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(labelText: 'Model'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Notes / Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              provider.updateAsset(asset.copyWith(
                name: nameCtrl.text.trim(),
                brand: brandCtrl.text.trim(),
                model: modelCtrl.text.trim(),
                color: colorCtrl.text.trim(),
                description: descCtrl.text.trim(),
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Belonging details updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AssetProvider provider, Asset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unregister Belonging', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to remove "${asset.name}" (${asset.tracebackId}) from Traceback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Go back from detail screen
              provider.removeAsset(asset.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Belonging removed from personal inventory')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmRecoveryDialog(BuildContext context, AssetProvider provider, Asset asset) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Confirm Recovery', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text('Confirm that you have physically retrieved "${asset.name}"? Active tracking will be terminated.'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item marked as Recovered! Trace terminated.')),
              );
            },
            child: const Text('Confirm Recovered', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssetProvider>(
      builder: (context, provider, child) {
        final Asset? asset = provider.allAssets.cast<Asset?>().firstWhere(
              (a) => a?.id == assetId,
              orElse: () => null,
            );

        if (asset == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(elevation: 0, backgroundColor: Colors.white),
            body: const Center(
              child: Text('This belonging could not be found.', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          );
        }

        final incidents = provider.incidentsForAsset(asset.id);
        final lastPingStr = LocationService.formatTimeAgo(asset.lastLocationUpdatedAt);

        Color statusColor = const Color(0xFF10B981);
        if (asset.isLost) {
          statusColor = const Color(0xFFEF4444);
        } else if (asset.isFound) {
          statusColor = const Color(0xFFF59E0B);
        } else if (asset.isRecovered) {
          statusColor = const Color(0xFF0284C7);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              asset.name,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            actions: [
              // Overflow Menu: Secondary Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.black, size: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  if (val == 'tag') {
                    TagDetailsModal.show(context, asset);
                  } else if (val == 'history') {
                    _showHistorySheet(context, incidents, asset);
                  } else if (val == 'desk') {
                    final auth = context.read<AuthService>();
                    final admin = auth.storageService.loadAdminConfig();
                    ContactCard.showAdminSheet(
                      context: context,
                      adminName: admin.name,
                      office: admin.office,
                      designation: admin.designation,
                      email: admin.email,
                      phone: admin.phone,
                      officeLocation: admin.officeLocation,
                    );
                  } else if (val == 'report_lost') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ReportItemScreen(initialAsset: asset, initialReason: 'Lost')),
                    );
                  } else if (val == 'report_stolen') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ReportItemScreen(initialAsset: asset, initialReason: 'Stolen')),
                    );
                  } else if (val == 'report_found') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ReportItemScreen(initialAsset: asset, initialReason: 'Found')),
                    );
                  } else if (val == 'edit') {
                    _showEditDialog(context, provider, asset);
                  } else if (val == 'delete') {
                    _showDeleteDialog(context, provider, asset);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'tag',
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 18, color: Colors.black),
                        SizedBox(width: 10),
                        Text('View Tag QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, size: 18, color: Colors.black),
                        SizedBox(width: 10),
                        Text('Recovery History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'desk',
                    child: Row(
                      children: [
                        Icon(Icons.support_agent_rounded, size: 18, color: Colors.black),
                        SizedBox(width: 10),
                        Text('Contact Recovery Desk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  if (!asset.isLost)
                    const PopupMenuItem(
                      value: 'report_lost',
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 18, color: Color(0xFFD97706)),
                          SizedBox(width: 10),
                          Text('Report Lost', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                        ],
                      ),
                    ),
                  if (!asset.isLost)
                    const PopupMenuItem(
                      value: 'report_stolen',
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFE11D48)),
                          SizedBox(width: 10),
                          Text('Report Stolen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE11D48))),
                        ],
                      ),
                    ),
                  if (asset.isLost)
                    const PopupMenuItem(
                      value: 'report_found',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF10B981)),
                          SizedBox(width: 10),
                          Text('Report Found', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: Colors.black),
                        SizedBox(width: 10),
                        Text('Edit Belonging', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 10),
                        Text('Delete Item', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFE2E8F0), height: 1),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ITEM IDENTITY
                  Text(
                    asset.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // STATUS DOT
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        asset.status.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // TRACEBACK ID (Tap to copy)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: asset.tracebackId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${asset.tracebackId} copied to clipboard'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Text(
                      asset.tracebackId,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 20),

                  // LAST KNOWN LOCATION
                  const Text(
                    'Last known location',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    asset.address,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updated $lastPingStr',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 20),

                  // TRACKING STATUS
                  const Text(
                    'Tracking',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: asset.trackingEnabled ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        asset.trackingEnabled ? 'Live' : 'Inactive',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: asset.trackingEnabled ? const Color(0xFF10B981) : const Color(0xFF64748B),
                        ),
                      ),
                      if (asset.trackingEnabled) ...[
                        const SizedBox(width: 8),
                        Text(
                          '·  ±${asset.locationAccuracy.toStringAsFixed(0)}m accuracy',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 36),

                  // ONE PRIMARY ACTION
                  _buildPrimaryActionButton(context, provider, asset),
                  const SizedBox(height: 16),

                  // History Quick Trigger
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showHistorySheet(context, incidents, asset),
                      icon: const Icon(Icons.history_rounded, size: 16, color: Color(0xFF64748B)),
                      label: const Text(
                        'View History & Timeline',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryActionButton(BuildContext context, AssetProvider provider, Asset asset) {
    if (asset.trackingEnabled) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LiveTraceScreen(assetId: asset.id)),
            );
          },
          icon: const Icon(Icons.radar_rounded, size: 18),
          label: const Text('View Live Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      );
    }

    if (asset.isLost) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () async {
            await provider.activateTrace(asset.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live trace activated!')),
              );
            }
          },
          icon: const Icon(Icons.radar_rounded, size: 18),
          label: const Text('Activate Live Trace', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      );
    }

    if (asset.isFound) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => _confirmRecoveryDialog(context, provider, asset),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
          label: const Text('Confirm Recovery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      );
    }

    if (asset.isRecovered) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            provider.markAsSafe(asset.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item marked as Secure in personal inventory')),
            );
          },
          icon: const Icon(Icons.shield_rounded, size: 18),
          label: const Text('Mark Secure', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      );
    }

    // Default Safe: Report Lost
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: Colors.black,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportItemScreen(initialAsset: asset, initialReason: 'Lost'),
            ),
          );
        },
        icon: const Icon(Icons.search_rounded, size: 18),
        label: const Text('Report Lost or Missing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      ),
    );
  }

  static Widget _buildVerticalTimeline(List<Incident> incidents, Asset asset) {
    final allSteps = <IncidentTimelineStep>[];
    for (final inc in incidents) {
      allSteps.addAll(inc.timeline);
    }
    allSteps.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (allSteps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Text('No history recorded yet.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allSteps.length,
      itemBuilder: (context, index) {
        final step = allSteps[index];
        final isLast = index == allSteps.length - 1;
        final dateStr = DateFormat('dd MMM, hh:mm a').format(step.timestamp);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == 0 ? Colors.black : const Color(0xFFE2E8F0),
                      border: Border.all(
                        color: index == 0 ? Colors.black : const Color(0xFF94A3B8),
                        width: 2,
                      ),
                    ),
                    child: index == 0
                        ? const Center(
                            child: Icon(Icons.check, size: 8, color: Colors.white),
                          )
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (step.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          step.description,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                        ),
                      ],
                      if (step.actor != null || step.actorRole == UserRole.admin) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (step.actorRole == UserRole.admin) ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (step.actorRole == UserRole.admin)
                                    ? 'BY COLLEGE ADMIN (${step.actor ?? "Staff"})'
                                    : 'BY STUDENT (${step.actor ?? "Owner"})',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  color: (step.actorRole == UserRole.admin) ? const Color(0xFF047857) : const Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
