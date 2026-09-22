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

  void _confirmDelete(AssetProvider provider, Asset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete Item?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Are you sure you want to remove ${asset.name} (${asset.tracebackId}) from your belongings?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteAsset(asset.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${asset.name} deleted'),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AssetProvider, List<Asset>>(
      selector: (_, provider) => provider.myBelongings,
      builder: (context, myBelongings, child) {
        final query = _searchController.text.trim().toLowerCase();
        List<Asset> items = myBelongings;

        if (_activeFilter == 'SAFE') {
          items = items.where((a) => a.status == AssetStatus.safe).toList();
        } else if (_activeFilter == 'LOST') {
          items = items.where((a) => a.status == AssetStatus.stolen).toList();
        } else if (_activeFilter == 'RECOVERED') {
          items = items.where((a) => a.status == AssetStatus.recovered).toList();
        }

        if (query.isNotEmpty) {
          items = items.where((a) {
            return a.name.toLowerCase().contains(query) ||
                a.tracebackId.toLowerCase().contains(query) ||
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
              'My Items',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
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
                icon: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
                tooltip: 'Add Item',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterBelongingScreen()),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(_showSearch ? 110 : 54),
              child: Column(
                children: [
                  if (_showSearch)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by item name or tag ID...',
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
                  // Filter Chips Row
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', 'All (${myBelongings.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('SAFE', 'Safe (${myBelongings.where((a) => a.status == AssetStatus.safe).length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('LOST', 'Lost (${myBelongings.where((a) => a.status == AssetStatus.stolen).length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('RECOVERED', 'Recovered (${myBelongings.where((a) => a.status == AssetStatus.recovered).length})'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                ],
              ),
            ),
          ),
          body: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 44,
                        color: Colors.black.withOpacity(0.15),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No items found',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        query.isNotEmpty ? 'Try a different search query' : 'Tap + to register your first item',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildItemCard(context, context.read<AssetProvider>(), item);
                  },
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterBelongingScreen()),
              );
            },
            child: const Icon(Icons.add_rounded, size: 26),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _activeFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, AssetProvider provider, Asset item) {
    Color statusColor;
    String statusLabel;

    if (item.isLost) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'Lost';
    } else if (item.isFound) {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'Found';
    } else if (item.isRecovered) {
      statusColor = const Color(0xFF0284C7);
      statusLabel = 'Recovered';
    } else {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'Safe';
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssetDetailScreen(assetId: item.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isLost ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
            width: item.isLost ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Item Icon / Image Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.category.icon, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 14),

            // Item Name & Traceback ID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Text(
                        'Traceback ID: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        item.tracebackId,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Visual Status Indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Context Action Popup Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (action) async {
                if (action == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterBelongingScreen(editingAsset: item),
                    ),
                  );
                } else if (action == 'mark_lost') {
                  await provider.markAsLost(item.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} marked as lost'),
                        backgroundColor: const Color(0xFFEF4444),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else if (action == 'mark_recovered') {
                  await provider.confirmRecovery(item.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} marked as recovered'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else if (action == 'delete') {
                  _confirmDelete(provider, item);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: Colors.black),
                      SizedBox(width: 8),
                      Text('Edit Item', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (!item.isLost)
                  const PopupMenuItem(
                    value: 'mark_lost',
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Mark Lost', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                if (item.isLost || item.isFound)
                  const PopupMenuItem(
                    value: 'mark_recovered',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text('Mark Recovered', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      SizedBox(width: 8),
                      Text('Delete Item', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                    ],
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
