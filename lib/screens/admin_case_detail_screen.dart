import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../models/incident.dart';
import '../models/recovery_report.dart';
import '../models/user_profile.dart';
import '../providers/asset_provider.dart';
import '../services/auth_service.dart';
import '../widgets/contact_card.dart';
import 'live_trace_screen.dart';

class AdminCaseDetailScreen extends StatefulWidget {
  final String assetId;

  const AdminCaseDetailScreen({
    super.key,
    required this.assetId,
  });

  @override
  State<AdminCaseDetailScreen> createState() => _AdminCaseDetailScreenState();
}

class _AdminCaseDetailScreenState extends State<AdminCaseDetailScreen> {
  void _showMarkFoundDialog(BuildContext context, Asset asset, UserProfile adminProfile) {
    final locationController = TextEditingController(text: 'Campus Security Desk, Admin Block');
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Report Asset Secured', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record that ${asset.name} (${asset.tracebackId}) has been secured by staff. The registered owner will be immediately notified.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: 'Holding Location / Desk',
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Condition / Handover Notes',
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final provider = Provider.of<AssetProvider>(context, listen: false);
              await provider.adminReportFound(
                identifier: asset.id,
                location: locationController.text.trim(),
                notes: noteController.text.trim(),
                adminProfile: adminProfile,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item marked as Found. Student owner notified.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Submit Found Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showRecordRecoveryDialog(BuildContext context, Asset asset, UserProfile adminProfile) {
    final noteController = TextEditingController(text: 'Identity verified with Student ID card. Handover complete.');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.task_alt_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Confirm Handover', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm that ${asset.name} (${asset.tracebackId}) has been handed over to the verified student owner.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Handover Verification Notes',
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final provider = Provider.of<AssetProvider>(context, listen: false);
              await provider.adminRecordRecovery(
                asset.id,
                handoverNotes: noteController.text.trim(),
                adminProfile: adminProfile,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recovery confirmed & recorded in official audit log.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Record Handover', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, Asset asset, UserProfile adminProfile) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Case Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add an internal campus security observation or update to this recovery case.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. CCTV checked at Hostel 4 entrance...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isEmpty) return;
              Navigator.pop(dialogCtx);
              final provider = Provider.of<AssetProvider>(context, listen: false);
              await provider.updateCaseStatus(
                asset.id,
                newStatus: asset.isFound ? 'Found' : 'Investigating',
                note: noteController.text.trim(),
                actorRole: UserRole.admin,
                actorName: adminProfile.name,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Case note logged.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Add Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AssetProvider, AuthService>(
      builder: (context, provider, auth, child) {
        final asset = provider.getAssetById(widget.assetId);

        if (asset == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Case Not Found')),
            body: const Center(child: Text('Case could not be found.')),
          );
        }

        final adminProfile = auth.currentUserProfile;
        final incidents = provider.incidentsForAsset(asset.id);
        final reports = provider.reportsForAsset(asset.id);
        final statusColor = asset.status.color;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CASE: ${asset.tracebackId}',
                  style: const TextStyle(color: Colors.black, fontSize: 14.5, fontWeight: FontWeight.w900),
                ),
                Text(
                  asset.name,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    asset.status.displayName.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFE2E8F0), height: 1),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Asset Overview Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(asset.category.icon, color: statusColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  asset.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${asset.category.displayName} • ${asset.brand} ${asset.model}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Last Location: ${asset.address}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      if (asset.trackingEnabled) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LiveTraceScreen(assetId: asset.id)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.radar_rounded, size: 14, color: Color(0xFF059669)),
                                SizedBox(width: 8),
                                Text(
                                  'Live GPS Telemetry Active • View Radar Map',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                                ),
                                Spacer(),
                                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF059669)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Verified Student Owner Contact Card
                const Text(
                  'REGISTERED OWNER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                ContactCard.owner(
                  name: 'Subhadeep',
                  email: 'subhadeep@bgu.ac.in',
                  phone: '9876543210',
                  studentId: 'BGU-2024-BTECH-042',
                  department: 'School of Computer Science',
                ),
                const SizedBox(height: 24),

                // 3. Reports Associated With This Case
                if (reports.isNotEmpty) ...[
                  const Text(
                    'OFFICIAL INCIDENT REPORTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...reports.map((rep) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: rep.reportType == ReportType.found
                                            ? const Color(0xFFFEF3C7)
                                            : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        rep.reportType.displayName,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: rep.reportType == ReportType.found
                                              ? const Color(0xFFB45309)
                                              : const Color(0xFFB91C1C),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'By: ${rep.reporterName} (${rep.reporterRole.displayName})',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                Text(
                                  DateFormat('dd MMM, hh:mm a').format(rep.timestamp),
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              rep.description,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    rep.location,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // 4. Chronological Case Audit Timeline
                const Text(
                  'CASE TIMELINE & AUDIT LOG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      for (final inc in incidents)
                        for (int i = 0; i < inc.timeline.length; i++) ...[
                          _buildTimelineTile(inc.timeline[i], i == inc.timeline.length - 1),
                        ],
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 5. Admin Action Buttons
                if (asset.isLost || asset.isFound) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddNoteDialog(context, asset, adminProfile),
                          icon: const Icon(Icons.note_add_outlined, size: 16),
                          label: const Text('Add Note', style: TextStyle(fontWeight: FontWeight.w800)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (asset.isLost) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showMarkFoundDialog(context, asset, adminProfile),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                            label: const Text('Mark Found', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ] else if (asset.isFound) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showRecordRecoveryDialog(context, asset, adminProfile),
                            icon: const Icon(Icons.handshake_outlined, size: 16, color: Colors.white),
                            label: const Text('Confirm Handover', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else if (asset.isRecovered) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'CASE RESOLVED • HANDOVER CONFIRMED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF065F46),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineTile(IncidentTimelineStep step, bool isLast) {
    final timeStr = DateFormat('dd MMM, hh:mm a').format(step.timestamp);
    final isByAdmin = step.actorRole == UserRole.admin;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isByAdmin ? const Color(0xFF10B981) : Colors.black,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 14),
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
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  step.description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                if (step.actor != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isByAdmin ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'By ${step.actor!} (${step.actorRole.displayName})',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isByAdmin ? const Color(0xFF059669) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
