import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../services/location_service.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.initialTagId != null && widget.initialTagId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openManualEntrySheet(initialValue: widget.initialTagId);
      });
    }
  }

  void _openManualEntrySheet({String? initialValue}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualTagEntrySheet(
        initialValue: initialValue,
        onAssetFound: (asset) {
          Navigator.pop(ctx);
          _openReportFoundSheet(asset);
        },
      ),
    );
  }

  void _openReportFoundSheet(Asset asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReportFoundSheet(asset: asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'SCAN TRACEBACK TAG',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_rounded, color: Colors.white70, size: 22),
            tooltip: 'Enter ID manually',
            onPressed: () => _openManualEntrySheet(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Camera Area with centered scanning reticle
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Viewfinder Box
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Corner markers
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.white, width: 3),
                                    left: BorderSide(color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 14,
                              right: 14,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.white, width: 3),
                                    right: BorderSide(color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 14,
                              left: 14,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.white, width: 3),
                                    left: BorderSide(color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 14,
                              right: 14,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.white, width: 3),
                                    right: BorderSide(color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                            ),

                            // Scanning icon
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 72,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Centered labels per spec
                      const Text(
                        'Scan Traceback Tag',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan the QR code attached to a registered item.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // OR divider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 32, height: 1, color: Colors.white24),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Container(width: 32, height: 1, color: Colors.white24),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // [ Enter Traceback ID ] button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            backgroundColor: Colors.white.withOpacity(0.08),
                          ),
                          onPressed: () => _openManualEntrySheet(),
                          icon: const Icon(Icons.tag_rounded, size: 18),
                          label: const Text(
                            'Enter Traceback ID',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet 1: Enter Traceback ID
// ---------------------------------------------------------------------------
class _ManualTagEntrySheet extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<Asset> onAssetFound;

  const _ManualTagEntrySheet({
    this.initialValue,
    required this.onAssetFound,
  });

  @override
  State<_ManualTagEntrySheet> createState() => _ManualTagEntrySheetState();
}

class _ManualTagEntrySheetState extends State<_ManualTagEntrySheet> {
  late final TextEditingController _controller;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _lookup() {
    final raw = _controller.text.trim().toUpperCase();
    if (raw.isEmpty) return;

    final clean = raw.replaceAll('TRACEBACK://ITEM/', '').trim();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<AssetProvider>();
    final asset = provider.allAssets.cast<Asset?>().firstWhere(
          (a) =>
              a?.tracebackId.toUpperCase() == clean ||
              a?.id.toUpperCase() == clean ||
              a?.identifier.toUpperCase() == clean,
          orElse: () => null,
        );

    setState(() => _isLoading = false);

    if (asset != null) {
      widget.onAssetFound(asset);
    } else {
      setState(() {
        _error = 'No belonging found with ID "$clean"';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final provider = context.watch<AssetProvider>();

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: bottomInset + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Enter Traceback ID',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Type the ID printed on the belonging or its QR tag.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g. TB-BIKE-001',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _controller.clear()),
                    )
                  : null,
            ),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _lookup(),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFE11D48), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],

          // Quick presets
          if (provider.allAssets.isNotEmpty) ...[
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: provider.allAssets.take(4).map((a) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      label: Text(
                        a.tracebackId,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onPressed: () {
                        _controller.text = a.tracebackId;
                        _lookup();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // [ Continue ]
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _lookup,
              child: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Continue', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet 2: Found Belonging Report
// ---------------------------------------------------------------------------
class _ReportFoundSheet extends StatefulWidget {
  final Asset asset;

  const _ReportFoundSheet({required this.asset});

  @override
  State<_ReportFoundSheet> createState() => _ReportFoundSheetState();
}

class _ReportFoundSheetState extends State<_ReportFoundSheet> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController(text: 'BGU Campus, Bhubaneswar');
  final _noteController = TextEditingController();
  bool _isDetectingLocation = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final loc = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _locationController.text = loc.address;
          _isDetectingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<AssetProvider>();
      await provider.reportFound(
        assetId: widget.asset.id,
        foundLocation: _locationController.text.trim(),
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      if (mounted) {
        Navigator.pop(context); // Close sheet
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFFE11D48)),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Report Submitted', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Text(
          'The owner of ${widget.asset.name} has been securely notified of the found location.',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: bottomInset + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Item summary row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.asset.category.icon, size: 20, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.asset.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.asset.tracebackId} • ${widget.asset.status.displayName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.asset.status.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14),

            // Found location
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FOUND LOCATION *',
                  style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: _isDetectingLocation ? null : _detectLocation,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  child: Text(
                    _isDetectingLocation ? 'Detecting...' : 'Use Current Location',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'e.g. BGU Library 2nd floor',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter location' : null,
            ),
            const SizedBox(height: 12),

            // Note
            const Text(
              'NOTE (OPTIONAL)',
              style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Left with campus security guard',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 20),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Report Found & Notify Owner',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}