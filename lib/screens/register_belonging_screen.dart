import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../services/location_service.dart';

class RegisterBelongingScreen extends StatefulWidget {
  const RegisterBelongingScreen({super.key});

  @override
  State<RegisterBelongingScreen> createState() => _RegisterBelongingScreenState();
}

class _RegisterBelongingScreenState extends State<RegisterBelongingScreen> {
  int _currentStep = 0; // 0: Category, 1: Basic Info, 2: Confirm & Tag

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(
    text: 'BGU Campus, Bhubaneswar',
  );

  AssetCategory _selectedCategory = AssetCategory.vehicle;
  String _categoryLabel = 'Bike';
  bool _isDetectingLocation = false;
  bool _isSaving = false;
  String _generatedTagId = '';

  final List<Map<String, dynamic>> _categoryOptions = [
    {'category': AssetCategory.vehicle, 'label': 'Bike', 'icon': Icons.two_wheeler_rounded, 'subtitle': 'Cycle, Scooter, Motorbike'},
    {'category': AssetCategory.electronics, 'label': 'Laptop', 'icon': Icons.laptop_mac_rounded, 'subtitle': 'MacBook, Dell, ThinkPad'},
    {'category': AssetCategory.phone, 'label': 'Phone', 'icon': Icons.smartphone_rounded, 'subtitle': 'iPhone, Android smartphone'},
    {'category': AssetCategory.belonging, 'label': 'Personal Bag', 'icon': Icons.backpack_rounded, 'subtitle': 'Backpack, Handbag, Kit'},
    {'category': AssetCategory.belonging, 'label': 'Other', 'icon': Icons.category_rounded, 'subtitle': 'Watches, Books, Chargers'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateGeneratedTagId();
    });
  }

  void _updateGeneratedTagId() {
    final provider = context.read<AssetProvider>();
    setState(() {
      _generatedTagId = provider.generateUniqueTracebackId(_selectedCategory);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final result = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _locationController.text = result.address;
          _isDetectingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isSaving = true);

    try {
      final provider = context.read<AssetProvider>();
      final newAsset = await provider.registerBelonging(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        color: _colorController.text.trim(),
        address: _locationController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newAsset.name} registered securely!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, newAsset);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _goToNextStep() {
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      _submitRegistration();
    }
  }

  void _goToPrevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
          onPressed: _goToPrevStep,
        ),
        title: const Text(
          'REGISTER BELONGING',
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
        child: Column(
          children: [
            // Minimal Step Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  _stepBadge(0, 'Category'),
                  _stepDivider(0),
                  _stepBadge(1, 'Basic Info'),
                  _stepDivider(1),
                  _stepBadge(2, 'Confirm & Tag'),
                ],
              ),
            ),

            // Wizard Step Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Fixed bottom action bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _stepBadge(int stepIndex, String label) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Colors.black
                : isDone
                    ? const Color(0xFF10B981)
                    : const Color(0xFFCBD5E1),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? Colors.black : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _stepDivider(int stepIndex) {
    final isDone = _currentStep > stepIndex;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 2,
        color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Category();
      case 1:
        return _buildStep2BasicInfo();
      case 2:
      default:
        return _buildStep3Confirm();
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: CATEGORY
  // ---------------------------------------------------------------------------
  Widget _buildStep1Category() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Category',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose what type of belonging you want to protect with Traceback.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),

        ..._categoryOptions.map((opt) {
          final isSelected = _categoryLabel == opt['label'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _categoryLabel = opt['label'] as String;
                _selectedCategory = opt['category'] as AssetCategory;
                _updateGeneratedTagId();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? Colors.black : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.8 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      opt['icon'] as IconData,
                      size: 22,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt['label'] as String,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          opt['subtitle'] as String,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? Colors.black : const Color(0xFFCBD5E1),
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: BASIC INFO
  // ---------------------------------------------------------------------------
  Widget _buildStep2BasicInfo() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Info',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tell us about your $_categoryLabel so it can be identified accurately.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Name *
          const Text(
            'NAME *',
            style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration('e.g. My Campus Cycle, Silver MacBook Pro'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name for this item' : null,
          ),
          const SizedBox(height: 16),

          // Brand
          const Text(
            'BRAND',
            style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _brandController,
            decoration: _inputDecoration('e.g. Hero, Apple, Dell, Decathlon'),
          ),
          const SizedBox(height: 16),

          // Model
          const Text(
            'MODEL',
            style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _modelController,
            decoration: _inputDecoration('e.g. Sprint Pro 21-Speed, M2 14"'),
          ),
          const SizedBox(height: 16),

          // Color
          const Text(
            'COLOR',
            style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _colorController,
            decoration: _inputDecoration('e.g. Matte Black, Space Gray, Navy Blue'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: CONFIRM & TAG
  // ---------------------------------------------------------------------------
  Widget _buildStep3Confirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm & Tag',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'A unique Traceback tag will be assigned to this belonging.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),

        // Generated Traceback ID Card Preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: QrImageView(
                  data: 'traceback://item/$_generatedTagId',
                  size: 60,
                  version: QrVersions.auto,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GENERATED TRACEBACK ID',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _generatedTagId.isNotEmpty ? _generatedTagId : 'Generating...',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'Initial Status: SECURE',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Summary details box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow('Category', _categoryLabel),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _summaryRow('Name', _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : '—'),
              if (_brandController.text.trim().isNotEmpty) ...[
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                _summaryRow('Brand', _brandController.text.trim()),
              ],
              if (_modelController.text.trim().isNotEmpty) ...[
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                _summaryRow('Model', _modelController.text.trim()),
              ],
              if (_colorController.text.trim().isNotEmpty) ...[
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                _summaryRow('Color', _colorController.text.trim()),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Registered Location
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'REGISTERED LOCATION',
              style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w800),
            ),
            TextButton.icon(
              onPressed: _isDetectingLocation ? null : _detectCurrentLocation,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              icon: _isDetectingLocation
                  ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.my_location_rounded, size: 13, color: Colors.black),
              label: const Text('Use GPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _locationController,
          decoration: _inputDecoration('Campus address or location'),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM ACTION BAR
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _goToPrevStep,
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _goToNextStep,
                child: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        _currentStep == 0
                            ? 'Next: Basic Info'
                            : _currentStep == 1
                                ? 'Next: Confirm & Tag'
                                : 'Register Belonging',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    );
  }
}
