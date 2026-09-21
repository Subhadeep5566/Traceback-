import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import 'asset_detail_screen.dart';
import 'register_belonging_screen.dart';

class MyBelongingsScreen extends StatefulWidget {
  final String? initialFilter;

  const MyBelongingsScreen({
    super.key,
    this.initialFilter,
  });

  @override
  State<MyBelongingsScreen> createState() => _MyBelongingsScreenState();
}

class _MyBelongingsScreenState extends State<MyBelongingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _activeFilter;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter ?? 'ALL';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context, AssetProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'FILTER BELONGINGS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildModalFilterChip('ALL', provider.totalAssetCount),
                  _buildModalFilterChip('SECURE', provider.secureCount),
                  _buildModalFilterChip('LOST', provider.lostCount),
                  _buildModalFilterChip('FOUND', provider.foundCount),
                  _buildModalFilterChip('RECOVERED', provider.recoveredCount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalFilterChip(String label, int count) {
    final isSelected = _activeFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      selectedColor: Colors.black,
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      onSelected: (val) {
        setState(() => _activeFilter = label);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssetProvider>(
      builder: (context, provider, child) {
        final query = _searchController.text.trim().toLowerCase();

        List<Asset> items = provider.myBelongings;

        if (_activeFilter == 'SECURE') {
          items = items.where((a) => a.status == AssetStatus.safe).toList();
        } else if (_activeFilter == 'LOST') {
          items = items.where((a) => a.status == AssetStatus.stolen).toList();
        } else if (_activeFilter == 'FOUND') {
          items = items.where((a) => a.status == AssetStatus.found).toList();
        } else if (_activeFilter == 'RECOVERED') {
          items = items.where((a) => a.status == AssetStatus.recovered).toList();
        }

        if (query.isNotEmpty) {
          items = items.where((a) {
            return a.name.toLowerCase().contains(query) ||
                a.tracebackId.toLowerCase().contains(query) ||
                a.category.displayName.toLowerCase().contains(query) ||
                a.brand.toLowerCase().contains(query) ||
                a.model.toLowerCase().contains(query);
          }).toList();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'My Belongings',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _showSearch ? Icons.close_rounded : Icons.search_rounded,
                  color: Colors.black,
                  size: 22,
                ),
                tooltip: 'Search',
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) _searchController.clear();
                  });
                },
              ),
              IconButton(
                icon: Badge(
                  isLabelVisible: _activeFilter != 'ALL',
                  smallSize: 8,
                  backgroundColor: Colors.black,
                  child: const Icon(Icons.filter_list_rounded, color: Colors.black, size: 22),
                ),
                tooltip: 'Filter',
                onPressed: () => _showFilterModal(context, provider),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
                tooltip: 'Register Item',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterBelongingScreen()),
                  );
                },
              ),
              const SizedBox(width: 6),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(_showSearch ? 60 : 1),
              child: Column(
                children: [
                  if (_showSearch)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by item or Traceback ID...',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  Container(color: const Color(0xFFE2E8F0), height: 1),
                ],
              ),
            ),
          ),
          body: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.black.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      const Text(
                        'No belongings found',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        query.isNotEmpty ? 'Try a different search term' : 'Tap + to register your first item',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final asset = items[index];
                    return _buildMinimalBelongingCard(context, asset);
                  },
                ),
        );
      },
    );
  }

  Widget _buildMinimalBelongingCard(BuildContext context, Asset asset) {
    Color statusColor = const Color(0xFF10B981);
    if (asset.isLost) {
      statusColor = const Color(0xFFEF4444);
    } else if (asset.isFound) {
      statusColor = const Color(0xFFF59E0B);
    } else if (asset.isRecovered) {
      statusColor = const Color(0xFF0284C7);
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AssetDetailScreen(assetId: asset.id)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: asset.isLost ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
            width: asset.isLost ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Item image/icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(asset.category.icon, color: Colors.black, size: 22),
            ),
            const SizedBox(width: 14),

            // Item name & Traceback ID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    asset.tracebackId,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Status: small indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  asset.status.displayName.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
