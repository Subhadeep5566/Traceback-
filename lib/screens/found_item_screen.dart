import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/asset.dart';
import '../models/user_profile.dart';
import '../providers/asset_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'map_location_picker_screen.dart';

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
  final TextEditingController _locationController = TextEditingController(text: 'Campus Security / Reception');
  final TextEditingController _noteController = TextEditingController();

  Asset? _matchedAsset;
  UserProfile? _ownerProfile;
  bool _hasSearched = false;
  bool _isSearching = false;
  bool _isSubmitting = false;
  bool _reportSuccess = false;
  bool _isDetectingLocation = false;
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
          SnackBar(content: Text('Phone dialer not available for $phone')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Owner phone: $phone')),
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
          SnackBar(content: Text('Messaging app not available for $phone')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Owner phone: $phone')),
        );
      }
    }
  }

  Future<void> _contactOwner(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Found%20Your%20Item%20on%20Traceback');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Owner email: $email')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Owner email: $email')),
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
      _isSearching = true;
      _hasSearched = false;
      _reportSuccess = false;
      _ownerProfile = null;
    });

    final provider = context.read<AssetProvider>();
    final found = await provider.lookupByTracebackIdRemote(query);

    UserProfile? profile;
    if (found != null && found.ownerId.isNotEmpty) {
      try {
        final firestoreService = FirestoreService();
        profile = await firestoreService.getUserProfile(found.ownerId);
      } catch (e) {
        debugPrint('Error loading owner profile: $e');
      }
    }

    if (mounted) {
      setState(() {
        _matchedAsset = found;
        _ownerProfile = profile;
        _hasSearched = true;
        _isSearching = false;
      });
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final loc = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _latitude = loc.latitude;
          _longitude = loc.longitude;
          _locationController.text = loc.address;
          _isDetectingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _pickOnMap() async {
    final initialPos = (_latitude != null && _longitude != null)
        ? ll.LatLng(_latitude!, _longitude!)
        : const ll.LatLng(
            LocationService.bhubaneswarLatitude,
            LocationService.bhubaneswarLongitude,
          );

    final result = await Navigator.push<MapLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          initialPosition: initialPos,
          title: 'Select Drop-off Location',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationController.text = result.address;
      });
    }
  }

  Future<void> _submitFoundReport() async {
    if (_matchedAsset == null) return;
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify where the item was found / handed over'),
          behavior: SnackBarBehavior.floating,
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
          // Refresh matched asset with updated status
          _matchedAsset = provider.getAssetById(_matchedAsset!.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Owner notified! Item secured at $location.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: const Text(
              'Found an Item',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Input Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ENTER TRACEBACK TAG ID',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                textCapitalization: TextCapitalization.characters,
                                onSubmitted: (_) => _performSearch(),
                                decoration: InputDecoration(
                                  hintText: 'e.g. TB-LAPTOP-002',
                                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.black, size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF1F5F9),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isSearching ? null : _performSearch,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                ),
                                child: _isSearching
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text(
                                        'Search',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        Selector<AssetProvider, List<String>>(
                          selector: (_, p) => p.allAssets.take(4).map((a) => a.tracebackId).toList(),
                          builder: (context, quickTags, _) {
                            if (quickTags.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 14),
                                const Text(
                                  'Quick test tags:',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: quickTags.map((tagId) {
                                    return InkWell(
                                      onTap: () {
                                        _searchController.text = tagId;
                                        _performSearch();
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          tagId,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search Results Area
                  if (_hasSearched) ...[
                    if (_matchedAsset == null)
                      // Compact "No item found" state
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_off_rounded,
                                color: Color(0xFF94A3B8),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No item found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'No registered belonging matches this Traceback ID.\nPlease check the tag and try again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Item Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _matchedAsset!.isLost
                                ? const Color(0xFFFECDD3)
                                : const Color(0xFFE2E8F0),
                            width: _matchedAsset!.isLost ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Possible Match Header Banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'POSSIBLE MATCH',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(_matchedAsset!.category.icon, size: 26, color: Colors.black),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _matchedAsset!.name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                      if (_matchedAsset!.brand.isNotEmpty || _matchedAsset!.model.isNotEmpty)
                                        Text(
                                          '${_matchedAsset!.brand} ${_matchedAsset!.model}'.trim(),
                                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                        ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _matchedAsset!.tracebackId,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusPill(_matchedAsset!),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Privacy & Owner Contact Information Card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.contact_phone_outlined, size: 15, color: Color(0xFF0F172A)),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'OWNER CONTACT',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (_ownerProfile != null && _ownerProfile!.phone.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF10B981)),
                                        const SizedBox(width: 6),
                                        Text(
                                          _ownerProfile!.phone,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _makeCall(_ownerProfile!.phone),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF10B981),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            icon: const Icon(Icons.call_rounded, size: 15),
                                            label: const Text('Call Owner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _sendSms(_ownerProfile!.phone),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.black,
                                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            icon: const Icon(Icons.sms_rounded, size: 15),
                                            label: const Text('Send Message', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else if (_ownerProfile != null && _ownerProfile!.email.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        const Icon(Icons.email_outlined, size: 14, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 6),
                                        Text(
                                          _ownerProfile!.email,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _contactOwner(_ownerProfile!.email),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.mail_outline_rounded, size: 15),
                                        label: const Text('Contact Owner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                      ),
                                    ),
                                  ] else ...[
                                    const Text(
                                      'Owner details secured. Submit the drop-off location below to notify the owner.',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Safe Report / Contact Section
                      if (!_reportSuccess)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SAFE FOUND REPORT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Report where the item was found or handed over so the owner can recover it safely.',
                                style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _locationController,
                                decoration: InputDecoration(
                                  labelText: 'Drop-off / Handover Location *',
                                  hintText: 'e.g. Main Gate Security, Room 204',
                                  prefixIcon: const Icon(Icons.place_outlined, size: 20),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: _isDetectingLocation
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Icon(Icons.my_location_rounded, size: 20, color: Colors.black),
                                        onPressed: _isDetectingLocation ? null : _detectLocation,
                                        tooltip: 'Use current GPS location',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.map_rounded, size: 20, color: Color(0xFF0284C7)),
                                        onPressed: _pickOnMap,
                                        tooltip: 'Select on Google Map',
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _isDetectingLocation ? null : _detectLocation,
                                    icon: const Icon(Icons.my_location_rounded, size: 14),
                                    label: const Text('Current GPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: _pickOnMap,
                                    icon: const Icon(Icons.map_rounded, size: 14),
                                    label: const Text('Select on Map', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0284C7),
                                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                                      backgroundColor: const Color(0xFFF0F9FF),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _noteController,
                                decoration: InputDecoration(
                                  labelText: 'Optional Note for Owner',
                                  hintText: 'e.g. Left with security guard Ramesh',
                                  prefixIcon: const Icon(Icons.note_outlined, size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : _submitFoundReport,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.send_rounded, size: 18),
                                  label: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text(
                                          'Notify Owner Safely',
                                          style: TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Thank you! The item report has been logged and the owner notified.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
  }

  Widget _buildStatusPill(Asset asset) {
    Color color = const Color(0xFF10B981);
    String label = 'Safe';

    if (asset.isLost) {
      color = const Color(0xFFEF4444);
      label = 'Lost';
    } else if (asset.isFound) {
      color = const Color(0xFFF59E0B);
      label = 'Found';
    } else if (asset.isRecovered) {
      color = const Color(0xFF0284C7);
      label = 'Recovered';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}