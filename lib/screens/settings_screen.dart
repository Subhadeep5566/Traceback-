import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _shareContactWithFinder = true;

  @override
  void initState() {
    super.initState();
    final storage = context.read<StorageService>();
    _notificationsEnabled = (storage.getSetting('notifications_enabled') as bool?) ?? true;
    _shareContactWithFinder = (storage.getSetting('share_contact') as bool?) ?? true;
  }

  void _showEditAccountDialog(BuildContext context, AuthService auth) {
    final nameCtrl = TextEditingController(text: auth.userName ?? '');
    final phoneCtrl = TextEditingController(text: auth.userPhone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Edit Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newPhone = phoneCtrl.text.trim();
              final current = auth.currentUserProfile;
              final updated = current.copyWith(
                name: newName.isNotEmpty ? newName : current.name,
                phone: newPhone.isNotEmpty ? newPhone : current.phone,
              );
              await auth.updateProfile(updated);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacy Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Safe Finder Contact', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Allow finder to view campus recovery desk without exposing private phone.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                value: _shareContactWithFinder,
                activeColor: Colors.black,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _shareContactWithFinder = val);
                  context.read<StorageService>().saveSetting('share_contact', val);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final auth = context.read<AuthService>();
    await auth.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        final profile = auth.currentUserProfile;
        final name = profile.name.isNotEmpty ? profile.name : 'Subhadeep';
        final email = profile.email.isNotEmpty ? profile.email : 'student@bgu.ac.in';
        final phone = profile.phone.isNotEmpty ? profile.phone : '9876543210';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Profile',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // Profile Photo / Avatar & Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.black,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+91 $phone',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Simple Settings Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Account',
                          onTap: () => _showEditAccountDialog(context, auth),
                        ),
                        const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9)),
                        _buildSwitchTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          value: _notificationsEnabled,
                          onChanged: (val) {
                            setState(() => _notificationsEnabled = val);
                            context.read<StorageService>().saveSetting('notifications_enabled', val);
                          },
                        ),
                        const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9)),
                        _buildSettingTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Privacy',
                          onTap: () => _showPrivacySheet(context),
                        ),
                        const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9)),
                        _buildSettingTile(
                          icon: Icons.logout_rounded,
                          title: 'Logout',
                          titleColor: const Color(0xFFEF4444),
                          iconColor: const Color(0xFFEF4444),
                          onTap: _logout,
                          hideArrow: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color titleColor = Colors.black,
    Color iconColor = Colors.black,
    bool hideArrow = false,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: titleColor,
        ),
      ),
      trailing: hideArrow
          ? null
          : const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeColor: Colors.black,
        onChanged: onChanged,
      ),
    );
  }
}