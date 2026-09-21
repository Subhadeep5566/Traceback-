import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';

class IncidentReportScreen extends StatefulWidget {
  final String? initialAssetId;

  const IncidentReportScreen({
    super.key,
    this.initialAssetId,
  });

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  late String _selectedAssetId;
  String _selectedReason = 'Missing from Campus Parking';
  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _reasons = [
    'Missing from Campus Parking',
    'Left Behind in Library / Hall',
    'Suspected Theft / Stolen',
    'Dropped / Lost in Transit',
    'Separation Alert Triggered',
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AssetProvider>(context, listen: false);
    if (widget.initialAssetId != null &&
        provider.allAssets.any((a) => a.id == widget.initialAssetId)) {
      _selectedAssetId = widget.initialAssetId!;
    } else if (provider.allAssets.isNotEmpty) {
      _selectedAssetId = provider.allAssets.first.id;
    } else {
      _selectedAssetId = '';
    }

    _notesController.text =
        'Item was last seen near BGU Main Gate. Requesting active mesh tracking.';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssetProvider>(
      builder: (context, provider, child) {
        final assets = provider.allAssets;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Report Missing Item',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFF1E293B), height: 1),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Reporting an asset activates Traceback high-priority recovery mode. Live location pings will be recorded in your dashboard.',
                            style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'SELECT ASSET',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAssetId.isNotEmpty ? _selectedAssetId : null,
                        dropdownColor: const Color(0xFF1E293B),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF38BDF8)),
                        items: assets.map((asset) {
                          return DropdownMenuItem<String>(
                            value: asset.id,
                            child: Row(
                              children: [
                                Icon(asset.category.icon, size: 16, color: const Color(0xFF38BDF8)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${asset.name} (${asset.identifier})',
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedAssetId = val);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'INCIDENT REASON',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reasons.map((reason) {
                      final isSelected = _selectedReason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        selectedColor: const Color(0xFFEF4444).withOpacity(0.2),
                        backgroundColor: const Color(0xFF1E293B),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF334155),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedReason = reason);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'ADDITIONAL DETAILS',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please provide description';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter circumstances or last seen spot...',
                        hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate() && _selectedAssetId.isNotEmpty) {
                          final selectedAsset = assets.firstWhere((a) => a.id == _selectedAssetId);
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              backgroundColor: const Color(0xFF1E293B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                                  SizedBox(width: 8),
                                  Text('Activate Recovery Mode?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                                ],
                              ),
                              content: Text(
                                'This will mark "${selectedAsset.name}" as LOST and activate high-priority tracking. Continue?',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(dialogCtx);
                                    provider.reportStolen(
                                      assetId: _selectedAssetId,
                                      description: '${_selectedReason.toUpperCase()}: ${_notesController.text.trim()}',
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: Color(0xFFEF4444),
                                        content: Text('Recovery mode activated. Asset tracking initiated.'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );

                                    Navigator.pop(context);
                                  },
                                  child: const Text('Activate', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.satellite_alt_rounded, size: 18),
                      label: const Text(
                        'ACTIVATE RECOVERY MODE',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
