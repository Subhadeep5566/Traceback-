import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/tb_theme.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../widgets/tb_widgets.dart';

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
  late final TextEditingController _locationController;

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
    _locationController = TextEditingController(text: item?.address ?? 'Main Campus, Bhubaneswar');
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
    _locationController.dispose();
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
          description: _serialController.text.trim(),
          address: _locationController.text.trim(),
          tracebackId: _tagIdController.text.trim().isNotEmpty
              ? _tagIdController.text.trim().toUpperCase()
              : existing.tracebackId,
          updatedAt: DateTime.now(),
        );
        await provider.updateAsset(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${updated.name} updated successfully'),
              backgroundColor: Tb.success,
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
          description: _serialController.text.trim(),
          customTracebackId: _tagIdController.text.trim().isNotEmpty
              ? _tagIdController.text.trim().toUpperCase()
              : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newAsset.name} registered to your account'),
              backgroundColor: Tb.success,
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
            backgroundColor: Tb.error,
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
      backgroundColor: Tb.bg,
      appBar: AppBar(
        backgroundColor: Tb.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Item' : 'Add Item',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 48),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subtitle
                const Text(
                  'Register and protect your belongings on campus',
                  style: TextStyle(
                    color: Tb.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // CARD 1: [ Category Selection ]
                AnimatedCardEntrance(
                  index: 0,
                  child: TracebackCard(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CATEGORY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Tb.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
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
                                    color: isSelected ? Colors.white : Tb.surface2,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Tb.borderSubtle,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        cat['icon'] as IconData,
                                        color: isSelected ? Colors.black : Colors.white,
                                        size: 21,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        cat['label'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: isSelected ? Colors.black : Tb.textSecondary,
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // CARD 2: [ Item Information ]
                AnimatedCardEntrance(
                  index: 1,
                  child: TracebackCard(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ITEM INFORMATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Tb.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Please enter item name' : null,
                          decoration: _buildInputDecoration(
                            hintText: 'Item Name (e.g. Student Laptop, Trek Bike)',
                            prefixIcon: Icons.label_outline_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _brandController,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                                decoration: _buildInputDecoration(
                                  hintText: 'Brand (e.g. Apple)',
                                  prefixIcon: Icons.branding_watermark_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _modelController,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                                decoration: _buildInputDecoration(
                                  hintText: 'Model (e.g. M2 Air)',
                                  prefixIcon: Icons.memory_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _serialController,
                          style: const TextStyle(color: Colors.white, fontSize: 13.5),
                          decoration: _buildInputDecoration(
                            hintText: 'Description or distinguishable markings',
                            prefixIcon: Icons.notes_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // CARD 3: [ Traceback Tag ]
                AnimatedCardEntrance(
                  index: 2,
                  child: TracebackCard(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TRACEBACK TAG',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Tb.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _tagIdController,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Tag ID is required' : null,
                          decoration: _buildInputDecoration(
                            hintText: 'e.g. TB-LAPTOP-002',
                            prefixIcon: Icons.qr_code_rounded,
                            suffixWidget: IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 20, color: Tb.textSecondary),
                              onPressed: _autoGenerateTag,
                              tooltip: 'Generate new ID',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // CARD 4: [ Additional Information / Location ]
                AnimatedCardEntrance(
                  index: 3,
                  child: TracebackCard(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LOCATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Tb.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _locationController,
                          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                          decoration: _buildInputDecoration(
                            hintText: 'e.g. Main Campus Hostel / Library',
                            prefixIcon: Icons.place_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // CARD 5: [ Submit Button / Card ]
                AnimatedCardEntrance(
                  index: 4,
                  child: GestureDetector(
                    onTap: _isSaving ? null : _submit,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: Tb.cardShadow,
                      ),
                      alignment: Alignment.center,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                            )
                          : Text(
                              isEditing ? 'Save Changes' : 'Add Item',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
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

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixWidget,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13.5, color: Tb.textMuted),
      prefixIcon: Icon(prefixIcon, size: 19, color: Tb.textMuted),
      suffixIcon: suffixWidget,
      filled: true,
      fillColor: Tb.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Tb.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Tb.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white54, width: 1.2),
      ),
    );
  }
}
