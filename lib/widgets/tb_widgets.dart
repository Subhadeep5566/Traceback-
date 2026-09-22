import 'package:flutter/material.dart';
import '../design/tb_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TRACEBACK SHARED WIDGETS
// All reusable UI components used across multiple screens.
// ─────────────────────────────────────────────────────────────────────────────

// ── TbStatusBadge ─────────────────────────────────────────────────────────────
/// Coloured status pill: LOST / SAFE / FOUND / RECOVERED
class TbStatusBadge extends StatelessWidget {
  final String status; // raw status string from Asset.status.name
  final bool small;

  const TbStatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final label = Tb.statusLabel(status);
    final color = Tb.statusColor(status);
    final bg = Tb.statusDim(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? Tb.s6 : Tb.s8,
        vertical: small ? 2 : Tb.s4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Tb.r6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: small ? 9 : 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── TbButton ──────────────────────────────────────────────────────────────────
enum TbButtonVariant { primary, secondary, ghost, danger }

class TbButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TbButtonVariant variant;
  final VoidCallback? onTap;
  final bool loading;
  final double? width;
  final double height;

  const TbButton({
    super.key,
    required this.label,
    this.icon,
    this.variant = TbButtonVariant.primary,
    this.onTap,
    this.loading = false,
    this.width,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BoxBorder? border;

    switch (variant) {
      case TbButtonVariant.primary:
        bg = Tb.accent;
        fg = Colors.white;
        break;
      case TbButtonVariant.secondary:
        bg = Tb.surface2;
        fg = Tb.textPrimary;
        border = Border.all(color: Tb.borderStrong);
        break;
      case TbButtonVariant.ghost:
        bg = Colors.transparent;
        fg = Tb.textSecondary;
        border = Border.all(color: Tb.border);
        break;
      case TbButtonVariant.danger:
        bg = Tb.errorDim;
        fg = Tb.error;
        border = Border.all(color: Tb.error.withOpacity(0.3));
        break;
    }

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Tb.r12),
          border: border,
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17, color: fg),
                    const SizedBox(width: Tb.s8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: fg,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── TbCard ────────────────────────────────────────────────────────────────────
/// Dark surface card with optional border highlight
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(Tb.s16),
        decoration: BoxDecoration(
          color: backgroundColor ?? Tb.surface,
          borderRadius: BorderRadius.circular(Tb.r16),
          border: Border.all(
            color: borderColor ?? Tb.border,
            width: borderColor != null ? 1.5 : 1.0,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ── TbSectionHeader ───────────────────────────────────────────────────────────
class TbSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const TbSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: Tb.label),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Tb.accent,
              ),
            ),
          ),
      ],
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
