import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import '../design/tb_theme.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../services/location_service.dart';
import '../widgets/tb_widgets.dart';
import 'map_location_picker_screen.dart';

class ReportItemScreen extends StatefulWidget {
  final Asset? initialAsset;
  final String? initialAssetId;

  const ReportItemScreen({
    super.key,
    this.initialAsset,
    this.initialAssetId,
  });

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedAssetId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double? _latitude;
  double? _longitude;
  bool _isDetectingLocation = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAssetId = widget.initialAsset?.id ?? widget.initialAssetId;
    _locationController.text = widget.initialAsset?.address ?? 'Main Campus, Bhubaneswar';
    _latitude = widget.initialAsset?.latitude ?? LocationService.bhubaneswarLatitude;
    _longitude = widget.initialAsset?.longitude ?? LocationService.bhubaneswarLongitude;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: TbColors.primary,
              surface: TbColors.cardBackground,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: TbColors.cardBackground,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: TbColors.primary,
              surface: TbColors.cardBackground,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: TbColors.cardBackground,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
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
          title: 'Select Lost Location',
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

  Future<void> _submitReport() async {
    if (_selectedAssetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an item', style: TextStyle(color: Colors.white)),
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

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final provider = context.read<AssetProvider>();

    try {
      final combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final combinedNotes = [
        if (_descController.text.trim().isNotEmpty) 'Description: ${_descController.text.trim()}',
        if (_notesController.text.trim().isNotEmpty) 'Additional Info: ${_notesController.text.trim()}',
        'Reported lost on ${DateFormat('MMM d, h:mm a').format(combinedDateTime)}',
      ].join('\n');

      await provider.reportLostOrStolen(
        assetId: _selectedAssetId!,
        reason: 'Lost',
        locationAddress: _locationController.text.trim(),
        coordinates: _latitude != null && _longitude != null
            ? ll.LatLng(_latitude!, _longitude!)
            : null,
        notes: combinedNotes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.radar_rounded, color: TbColors.statusLost, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Item marked as lost and flagged on campus radar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: TbColors.cardBackground,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0x33EF4444)),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report failed: $e', style: const TextStyle(color: Colors.white)),
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
    return Consumer<AssetProvider>(
      builder: (context, provider, child) {
        final availableAssets = provider.myBelongings;
        if (_selectedAssetId == null && availableAssets.isNotEmpty) {
          _selectedAssetId = availableAssets.first.id;
        }

        return Scaffold(
          backgroundColor: TbColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with back button
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report Lost Item',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Flag on campus radar for peer recovery',
                                style: TextStyle(
                                  color: TbColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // CARD 1: Selected Item
                    AnimatedCardEntrance(
                      delayMs: 40,
                      child: TracebackCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TracebackSectionHeader(
                              title: 'SELECTED ITEM',
                              subtitle: 'Choose which registered belonging was lost',
                            ),
                            const SizedBox(height: 14),
                            if (availableAssets.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No registered items found.',
                                  style: TextStyle(color: TbColors.textMuted, fontSize: 13),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A0A0A),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: TbColors.cardBorder),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedAssetId,
                                    dropdownColor: const Color(0xFF141416),
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: TbColors.textMuted,
                                    ),
                                    items: availableAssets.map((asset) {
                                      return DropdownMenuItem<String>(
                                        value: asset.id,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: TbColors.cardBackground,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: TbColors.cardBorder),
                                              ),
                                              child: Icon(
                                                asset.category.icon,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    asset.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    '${asset.category.displayName} • ${asset.tracebackId}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: TbColors.textMuted,
                                                    ),
                                                  ),
                                                ],
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
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CARD 2: Last Seen Location Card
                    AnimatedCardEntrance(
                      delayMs: 80,
                      child: TracebackCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TracebackSectionHeader(
                              title: 'LAST SEEN LOCATION',
                              subtitle: 'Where was this item last in your possession?',
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _locationController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Please specify location' : null,
                              decoration: InputDecoration(
                                hintText: 'e.g. Campus Library 2nd floor, Room 302',
                                hintStyle: const TextStyle(fontSize: 13, color: TbColors.textMuted),
                                prefixIcon: const Icon(
                                  Icons.place_outlined,
                                  size: 18,
                                  color: TbColors.textMuted,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF0A0A0A),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: TbColors.cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: TbColors.cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.white30),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _isDetectingLocation ? null : _detectLocation,
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF141416),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: TbColors.cardBorder),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (_isDetectingLocation)
                                            const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          else
                                            const Icon(
                                              Icons.my_location_rounded,
                                              size: 14,
                                              color: Colors.white70,
                                            ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Current GPS',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
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
                                    onTap: _pickOnMap,
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
                                          Icon(
                                            Icons.map_rounded,
                                            size: 14,
                                            color: Colors.white70,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Select on Map',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
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
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CARD 3: Date & Time in Dark Cards
                    AnimatedCardEntrance(
                      delayMs: 120,
                      child: Row(
                        children: [
                          // Date Card
                          Expanded(
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(20),
                              child: TracebackCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'DATE LOST',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: TbColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 14,
                                          color: TbColors.textMuted,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('MMM d, yyyy').format(_selectedDate),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Time Card
                          Expanded(
                            child: InkWell(
                              onTap: _pickTime,
                              borderRadius: BorderRadius.circular(20),
                              child: TracebackCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'APPROX TIME',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: TbColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: TbColors.textMuted,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _selectedTime.format(context),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CARD 4: Description Card
                    AnimatedCardEntrance(
                      delayMs: 160,
                      child: TracebackCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TracebackSectionHeader(
                              title: 'INCIDENT DESCRIPTION',
                              subtitle: 'Briefly explain circumstances when you noticed it missing',
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _descController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Left at table near south window after class...',
                                hintStyle: const TextStyle(fontSize: 13, color: TbColors.textMuted),
                                filled: true,
                                fillColor: const Color(0xFF0A0A0A),
                                contentPadding: const EdgeInsets.all(14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: TbColors.cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: TbColors.cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.white30),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CARD 5: Additional Information Card
                    AnimatedCardEntrance(
                      delayMs: 200,
                      child: TracebackCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TracebackSectionHeader(
                              title: 'DISTINGUISHING MARKS',
                              subtitle: 'Stickers, scratches, case color, or unique serial info',
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _notesController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Blue sticker on back, small dent on bottom left...',
                                hintStyle: const TextStyle(fontSize: 13, color: TbColors.textMuted),
                                filled: true,
                                fillColor: const Color(0xFF0A0A0A),
                                contentPadding: const EdgeInsets.all(14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: TbColors.cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: TbColors.cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.white30),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // LARGE ACTION BUTTON: Report Lost
                    AnimatedCardEntrance(
                      delayMs: 240,
                      child: InkWell(
                        onTap: _isSubmitting ? null : _submitReport,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Broadcast Lost Alert',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
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
            ),
          ),
        );
      },
    );
  }
}
