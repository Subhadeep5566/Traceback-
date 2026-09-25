import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/tb_theme.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/tb_widgets.dart';
import 'my_belongings_screen.dart';
import 'notifications_screen.dart';

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
        backgroundColor: const Color(0xFF141416),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: TbColors.cardBorder),
        ),
        title: const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: const TextStyle(color: TbColors.textMuted),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: TbColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: TbColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneCtrl,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: const TextStyle(color: TbColors.textMuted),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: TbColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: TbColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: TbColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141416),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: TbColors.cardBorder),
        ),
        title: const Text(
          'Security & Privacy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Traceback uses campus-grade encrypted tokens to protect your contact data when belongings are scanned.',
              style: TextStyle(fontSize: 13, color: TbColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text(
                'Safe Finder Contact',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
              ),
              subtitle: const Text(
                'Mask direct phone number until item is safely identified.',
                style: TextStyle(fontSize: 11, color: TbColors.textMuted),
              ),
              value: _shareContactWithFinder,
              activeColor: Colors.white,
              activeTrackColor: Colors.white38,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() => _shareContactWithFinder = val);
                context.read<StorageService>().saveSetting('share_contact', val);
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141416),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: TbColors.cardBorder),
        ),
        title: const Text(
          'Campus Operations Desk',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lost & Found Hub:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            SizedBox(height: 6),
            Text(
              'Location: Main Gate Security Office\nPhone: +91 674 237 8000\nEmail: lostfound@campus.edu',
              style: TextStyle(fontSize: 13, color: TbColors.textMuted, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'Hours: Monday - Saturday (8:00 AM - 8:00 PM)',
              style: TextStyle(fontSize: 11, color: TbColors.textMuted),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141416),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: TbColors.cardBorder),
        ),
        title: const Text(
          'Sign Out?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to sign out from Traceback?',
          style: TextStyle(fontSize: 13, color: TbColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: TbColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final auth = context.read<AuthService>();
      await auth.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        final profile = auth.currentUserProfile;
        final name = profile.name.isNotEmpty ? profile.name : (auth.userName ?? 'Subhadeep');
        final email = profile.email.isNotEmpty ? profile.email : (auth.userEmail ?? 'subhadeep@campus.edu');
        final phone = profile.phone.isNotEmpty ? profile.phone : (auth.userPhone ?? '9876543210');
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

        return Scaffold(
          backgroundColor: TbColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage campus account, privacy, and preferences',
                    style: TextStyle(
                      color: TbColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 1. [ PROFILE CARD ]
                  AnimatedCardEntrance(
                    delayMs: 30,
                    child: TracebackCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C20),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.06),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: TbColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  phone.startsWith('+') ? phone : '+91 $phone',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF888890),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => _showEditAccountDialog(context, auth),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: TbColors.cardBorder),
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 2. [ ACCOUNT CARD ]
                  AnimatedCardEntrance(
                    delayMs: 60,
                    child: TracebackCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(4, 10, 4, 8),
                            child: TracebackSectionHeader(
                              title: 'ACCOUNT & ASSETS',
                              subtitle: 'Manage your verified items on campus',
                            ),
                          ),
                          _buildProfileRow(
                            icon: Icons.inventory_2_outlined,
                            title: 'Registered Belongings',
                            subtitle: 'View, edit, or remove your campus items',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MyBelongingsScreen()),
                              );
                            },
                          ),
                          const Divider(color: TbColors.cardBorder, height: 1),
                          _buildProfileRow(
                            icon: Icons.person_outline_rounded,
                            title: 'Personal Information',
                            subtitle: 'Name, contact phone, and campus email',
                            onTap: () => _showEditAccountDialog(context, auth),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. [ ACTIVITY & NOTIFICATIONS CARD ]
                  AnimatedCardEntrance(
                    delayMs: 90,
                    child: TracebackCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(4, 10, 4, 8),
                            child: TracebackSectionHeader(
                              title: 'ACTIVITY & ALERTS',
                              subtitle: 'Radar scan alerts and push updates',
                            ),
                          ),
                          _buildProfileRow(
                            icon: Icons.notifications_none_rounded,
                            title: 'Push Notifications',
                            subtitle: 'Receive alerts when belongings are scanned',
                            trailing: Switch(
                              value: _notificationsEnabled,
                              activeColor: Colors.white,
                              activeTrackColor: Colors.white38,
                              onChanged: (val) {
                                setState(() => _notificationsEnabled = val);
                                context.read<StorageService>().saveSetting('notifications_enabled', val);
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 4. [ SETTINGS & PRIVACY CARD ]
                  AnimatedCardEntrance(
                    delayMs: 120,
                    child: TracebackCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(4, 10, 4, 8),
                            child: TracebackSectionHeader(
                              title: 'SECURITY & PRIVACY',
                              subtitle: 'Finder masking and encrypted contact',
                            ),
                          ),
                          _buildProfileRow(
                            icon: Icons.shield_outlined,
                            title: 'Privacy & Token Masking',
                            subtitle: 'Hide contact until item verified by finder',
                            onTap: () => _showSecurityDialog(context),
                          ),
                          const Divider(color: TbColors.cardBorder, height: 1),
                          _buildProfileRow(
                            icon: Icons.help_outline_rounded,
                            title: 'Campus Lost & Found Desk',
                            subtitle: 'Main Gate contact, hours, and emergency help',
                            onTap: () => _showHelpSupportDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 5. [ LOGOUT CARD ]
                  AnimatedCardEntrance(
                    delayMs: 150,
                    child: InkWell(
                      onTap: _logout,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF140F0F),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x33DC2626)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Sign Out of Traceback',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFEF4444),
                              size: 20,
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
        );
      },
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TbColors.cardBorder),
              ),
              child: Icon(icon, color: Colors.white70, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: TbColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: TbColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}