import 'package:flutter/material.dart';
import '../design/tb_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TRACEBACK SHARED WIDGETS
// All reusable UI components used across multiple screens.
// ─────────────────────────────────────────────────────────────────────────────

// ── TracebackStatusBadge ───────────────────────────────────────────────────────
/// Coloured status pill: LOST / SAFE / FOUND / RECOVERED with dot indicator
class TracebackStatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const TracebackStatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final label = Tb.statusLabel(status);
    final color = Tb.statusColor(status);
    final bg = Tb.statusDim(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Tb.r999),
        border: Border.all(color: color.withOpacity(0.35), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: small ? 5 : 6,
            height: small ? 5 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 9.5 : 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Backwards compatible alias
typedef TbStatusBadge = TracebackStatusBadge;

// ── TracebackCard ─────────────────────────────────────────────────────────────
/// Floating dark charcoal card with subtle border and floating surface shadow
class TracebackCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  const TracebackCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 22.0,
    this.onTap,
    this.clipBehavior = Clip.none,
  });

  @override
  State<TracebackCard> createState() => _TracebackCardState();
}

class _TracebackCardState extends State<TracebackCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: widget.margin,
      padding: widget.padding ?? const EdgeInsets.all(20),
      clipBehavior: widget.clipBehavior,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Tb.card,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: widget.borderColor ?? Tb.border,
          width: 1.0,
        ),
        boxShadow: Tb.cardShadow,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) {
      return cardContent;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.982 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: cardContent,
      ),
    );
  }
}

/// Backwards compatible alias for TbCard
class TbCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const TbCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return TracebackCard(
      padding: padding ?? const EdgeInsets.all(Tb.s16),
      borderColor: borderColor,
      onTap: onTap,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}

// ── TracebackStatCard ─────────────────────────────────────────────────────────
/// Compact statistics card for carousel / metrics
class TracebackStatCard extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;
  final Color? countColor;
  final Color? accentColor;
  final VoidCallback? onTap;
  final double width;

  const TracebackStatCard({
    super.key,
    required this.count,
    required this.label,
    required this.icon,
    this.countColor,
    this.accentColor,
    this.onTap,
    this.width = 114,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = countColor ?? Tb.textPrimary;
    final dotColor = accentColor ?? effectiveColor;

    return TracebackCard(
      onTap: onTap,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Tb.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Tb.borderSubtle),
                  ),
                  child: Icon(icon, size: 16, color: dotColor),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              count,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Tb.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── TracebackActionCard ───────────────────────────────────────────────────────
/// Compact floating action card with icon, title, description, and chevron
class TracebackActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBg;
  final VoidCallback onTap;

  const TracebackActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor,
    this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Tb.textPrimary;

    return TracebackCard(
      onTap: onTap,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg ?? Tb.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Tb.borderSubtle),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Tb.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Tb.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Tb.textMuted,
            size: 14,
          ),
        ],
      ),
    );
  }
}

enum TracebackItemStatus { lost, found, safe, recovered }

// ── TracebackItemCard ─────────────────────────────────────────────────────────
/// Standard floating belonging item card
class TracebackItemCard extends StatelessWidget {
  final IconData icon;
  final String? name;
  final String? title;
  final String tracebackId;
  final dynamic status;
  final String? location;
  final VoidCallback onTap;
  final Widget? trailing;

  const TracebackItemCard({
    super.key,
    required this.icon,
    this.name,
    this.title,
    required this.tracebackId,
    required this.status,
    this.location,
    required this.onTap,
    this.trailing,
  });

  String get _effectiveName => name ?? title ?? 'Item';

  String get _statusString {
    if (status is TracebackItemStatus) {
      switch (status as TracebackItemStatus) {
        case TracebackItemStatus.lost:
          return 'LOST';
        case TracebackItemStatus.found:
          return 'FOUND';
        case TracebackItemStatus.safe:
          return 'SAFE';
        case TracebackItemStatus.recovered:
          return 'RECOVERED';
      }
    }
    return status.toString();
  }

  @override
  Widget build(BuildContext context) {
    return TracebackCard(
      onTap: onTap,
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                child: Icon(icon, color: Tb.textPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _effectiveName,
                      style: const TextStyle(
                        color: Tb.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tracebackId,
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
              const SizedBox(width: 8),
              if (trailing != null)
                trailing!
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Tb.textMuted,
                  size: 14,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TracebackStatusBadge(status: _statusString, small: true),
              if (location != null && location!.isNotEmpty)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Tb.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          location!,
                          style: const TextStyle(
                            color: Tb.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── TracebackSectionHeader ────────────────────────────────────────────────────
class TracebackSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  const TracebackSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Tb.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            if (action != null)
              GestureDetector(
                onTap: onAction,
                child: Text(
                  action!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Tb.textPrimary,
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: const TextStyle(
              color: Tb.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Backwards compatible alias
typedef TbSectionHeader = TracebackSectionHeader;

// ── AnimatedCardEntrance ──────────────────────────────────────────────────────
/// Subtle entrance animation for cards (staggered fade & slide up)
class AnimatedCardEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final int? delayMs;
  final Duration duration;

  const AnimatedCardEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delayMs,
    this.duration = const Duration(milliseconds: 320),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDelayMs = delayMs ?? (index * 45).clamp(0, 300);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration + Duration(milliseconds: effectiveDelayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, animChild) {
        final opacity = value.clamp(0.0, 1.0);
        final offsetY = (1.0 - value) * 16.0;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: animChild,
          ),
        );
      },
      child: child,
    );
  }
}

// ── TracebackBottomNav ────────────────────────────────────────────────────────
class TracebackNavItem {
  final IconData icon;
  final String label;

  const TracebackNavItem({required this.icon, required this.label});
}

class TracebackBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<TracebackNavItem> items;
  final ValueChanged<int> onTabSelected;

  const TracebackBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 12,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF101012),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Tb.border, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (idx) {
            final item = items[idx];
            final isSelected = currentIndex == idx;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTabSelected(idx),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0x18FFFFFF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 21,
                        color: isSelected ? Colors.white : const Color(0xFF71717A),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF71717A),
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── TbAppBar ──────────────────────────────────────────────────────────────────
class TbAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? bottom;
  final double bottomHeight;

  const TbAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
    this.bottom,
    this.bottomHeight = 1,
  });

