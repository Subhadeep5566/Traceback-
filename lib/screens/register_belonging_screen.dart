import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';

class RegisterBelongingScreen extends StatefulWidget {
  final Asset? editingAsset;

  const RegisterBelongingScreen({
    super.key,
    this.editingAsset,
  });

  @override
  State<RegisterBelongingScreen> createState() => _RegisterBelongingScreenState();
}

class _RegisterBelongingScreenState extends State<RegisterBelongingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _serialController;
  late final TextEditingController _tagIdController;
  late final TextEditingController _colorController;

  late AssetCategory _selectedCategory;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _categories = [
    {'category': AssetCategory.electronics, 'label': 'Laptop', 'icon': Icons.laptop_mac_rounded},
    {'category': AssetCategory.phone, 'label': 'Phone', 'icon': Icons.smartphone_rounded},
    {'category': AssetCategory.vehicle, 'label': 'Bike / Cycle', 'icon': Icons.two_wheeler_rounded},
    {'category': AssetCategory.belonging, 'label': 'Bag / Other', 'icon': Icons.backpack_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.editingAsset;
    _nameController = TextEditingController(text: item?.name ?? '');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _modelController = TextEditingController(text: item?.model ?? '');
    _serialController = TextEditingController(text: item?.description ?? '');
    _tagIdController = TextEditingController(text: item?.tracebackId ?? '');
    _colorController = TextEditingController(text: item?.color ?? '');
    _selectedCategory = item?.category ?? AssetCategory.electronics;

    if (item == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoGenerateTag();
      });
    }
  }

  void _autoGenerateTag() {
    if (widget.editingAsset != null) return;
    final provider = context.read<AssetProvider>();
    setState(() {
      _tagIdController.text = provider.generateUniqueTracebackId(_selectedCategory);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _tagIdController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<AssetProvider>();

    try {
      if (widget.editingAsset != null) {
        final existing = widget.editingAsset!;
        final updated = existing.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          color: _colorController.text.trim(),
          description: _serialController.text.trim(),
          tracebackId: _tagIdController.text.trim().isNotEmpty
              ? _tagIdController.text.trim().toUpperCase()
              : existing.tracebackId,
          updatedAt: DateTime.now(),
        );
        await provider.updateAsset(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${updated.name} updated'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, updated);
        }
      } else {
        final newAsset = await provider.registerBelonging(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          color: _colorController.text.trim(),
          description: _serialController.text.trim(),
          customTracebackId: _tagIdController.text.trim().isNotEmpty
              ? _tagIdController.text.trim().toUpperCase()
              : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newAsset.name} registered'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, newAsset);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingAsset != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Item' : 'Add Item',
          style: const TextStyle(
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Selector
                const Text(
                  'CATEGORY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['category'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat['category'] as AssetCategory;
                            _autoGenerateTag();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? Colors.black : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat['icon'] as IconData,
                                color: isSelected ? Colors.white : Colors.black,
                                size: 22,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat['label'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Item Name Field
                _buildFieldLabel('ITEM NAME *'),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter item name' : null,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. MacBook Air, Trek Bicycle',
                    prefixIcon: Icons.label_outline_rounded,
                  ),
                ),
                const SizedBox(height: 18),

                // Brand & Model Fields
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('BRAND'),
                          TextFormField(
                            controller: _brandController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _buildInputDecoration(
                              hintText: 'e.g. Apple, Trek',
                              prefixIcon: Icons.branding_watermark_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('MODEL'),
                          TextFormField(
                            controller: _modelController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _buildInputDecoration(
                              hintText: 'e.g. M2 13", FX 2',
                              prefixIcon: Icons.memory_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Color & Serial Number Fields
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('COLOR'),
                          TextFormField(
                            controller: _colorController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _buildInputDecoration(
                              hintText: 'e.g. Space Gray, Blue',
                              prefixIcon: Icons.palette_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('SERIAL NUMBER (OPTIONAL)'),
                          TextFormField(
                            controller: _serialController,
                            decoration: _buildInputDecoration(
                              hintText: 'e.g. C02G90...',
                              prefixIcon: Icons.tag_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Traceback Tag ID Field
                _buildFieldLabel('TRACEBACK TAG ID *'),
                TextFormField(
                  controller: _tagIdController,
                  textCapitalization: TextCapitalization.characters,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Tag ID is required' : null,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. TB-20481',
                    prefixIcon: Icons.qr_code_rounded,
                    suffixWidget: IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                      onPressed: _autoGenerateTag,
                      tooltip: 'Generate new ID',
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Register / Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEditing ? 'Save Changes' : 'Register Item',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
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
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixWidget,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF64748B)),
      suffixIcon: suffixWidget,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
    );
  }
}
