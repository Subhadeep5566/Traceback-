import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'admin_cases_screen.dart';
import 'admin_dashboard_screen.dart';
import 'dashboard_screen.dart';
import 'found_item_screen.dart';
import 'global_map_screen.dart';
import 'my_belongings_screen.dart';
import 'settings_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialTab;

  const MainNavigationShell({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;
  final Set<int> _loadedTabs = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _loadedTabs.add(widget.initialTab);
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });
  }

  Widget _buildScreen(int index, bool isAdmin) {
    if (!_loadedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case 0:
        return isAdmin
            ? AdminDashboardScreen(onNavigateTab: _onTabSelected)
            : DashboardScreen(onNavigateTab: _onTabSelected);
      case 1:
        return isAdmin ? const AdminCasesScreen() : const MyBelongingsScreen();
      case 2:
        return const GlobalMapScreen();
      case 3:
        return const FoundItemScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isAdmin = auth.isAdmin;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, (idx) => _buildScreen(idx, isAdmin)),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: isAdmin ? Icons.admin_panel_settings_rounded : Icons.home_rounded,
                  label: isAdmin ? 'DASHBOARD' : 'HOME',
                ),
                _buildNavItem(
                  index: 1,
                  icon: isAdmin ? Icons.folder_shared_rounded : Icons.inventory_2_rounded,
                  label: isAdmin ? 'CASES' : 'BELONGINGS',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.radar_rounded,
                  label: 'MAP',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'SCAN',
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_rounded,
                  label: 'PROFILE',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.black : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: color,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
