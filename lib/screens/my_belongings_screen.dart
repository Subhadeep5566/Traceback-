import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/tb_theme.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../widgets/tb_widgets.dart';
import 'asset_detail_screen.dart';
import 'qr_scanner_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter?.toUpperCase() ?? 'ALL';
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
        backgroundColor: const Color(0xFF141416),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Tb.border),
        ),
        title: const Text(
          'Delete Item?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to remove ${asset.name} (${asset.tracebackId}) from your belongings?',
          style: const TextStyle(fontSize: 13.5, color: Tb.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Tb.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Tb.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteAsset(asset.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${asset.name} deleted'),
                  backgroundColor: Tb.error,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
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
        } else if (_activeFilter == 'FOUND') {
          items = items.where((a) => a.status == AssetStatus.found).toList();
        } else if (_activeFilter == 'RECOVERED') {
          items = items.where((a) => a.status == AssetStatus.recovered).toList();
        }

        if (query.isNotEmpty) {
          items = items.where((a) {
            return a.name.toLowerCase().contains(query) ||
                a.tracebackId.toLowerCase().contains(query) ||
                a.brand.toLowerCase().contains(query) ||
                a.model.toLowerCase().contains(query) ||
                a.category.displayName.toLowerCase().contains(query) ||
                a.address.toLowerCase().contains(query);
          }).toList();
        }

        final totalCount = myBelongings.length;
        final lostCount = myBelongings.where((a) => a.status == AssetStatus.stolen).length;
        final safeCount = myBelongings.where((a) => a.status == AssetStatus.safe).length;

        return Scaffold(
          backgroundColor: Tb.bg,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER
                  AnimatedCardEntrance(
                    index: 0,
                    child: _buildHeader(context),
                  ),

                  const SizedBox(height: 18),

                  // 2. METRICS CAROUSEL
                  AnimatedCardEntrance(
                    index: 1,
                    child: _buildSummaryMetrics(totalCount, lostCount, safeCount),
                  ),

                  const SizedBox(height: 18),

                  // 3. SEARCH BAR
                  AnimatedCardEntrance(
                    index: 2,
                    child: _buildSearchBar(),
                  ),

                  const SizedBox(height: 14),

                  // 4. FILTER CHIPS
                  AnimatedCardEntrance(
                    index: 3,
                    child: _buildFilterChips(myBelongings),
                  ),

                  const SizedBox(height: 20),

                  // 5. ITEM CARDS LIST
                  if (items.isEmpty)
                    AnimatedCardEntrance(
                      index: 4,
                      child: _buildEmptyState(query),
                    )
                  else
                    Column(
                      children: List.generate(items.length, (idx) {
                        final item = items[idx];
                        return AnimatedCardEntrance(
                          index: 4 + idx,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildBelongingCard(context, context.read<AssetProvider>(), item),
                          ),
                        );
                      }),
                    ),
                ],
              ),
            ),
          ),
          );
      },
    );
  }

  // ── 1. Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Items',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'All your registered belongings',
              style: TextStyle(
                color: Tb.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                );
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Tb.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Tb.border),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterBelongingScreen()),
                );
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.black,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 2. Summary Metrics ─────────────────────────────────────────────────────
  Widget _buildSummaryMetrics(int total, int lost, int safe) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          TracebackStatCard(
            count: '$total',
            label: 'Registered',
            icon: Icons.inventory_2_outlined,
            countColor: Colors.white,
            accentColor: Colors.white70,
            onTap: () => setState(() => _activeFilter = 'ALL'),
          ),
          const SizedBox(width: 12),
          TracebackStatCard(
            count: '$lost',
            label: 'Lost',
            icon: Icons.error_outline_rounded,
            countColor: Tb.error,
            accentColor: Tb.error,
            onTap: () => setState(() => _activeFilter = 'LOST'),
          ),
          const SizedBox(width: 12),
          TracebackStatCard(
            count: '$safe',
            label: 'Safe',
            icon: Icons.check_circle_outline_rounded,
            countColor: Tb.success,
            accentColor: Tb.success,
            onTap: () => setState(() => _activeFilter = 'SAFE'),
          ),
        ],
      ),
    );
  }

  // ── 3. Search Bar ──────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return TracebackCard(
      padding: EdgeInsets.zero,
      borderRadius: 18,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search items, IDs, serials...',
          hintStyle: const TextStyle(
            fontSize: 13.5,
            color: Tb.textMuted,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Tb.textMuted,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Tb.textMuted),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  // ── 4. Filter Chips ────────────────────────────────────────────────────────
  Widget _buildFilterChips(List<Asset> myBelongings) {
    final safeNum = myBelongings.where((a) => a.status == AssetStatus.safe).length;
    final lostNum = myBelongings.where((a) => a.status == AssetStatus.stolen).length;
    final foundNum = myBelongings.where((a) => a.status == AssetStatus.found).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildFilterChip('ALL', 'All (${myBelongings.length})'),
          const SizedBox(width: 8),
          _buildFilterChip('SAFE', 'Safe ($safeNum)'),
          const SizedBox(width: 8),
          _buildFilterChip('LOST', 'Lost ($lostNum)'),
          const SizedBox(width: 8),
          _buildFilterChip('FOUND', 'Found ($foundNum)'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _activeFilter == key;

    return GestureDetector(
      onTap: () => setState(() => _activeFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Tb.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Tb.border,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.black : Tb.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── 5. Belonging Item Card ─────────────────────────────────────────────────
  Widget _buildBelongingCard(BuildContext context, AssetProvider provider, Asset item) {
    return TracebackCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssetDetailScreen(assetId: item.id),
          ),
        );
      },
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category icon, Item name, monospace ID, and more actions
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Tb.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Tb.borderSubtle),
                ),
                child: Icon(
                  item.category.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.tracebackId,
                      style: const TextStyle(
                        color: Tb.textSecondary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Tb.textMuted, size: 20),
                color: const Color(0xFF18181B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Tb.border),
                ),
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
                          backgroundColor: Tb.error,
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
                          backgroundColor: Tb.success,
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
                        Icon(Icons.edit_outlined, size: 17, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Edit Item', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                  if (!item.isLost)
                    const PopupMenuItem(
                      value: 'mark_lost',
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 17, color: Tb.error),
                          SizedBox(width: 10),
                          Text('Mark Lost', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tb.error)),
                        ],
                      ),
                    ),
                  if (item.isLost || item.isFound)
                    const PopupMenuItem(
                      value: 'mark_recovered',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 17, color: Tb.success),
                          SizedBox(width: 10),
                          Text('Mark Recovered', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tb.success)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 17, color: Tb.error),
                        SizedBox(width: 10),
                        Text('Delete Item', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tb.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Row 2: Status pill + Last detected location + arrow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TracebackStatusBadge(status: item.status.name, small: true),
              const SizedBox(width: 8),
              if (item.address.isNotEmpty)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Tb.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.address,
                          style: const TextStyle(
                            color: Tb.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Tb.textMuted,
                size: 13,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String query) {
    return TracebackCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      borderRadius: 22,
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Tb.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: Tb.border),
              ),
              child: Icon(
                query.isNotEmpty ? Icons.search_off_rounded : Icons.inventory_2_outlined,
                size: 28,
                color: Tb.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty ? 'No belongings match "$query"' : 'No items in this category',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              query.isNotEmpty
                  ? 'Try searching with another keyword'
                  : 'Add your belongings to protect them on campus',
              style: const TextStyle(
                fontSize: 12.5,
                color: Tb.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
