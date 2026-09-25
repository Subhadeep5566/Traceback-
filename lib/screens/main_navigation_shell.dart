import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/tb_widgets.dart';
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

  final Map<int, Widget> _screenCache = {};
  bool? _lastIsAdmin;

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });
  }

  Widget _getScreen(int index, bool isAdmin) {
    if (_lastIsAdmin != isAdmin) {
      _screenCache.remove(0);
      _screenCache.remove(1);
      _lastIsAdmin = isAdmin;
    }

    if (!_loadedTabs.contains(index)) {
      return const SizedBox.shrink();
    }

    return _screenCache.putIfAbsent(index, () {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, (idx) => _getScreen(idx, isAdmin)),
      ),
      bottomNavigationBar: TracebackBottomNav(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
        items: [
          const TracebackNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
          ),
          TracebackNavItem(
            icon: isAdmin ? Icons.assignment_rounded : Icons.inventory_2_rounded,
            label: isAdmin ? 'Cases' : 'Items',
          ),
          const TracebackNavItem(
            icon: Icons.map_rounded,
            label: 'Map',
          ),
          const TracebackNavItem(
            icon: Icons.search_rounded,
            label: 'Search',
          ),
          const TracebackNavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
