import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ContactCardType {
  owner,
  admin,
}

class ContactCard extends StatelessWidget {
  final ContactCardType cardType;
  final String title;
  final String subtitle;
  final String email;
  final String phone;
  final String? extraInfo; // e.g., Student ID or Office Location
  final String? extraLabel; // e.g., 'Student ID' or 'Office'
  final String? department;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;

  const ContactCard({
    super.key,
    required this.cardType,
    required this.title,
    required this.subtitle,
    required this.email,
    required this.phone,
    this.extraInfo,
    this.extraLabel,
    this.department,
    this.onCall,
    this.onEmail,
  });

  factory ContactCard.owner({
    Key? key,
    required String name,
    required String email,
    required String phone,
    String? studentId,
    String? department,
    VoidCallback? onCall,
    VoidCallback? onEmail,
  }) {
    return ContactCard(
      key: key,
      cardType: ContactCardType.owner,
      title: name,
      subtitle: 'BGU Student',
      email: email,
      phone: phone,
      extraInfo: studentId,
      extraLabel: 'Student ID',
      department: department ?? 'Birla Global University',
      onCall: onCall,
      onEmail: onEmail,
    );
  }

  factory ContactCard.admin({
    Key? key,
    String? adminName,
    String? office,
    String? designation,
    required String email,
    required String phone,
    String? officeLocation,
    VoidCallback? onCall,
    VoidCallback? onEmail,
  }) {
    return ContactCard(
      key: key,
      cardType: ContactCardType.admin,
      title: office ?? 'BGU Asset Recovery Office',
      subtitle: designation ?? 'Campus Property & Security Office',
      email: email,
      phone: phone,
      extraInfo: officeLocation ?? 'Administrative Block, Ground Floor, Room G-04',
      extraLabel: 'Office Location',
      department: adminName ?? 'Birla Global University Security',
      onCall: onCall,
      onEmail: onEmail,
    );
  }

  void _triggerAction(BuildContext context, String action, String target) {
    Clipboard.setData(ClipboardData(text: target));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              action == 'Call' ? Icons.phone_in_talk_rounded : Icons.email_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$action: $target (Copied to clipboard)',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = cardType == ContactCardType.owner;
    final headerBadge = isOwner ? 'REGISTERED OWNER' : 'CAMPUS RECOVERY DESK';
    final badgeColor = isOwner ? const Color(0xFF0284C7) : const Color(0xFF10B981);
    final badgeBg = isOwner ? const Color(0xFFE0F2FE) : const Color(0xFFECFDF5);
    final icon = isOwner ? Icons.person_outline_rounded : Icons.verified_user_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge & Type Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: badgeColor),
                    const SizedBox(width: 5),
                    Text(
                      headerBadge,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'AUTHORIZED CONTACT',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name & Subtitle
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            department != null ? '$subtitle • $department' : subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Contact Items List
          if (email.isNotEmpty)
            _buildInfoRow(Icons.alternate_email_rounded, 'Email', email),
          if (phone.isNotEmpty)
            _buildInfoRow(Icons.phone_rounded, 'Phone', phone),
          if (extraInfo != null && extraInfo!.isNotEmpty)
            _buildInfoRow(
              isOwner ? Icons.badge_outlined : Icons.location_on_outlined,
              extraLabel ?? 'Detail',
              extraInfo!,
            ),

          const SizedBox(height: 14),

          // Action Buttons: Call & Email
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (onCall != null) {
                      onCall!();
                    } else {
                      _triggerAction(context, 'Call', phone);
                    }
                  },
                  icon: const Icon(Icons.call_rounded, size: 14, color: Colors.black),
                  label: const Text(
                    'Call',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (onEmail != null) {
                      onEmail!();
                    } else {
                      _triggerAction(context, 'Email', email);
                    }
                  },
                  icon: const Icon(Icons.email_outlined, size: 14, color: Colors.white),
                  label: const Text(
                    'Email',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static void showOwnerSheet({
    required BuildContext context,
    required String name,
    required String email,
    required String phone,
    String? studentId,
    String? department,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                'CONTACT OWNER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              ContactCard.owner(
                name: name,
                email: email,
                phone: phone,
                studentId: studentId,
                department: department,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showAdminSheet({
    required BuildContext context,
    String? adminName,
    String? office,
    String? designation,
    required String email,
    required String phone,
    String? officeLocation,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                'OFFICIAL RECOVERY DESK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              ContactCard.admin(
                adminName: adminName,
                office: office,
                designation: designation,
                email: email,
                phone: phone,
                officeLocation: officeLocation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
