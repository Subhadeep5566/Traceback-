import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isSaving = false;
  String? _savedApiKey;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final storage = context.read<StorageService>();
    final key = storage.getSetting('gemini_api_key') as String?;
    setState(() => _savedApiKey = key);
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      _showSnackBar('Please enter an API key', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final storage = context.read<StorageService>();
      await storage.saveSetting('gemini_api_key', key);
      setState(() => _savedApiKey = key);
      _apiKeyController.clear();
      _showSnackBar('API key saved successfully');
    } catch (e) {
      _showSnackBar('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearApiKey() async {
    final storage = context.read<StorageService>();
    await storage.saveSetting('gemini_api_key', '');
    setState(() => _savedApiKey = '');
    _showSnackBar('API key cleared');
  }

  Future<void> _logout() async {
    final auth = context.read<AuthService>();
    final provider = context.read<AssetProvider>();
    await provider.resetToProduction();
    await auth.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _showEditAdminDetailsDialog(BuildContext context, UserProfile profile, AuthService auth) {
    final nameCtrl = TextEditingController(text: profile.name);
    final emailCtrl = TextEditingController(text: profile.email);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final locationCtrl = TextEditingController(text: profile.officeLocation);
    final officeCtrl = TextEditingController(text: profile.office);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Official College Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter real official college contact information for the recovery desk.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: officeCtrl,
                decoration: InputDecoration(
                  labelText: 'Office / Department Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Officer / Staff Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Official BGU Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Official Contact Phone',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(
                  labelText: 'Desk / Office Location',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final updated = profile.copyWith(
                office: officeCtrl.text.trim(),
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                officeLocation: locationCtrl.text.trim(),
              );
              await auth.updateProfile(updated);
              _showSnackBar('Official recovery desk details updated.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final provider = context.watch<AssetProvider>();
    final profile = auth.currentUserProfile;
    final isStudent = profile.isStudent;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'PROFILE & SETTINGS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role Switcher Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isStudent ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isStudent ? const Color(0xFFBFDBFE) : const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isStudent ? Icons.school_rounded : Icons.shield_rounded,
                        color: isStudent ? const Color(0xFF1D4ED8) : const Color(0xFF047857),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTIVE ROLE: ${profile.role.displayName}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: isStudent ? const Color(0xFF1E40AF) : const Color(0xFF065F46),
                            ),
                          ),
                          Text(
                            isStudent ? 'Standard Student Account' : 'Authorized College Staff',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isStudent ? const Color(0xFF1D4ED8) : const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final newRole = isStudent ? UserRole.admin : UserRole.student;
                      await auth.switchRole(newRole);
                      _showSnackBar('Switched to ${newRole.displayName}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isStudent ? 'Switch to Admin' : 'Switch to Student',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Profile Information Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isStudent ? Colors.black : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            isStudent ? Icons.person_rounded : Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    profile.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isStudent ? const Color(0xFFE0F2FE) : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    profile.role.displayName,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: isStudent ? const Color(0xFF0284C7) : const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isStudent
                                  ? '${profile.department} • ${profile.college}'
                                  : '${profile.designation} • ${profile.office}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // Detail Rows
                  _buildProfileRow(Icons.alternate_email_rounded, 'Email', profile.email),
                  _buildProfileRow(Icons.phone_rounded, 'Phone', '+91 ${profile.phone}'),
                  if (isStudent) ...[
                    _buildProfileRow(Icons.badge_outlined, 'Student ID', profile.studentId),
                    _buildProfileRow(Icons.account_balance_rounded, 'College', profile.college),
                  ] else ...[
                    _buildProfileRow(Icons.business_rounded, 'Office', profile.office),
                    _buildProfileRow(Icons.location_on_outlined, 'Desk Location', profile.officeLocation),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditAdminDetailsDialog(context, profile, auth),
                        icon: const Icon(Icons.edit_outlined, size: 14, color: Colors.black),
                        label: const Text(
                          'Configure Official Recovery Desk Details',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Student Privacy Controls Card (only for student)
            if (isStudent) ...[
              _buildSectionHeader('PRIVACY & DISCLOSURE PREFERENCES'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Share Phone Number during verified recovery', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      subtitle: const Text('Allowed administrators can call you directly for handover', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      value: profile.sharePhone,
                      activeColor: Colors.black,
                      onChanged: (val) => auth.updateProfile(profile.copyWith(sharePhone: val)),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Share BGU Email during recovery', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      subtitle: const Text('Receive formal verification receipts via college email', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      value: profile.shareEmail,
                      activeColor: Colors.black,
                      onChanged: (val) => auth.updateProfile(profile.copyWith(shareEmail: val)),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Share Student ID with Staff on Handover', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      subtitle: const Text('Enables security desk to verify your student credentials quickly', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      value: profile.shareStudentId,
                      activeColor: Colors.black,
                      onChanged: (val) => auth.updateProfile(profile.copyWith(shareStudentId: val)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Belongings Statistics Overview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INVENTORY AUDIT',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('Total', '${provider.totalAssetCount}', Colors.black),
                      _buildMiniStat('Secure', '${provider.secureCount}', const Color(0xFF10B981)),
                      _buildMiniStat('Lost', '${provider.lostCount}', const Color(0xFFEF4444)),
                      _buildMiniStat('Recovered', '${provider.recoveredCount}', const Color(0xFF0EA5E9)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Features Section
            _buildSectionHeader('TRACEBACK AI'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text('Gemini API Key', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (_savedApiKey != null && _savedApiKey!.isNotEmpty)
                        TextButton(
                          onPressed: _clearApiKey,
                          child: const Text('Clear', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _savedApiKey != null && _savedApiKey!.isNotEmpty
                        ? 'Configured (${_maskApiKey(_savedApiKey!)})'
                        : 'Enter key to enable AI recovery assistant',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _apiKeyController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'AIzaSy...',
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSaving ? null : _saveApiKey,
                        child: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Developer / Diagnostic Tools (Hidden under expandable per Section 27)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                collapsedBackgroundColor: Colors.white,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE2E8F0))),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE2E8F0))),
                leading: const Icon(Icons.code_rounded, size: 18, color: Color(0xFF64748B)),
                title: const Text(
                  'Developer & Diagnostics',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                ),
                subtitle: const Text(
                  'Diagnostic tools & dataset reset',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Reset to Initial Production Data', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          subtitle: const Text('Reloads default campus belongings into local storage', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          trailing: OutlinedButton(
                            onPressed: () async {
                              await provider.resetToProduction();
                              _showSnackBar('Reset to default belongings');
                            },
                            child: const Text('Reset', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Test GPS Location Service', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          subtitle: const Text('Queries Geolocator coordinates and accuracy', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          trailing: OutlinedButton(
                            onPressed: () async {
                              final loc = await LocationService.getCurrentLocation();
                              _showSnackBar('GPS test: ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)} (±${loc.accuracy.toStringAsFixed(0)}m)');
                            },
                            child: const Text('Test', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFECDD3)),
                  foregroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text(
                  'SIGN OUT OF TRACEBACK',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  String _maskApiKey(String key) {
    if (key.length <= 8) return '****';
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }
}