  @override
  Size get preferredSize => Size.fromHeight(56 + bottomHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Tb.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Tb.textPrimary),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Text(
        title,
        style: Tb.title.copyWith(letterSpacing: -0.2),
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(bottomHeight),
        child: bottom ?? const Divider(height: 1, color: Tb.border),
      ),
    );
  }
}

// ── TbButton ──────────────────────────────────────────────────────────────────
class TbButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final Color? color;
  final Color? textColor;

  const TbButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width,
    this.height = 48,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.white,
          foregroundColor: textColor ?? Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tb.r14)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
      ),
    );
  }
}

// ── TbEmptyState ──────────────────────────────────────────────────────────────
class TbEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TbEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Tb.s40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Tb.surface2,
                borderRadius: BorderRadius.circular(Tb.r20),
                border: Border.all(color: Tb.border),
              ),
              child: Icon(icon, size: 32, color: Tb.textMuted),
            ),
            const SizedBox(height: Tb.s20),
            Text(title, style: Tb.title.copyWith(color: Tb.textSecondary)),
            if (subtitle != null) ...[
              const SizedBox(height: Tb.s8),
              Text(
                subtitle!,
                style: Tb.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Tb.s24),
              TbButton(
                label: actionLabel!,
                onTap: onAction,
                width: 200,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── TbItemTile ────────────────────────────────────────────────────────────────
/// Standard dark item row used in lists
class TbItemTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String tracebackId;
  final String status;
  final String? subtitle;
  final VoidCallback? onTap;

  const TbItemTile({
    super.key,
    required this.icon,
    required this.name,
    required this.tracebackId,
    required this.status,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Tb.statusColor(status);
    final dim = Tb.statusDim(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Tb.s16),
        decoration: BoxDecoration(
          color: Tb.surface,
          borderRadius: BorderRadius.circular(Tb.r16),
          border: Border.all(color: Tb.border),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: dim,
                borderRadius: BorderRadius.circular(Tb.r12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: Tb.s12),
            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Tb.title.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: Tb.s2),
                  Text(
                    subtitle ?? tracebackId,
                    style: Tb.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Tb.s8),
            // Status + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TbStatusBadge(status: status, small: true),
                const SizedBox(height: Tb.s4),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Tb.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── TbTextField ───────────────────────────────────────────────────────────────
class TbTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool enabled;
  final TextInputAction? textInputAction;

  const TbTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      enabled: enabled,
      textInputAction: textInputAction,
      style: Tb.body.copyWith(color: Tb.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: Tb.textMuted) : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: Tb.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tb.r12),
          borderSide: const BorderSide(color: Tb.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tb.r12),
          borderSide: const BorderSide(color: Tb.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tb.r12),
          borderSide: const BorderSide(color: Tb.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tb.r12),
          borderSide: const BorderSide(color: Tb.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tb.r12),
          borderSide: const BorderSide(color: Tb.error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Tb.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Tb.textDisabled, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: Tb.s16, vertical: Tb.s16),
      ),
    );
  }
}

// ── TbDivider ─────────────────────────────────────────────────────────────────
class TbDivider extends StatelessWidget {
  const TbDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Tb.border);
  }
}

// ── TbInfoRow ─────────────────────────────────────────────────────────────────
/// A labelled info row used in detail screens
class TbInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const TbInfoRow({super.key, required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Tb.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: Tb.textMuted),
            const SizedBox(width: Tb.s8),
          ],
          Expanded(
            flex: 2,
            child: Text(label.toUpperCase(), style: Tb.label.copyWith(fontSize: 9)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '—' : value,
              style: Tb.body.copyWith(fontSize: 13, color: Tb.textSecondary),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── TbSettingsRow ─────────────────────────────────────────────────────────────
class TbSettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;

  const TbSettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Tb.s20, vertical: Tb.s14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Tb.surface2,
                borderRadius: BorderRadius.circular(Tb.r8),
              ),
              child: Icon(icon, size: 16, color: iconColor ?? Tb.textSecondary),
            ),
            const SizedBox(width: Tb.s14),
            Expanded(
              child: Text(label, style: Tb.body.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (value != null)
              Text(value!, style: Tb.caption),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(Icons.chevron_right_rounded, size: 16, color: Tb.textMuted),
          ],
        ),
      ),
    );
  }
}
