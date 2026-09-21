import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../services/location_service.dart';

class ReportItemScreen extends StatefulWidget {
  final Asset? initialAsset;
  final String? initialAssetId;
  final String initialReason; // 'Lost' or 'Stolen'

  const ReportItemScreen({
    super.key,
    this.initialAsset,
    this.initialAssetId,
    this.initialReason = 'Lost',
  });

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  late String _selectedReason;
  String? _selectedAssetId;
  bool _isDetectingLocation = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedReason = widget.initialReason;
    _selectedAssetId = widget.initialAsset?.id ?? widget.initialAssetId;
    _locationController.text = widget.initialAsset?.address ?? 'BGU Campus, Bhubaneswar';
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
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

  Future<void> _submitReport(AssetProvider provider) async {
    if (_selectedAssetId == null || _selectedAssetId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item to report')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await provider.reportLostOrStolen(
        assetId: _selectedAssetId!,
        reason: _selectedReason,
        locationAddress: _locationController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (mounted) {
        final asset = provider.allAssets.firstWhere((a) => a.id == _selectedAssetId);
        _showSuccessAndPromptTrace(asset);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to report: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  void _showSuccessAndPromptTrace(Asset asset) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Report Submitted',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${asset.name} has been marked as $_selectedReason.',
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 10),
            const Text(
              'Would you like to activate live GPS trace now to monitor location?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
            },
            child: const Text('Later', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final provider = context.read<AssetProvider>();
              await provider.activateTrace(asset.id);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('ACTIVATE TRACE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssetProvider>();
    final assets = provider.allAssets;

    final targetAsset = widget.initialAsset ??
        (_selectedAssetId != null
            ? assets.cast<Asset?>().firstWhere((a) => a?.id == _selectedAssetId, orElse: () => null)
            : null);

    final itemTitle = targetAsset != null ? targetAsset.name : 'Belonging';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'REPORT ITEM',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean header per spec: "Report Bike"
                Text(
                  'Report $itemTitle',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                if (targetAsset != null)
                  Text(
                    '${targetAsset.tracebackId} • ${targetAsset.brand} ${targetAsset.model}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  )
                else
                  const Text(
                    'Select the belonging you need to report.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),

                if (widget.initialAsset == null) ...[
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: _selectedAssetId,
                    decoration: InputDecoration(
                      hintText: 'Choose a registered belonging',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    items: assets.map((a) {
                      return DropdownMenuItem<String>(
                        value: a.id,
                        child: Text('${a.name} (${a.tracebackId})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedAssetId = val;
                        final found = assets.firstWhere((a) => a.id == val);
                        _locationController.text = found.address;
                      });
                    },
                  ),
                ],

                const SizedBox(height: 28),

                // Focused Radio Options: ○ Lost / ○ Stolen
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedReason = 'Lost'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _selectedReason == 'Lost' ? Colors.black : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedReason == 'Lost' ? Colors.black : const Color(0xFFE2E8F0),
                              width: _selectedReason == 'Lost' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedReason == 'Lost' ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: _selectedReason == 'Lost' ? Colors.white : const Color(0xFF94A3B8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Lost',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedReason == 'Lost' ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedReason = 'Stolen'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _selectedReason == 'Stolen' ? const Color(0xFFEF4444) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedReason == 'Stolen' ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                              width: _selectedReason == 'Stolen' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedReason == 'Stolen' ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: _selectedReason == 'Stolen' ? Colors.white : const Color(0xFF94A3B8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Stolen',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedReason == 'Stolen' ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Last known location
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LAST KNOWN LOCATION',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    TextButton(
                      onPressed: _isDetectingLocation ? null : _useCurrentLocation,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                      child: Text(
                        _isDetectingLocation ? 'Detecting...' : 'Use Current Location',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'e.g. BGU Library, Cycle Stand',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter last known location' : null,
                ),
                const SizedBox(height: 20),

                // Additional note (optional)
                const Text(
                  'ADDITIONAL NOTE (OPTIONAL)',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Any details or circumstances to help security...',
                    hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
                const SizedBox(height: 32),

                // [ Report ] Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSubmitting ? null : () => _submitReport(provider),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            'Report $_selectedReason',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
