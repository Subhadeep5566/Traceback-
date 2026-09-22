import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../models/recovery_report.dart';
import '../models/user_profile.dart';
import '../providers/asset_provider.dart';
import '../services/auth_service.dart';
import 'admin_case_detail_screen.dart';
import 'admin_cases_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const AdminDashboardScreen({
    super.key,
    this.onNavigateTab,
  });

  void _showAdminReportFoundDialog(BuildContext context, UserProfile adminProfile) {
    final idController = TextEditingController();
    final locationController = TextEditingController(text: 'Campus Security Desk, Administrative Block');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.black),
            SizedBox(width: 8),
            Text('Admin Report Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter or scan the asset Traceback ID (e.g. TB-BIKE-001) to log an item secured by staff.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: idController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Traceback ID',
                  hintText: 'e.g. TB-BIKE-001',
                  prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Holding Location / Desk',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Condition / Secure Notes',
                  hintText: 'e.g. Found at canteen entrance...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = idController.text.trim();
              if (id.isEmpty) return;
              Navigator.pop(dialogCtx);
              final provider = Provider.of<AssetProvider>(context, listen: false);
              try {
                await provider.adminReportFound(
                  identifier: id,
                  location: locationController.text.trim(),
                  notes: notesController.text.trim(),
                  adminProfile: adminProfile,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Item $id logged as FOUND. Owner notified!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log Found Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showReportOnBehalfDialog(BuildContext context, UserProfile adminProfile, List<Asset> assets) {
    if (assets.isEmpty) return;
    Asset selectedAsset = assets.first;
    ReportType reportType = ReportType.lost;
    final locationController = TextEditingController(text: 'Campus');
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Report on Behalf of User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select the belonging to report lost or stolen.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<Asset>(
                  value: selectedAsset,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Select Registered Asset',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: assets.map((a) {
                    return DropdownMenuItem<Asset>(
                      value: a,
                      child: Text('${a.name} (${a.tracebackId})', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedAsset = val);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ReportType>(
                  value: reportType,
                  decoration: InputDecoration(
                    labelText: 'Incident Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: ReportType.lost, child: Text('LOST (Misplaced)')),
                    DropdownMenuItem(value: ReportType.stolen, child: Text('STOLEN (Suspected Theft)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => reportType = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'Last Known Location',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Incident Notes / Description',
                    hintText: 'e.g. Student reported at security office...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
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
                await provider.adminReportOnBehalf(
                  assetId: selectedAsset.id,
                  reportType: reportType,
                  location: locationController.text.trim(),
                  notes: noteController.text.trim(),
                  adminProfile: adminProfile,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Report filed on behalf of student. Item is now ${reportType.displayName}.'),
                      backgroundColor: Colors.black,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('File Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AssetProvider, AuthService>(
      builder: (context, provider, auth, child) {
        final adminProfile = auth.currentUserProfile;
        final activeCases = provider.activeCases;
        final recentReports = provider.allReports.take(4).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'TRACEBACK ADMIN DESK',
                                style: TextStyle(
                                  color: Color(0xFF0284C7),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            adminProfile.name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                           label: 'ACTIVE CASES',
                          count: provider.activeCases.length,
                          color: const Color(0xFFEF4444),
                          bg: const Color(0xFFFEF2F2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'FOUND ITEMS',
                          count: provider.foundCount,
                          color: const Color(0xFFF59E0B),
                          bg: const Color(0xFFFFFBEB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          label: 'LOST ITEMS',
                          count: provider.lostCount,
                          color: const Color(0xFFDC2626),
                          bg: const Color(0xFFFEF2F2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'RECOVERED',
                          count: provider.resolvedCount,
                          color: const Color(0xFF10B981),
                          bg: const Color(0xFFECFDF5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAdminReportFoundDialog(context, adminProfile),
                          icon: const Icon(Icons.add_task_rounded, size: 16, color: Colors.white),
                          label: const Text('Report Found', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 12.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showReportOnBehalfDialog(context, adminProfile, provider.allAssets),
                          icon: const Icon(Icons.person_search_rounded, size: 16, color: Colors.black),
                          label: const Text('File for User', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 12.5)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Active Recovery Cases Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ACTIVE RECOVERY CASES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (onNavigateTab != null) {
                            onNavigateTab!(1); // Go to Cases Tab
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCasesScreen()));
                          }
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (activeCases.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'No active recovery cases. All campus belongings secure.',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    ...activeCases.take(3).map((asset) => _buildActiveCaseCard(context, asset)),

                  const SizedBox(height: 24),

                  // Recent Reports Section
                  const Text(
                    'RECENT INCIDENT REPORTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (recentReports.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'No reports recorded yet.',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    )
                  else
                    ...recentReports.map((report) => _buildRecentReportTile(context, report)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String label,
    required int count,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count.toString(),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: color.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCaseCard(BuildContext context, Asset asset) {
    final statusColor = asset.status.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE RECOVERY',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: statusColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '● ${asset.status.displayName.toUpperCase()}',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(asset.category.icon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                    Text(
                      '${asset.tracebackId} • Student: Subhadeep',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Last location: ${asset.address}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminCaseDetailScreen(assetId: asset.id)),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'View Case',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportTile(BuildContext context, RecoveryReport report) {
    final isFound = report.reportType == ReportType.found;
    final badgeColor = isFound ? const Color(0xFFD97706) : const Color(0xFFDC2626);
    final badgeBg = isFound ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              report.reportType.displayName,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: badgeColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${report.tracebackId} • ${report.reporterName} (${report.reporterRole.displayName})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                ),
                Text(
                  'Near ${report.location}',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            DateFormat('hh:mm a').format(report.timestamp),
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
