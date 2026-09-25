import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../design/tb_theme.dart';
import '../models/asset.dart';
import '../models/user_profile.dart';
import '../providers/asset_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/tb_widgets.dart';
import 'asset_detail_screen.dart';

class FoundItemScreen extends StatefulWidget {
  final String? initialTagId;

  const FoundItemScreen({
    super.key,
    this.initialTagId,
  });

  @override
  State<FoundItemScreen> createState() => _FoundItemScreenState();
}

class _FoundItemScreenState extends State<FoundItemScreen> {
  late final TextEditingController _searchController;
  final TextEditingController _locationController =
      TextEditingController(text: 'Campus Security / Reception');
  final TextEditingController _noteController = TextEditingController();

  Asset? _matchedAsset;
  UserProfile? _ownerProfile;
  bool _isSubmitting = false;
  bool _reportSuccess = false;
  double? _latitude;
  double? _longitude;

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone dialer not available for $phone',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: TbColors.cardBackground,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Owner phone: $phone',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: TbColors.cardBackground,
          ),
        );
      }
    }
  }

  Future<void> _sendSms(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('sms:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Messaging app not available for $phone',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: TbColors.cardBackground,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Owner phone: $phone',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: TbColors.cardBackground,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialTagId ?? '');
    if (widget.initialTagId != null && widget.initialTagId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _reportSuccess = false;
      _matchedAsset = null;
      _ownerProfile = null;
    });

    final provider = context.read<AssetProvider>();
    final asset = provider.getAssetById(query);

    if (asset != null) {
      _matchedAsset = asset;
      try {
        final profile = await FirestoreService().getUserProfile(asset.ownerId);
        if (mounted) _ownerProfile = profile;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submitFoundReport() async {
    if (_matchedAsset == null) return;
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please specify where the item was found / handed over',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: TbColors.cardBackground,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: TbColors.cardBorder),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<AssetProvider>();
    final auth = context.read<AuthService>();

    try {
      await provider.reportFound(
        assetId: _matchedAsset!.id,
        foundLocation: location,
        coordinates: _latitude != null && _longitude != null
            ? ll.LatLng(_latitude!, _longitude!)
            : null,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : 'Found on campus and handed over at $location.',
        reporterName: auth.userName ?? 'Campus Finder',
        reporterContact: auth.userPhone ?? '',
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _reportSuccess = true;
          _matchedAsset = provider.getAssetById(_matchedAsset!.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Owner notified! Item secured at $location.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: TbColors.cardBackground,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0x3310B981)),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: TbColors.cardBackground,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: TbColors.cardBorder),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssetProvider>();
    final query = _searchController.text.trim().toLowerCase();

    final matchingItems = query.isEmpty
        ? provider.myBelongings
        : provider.allAssets.where((a) {
            return a.name.toLowerCase().contains(query) ||
                a.tracebackId.toLowerCase().contains(query) ||
                a.brand.toLowerCase().contains(query) ||
                a.category.displayName.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: TbColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER
              if (Navigator.canPop(context)) ...[
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: TbColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TbColors.cardBorder),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Search & Trace',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else ...[
                const Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lookup items or scan a Traceback tag ID',
                  style: TextStyle(
                    color: TbColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 2. PREMIUM SEARCH CARD
              AnimatedCardEntrance(
                delayMs: 30,
                child: TracebackCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _performSearch(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search items, tags, or categories...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: TbColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: TbColors.textMuted,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: TbColors.textMuted,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _matchedAsset = null;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // 3. TAG HANDOVER CARD (If matched tag selected)
              if (_matchedAsset != null) ...[
                AnimatedCardEntrance(
                  delayMs: 60,
                  child: _buildMatchedAssetCard(_matchedAsset!),
                ),
                const SizedBox(height: 22),
              ],

              // 4. SEARCH RESULTS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    query.isEmpty
                        ? 'ALL BELONGINGS'
                        : 'SEARCH RESULTS (${matchingItems.length})',
                    style: const TextStyle(
                      color: TbColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (matchingItems.isEmpty)
                AnimatedCardEntrance(
                  delayMs: 90,
                  child: TracebackCard(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 36,
                            color: TbColors.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No matching items found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Try searching by item name or exact Traceback ID.',
                            style: TextStyle(
                              fontSize: 12,
                              color: TbColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: matchingItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return AnimatedCardEntrance(
                      delayMs: (index * 40).clamp(0, 300),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TracebackItemCard(
                          icon: item.category.icon,
                          title: item.name,
                          tracebackId: item.tracebackId,
                          status: item.isLost
                              ? TracebackItemStatus.lost
                              : item.isFound
                                  ? TracebackItemStatus.found
                                  : TracebackItemStatus.safe,
                          location: item.address.isNotEmpty ? item.address : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AssetDetailScreen(assetId: item.id),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchedAssetCard(Asset asset) {
    return TracebackCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'EXACT TAG MATCH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF60A5FA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            asset.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${asset.category.displayName} • ${asset.tracebackId}',
            style: const TextStyle(fontSize: 12, color: TbColors.textMuted),
          ),
          const SizedBox(height: 16),
          if (_ownerProfile != null && _ownerProfile!.phone.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _makeCall(_ownerProfile!.phone),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call_rounded, size: 16, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'Call Owner',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _sendSms(_ownerProfile!.phone),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: TbColors.cardBorder),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sms_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Message',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (!_reportSuccess) ...[
            const Divider(color: TbColors.cardBorder, height: 1),
            const SizedBox(height: 14),
            const Text(
              'Handover / Found Drop-off Location',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Campus Security Desk, Room 204',
                hintStyle: const TextStyle(fontSize: 12, color: TbColors.textMuted),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: TbColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: TbColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _isSubmitting ? null : _submitFoundReport,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Notify Owner Safely',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x1A10B981),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x3310B981)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Report logged and owner notified successfully!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF34D399),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}