// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Consumer<AppState>(
      builder: (ctx, state, _) => Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: c.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Settings',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.textDark)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [

            // ── Appearance ──────────────────────────────────────────────────
            _SectionHeader(label: 'Appearance', c: c),
            _SettingsCard(c: c, children: [
              _ToggleRow(
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFF6366F1),
                iconBg: const Color(0xFFEEF2FF),
                label: 'Dark Mode',
                subtitle: 'Switch to a darker theme',
                value: state.isDarkMode,
                c: c,
                onChanged: (_) => state.toggleDarkMode(),
              ),
            ]),

            const SizedBox(height: 20),

            // ── Notifications ───────────────────────────────────────────────
            _SectionHeader(label: 'Notifications', c: c),
            _SettingsCard(c: c, children: [
              _ToggleRow(
                icon: Icons.home_outlined,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFF0FDF4),
                label: 'Listing Updates',
                subtitle: 'Approval & rejection alerts',
                value: state.notifListingUpdates,
                c: c,
                onChanged: (v) => state.setSetting('notifListingUpdates', v),
              ),
              _Divider(c: c),
              _ToggleRow(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                label: 'New Messages',
                subtitle: 'Alerts for incoming chat messages',
                value: state.notifNewMessages,
                c: c,
                onChanged: (v) => state.setSetting('notifNewMessages', v),
              ),
            ]),

            const SizedBox(height: 20),

            // ── Account ─────────────────────────────────────────────────────
            _SectionHeader(label: 'Account', c: c),
            _SettingsCard(c: c, children: [
              _ActionRow(
                icon: Icons.lock_reset_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                label: 'Change Password',
                subtitle: 'Send a password reset email',
                c: c,
                onTap: () => _resetPassword(context, state, c),
              ),
              _Divider(c: c),
              _ActionRow(
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFEF4444),
                iconBg: const Color(0xFFFFF0F0),
                label: 'Delete Account',
                subtitle: 'Permanently remove your account',
                labelColor: const Color(0xFFEF4444),
                c: c,
                onTap: () => _confirmDeleteAccount(context, c),
              ),
            ]),

            const SizedBox(height: 20),

            // ── About ───────────────────────────────────────────────────────
            _SectionHeader(label: 'About', c: c),
            _SettingsCard(c: c, children: [
              _InfoRow(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF64748B),
                iconBg: c.iconBg,
                label: 'App Version',
                value: '1.0.2',
                c: c,
              ),
              _Divider(c: c),
              _ActionRow(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF64748B),
                iconBg: c.iconBg,
                label: 'Terms of Service',
                c: c,
                onTap: () => _showDialog(context, 'Terms of Service',
                    '123Homes connects property seekers with verified listings in Nigeria. '
                    'By using the app you agree to our usage policies. '
                    'Listings are submitted by users and reviewed by our moderation team.'),
              ),
              _Divider(c: c),
              _ActionRow(
                icon: Icons.privacy_tip_outlined,
                iconColor: const Color(0xFF64748B),
                iconBg: c.iconBg,
                label: 'Privacy Policy',
                c: c,
                onTap: () => _showDialog(context, 'Privacy Policy',
                    'We collect only the data needed to provide the service. '
                    'Your profile, listings and messages are stored securely in Supabase. '
                    'We do not sell your personal data to third parties.'),
              ),
              _Divider(c: c),
              _ActionRow(
                icon: Icons.star_rate_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBg: const Color(0xFFFFFBEB),
                label: 'Rate 123Homes',
                c: c,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thanks for your support! ⭐'))),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _resetPassword(BuildContext context, AppState state, AppColorSet c) async {
    if (state.email.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.w800, color: c.textDark)),
        content: Text(
          'A password reset link will be sent to:\n${state.email}',
          style: TextStyle(color: c.textGrey, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: c.textGrey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await SupabaseService.sendPasswordReset(state.email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password reset email sent ✅'),
          backgroundColor: Color(0xFF16A34A),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
      }
    }
  }

  void _confirmDeleteAccount(BuildContext context, AppColorSet c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account?',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
        content: Text(
          'This permanently deletes your account, listings, and all data. This cannot be undone.',
          style: TextStyle(color: c.textGrey, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: c.textGrey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await SupabaseService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
      }
    }
  }

  void _showDialog(BuildContext context, String title, String body) {
    final c = context.colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: c.textDark)),
        content: Text(body, style: TextStyle(color: c.textGrey, height: 1.6)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable components ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final AppColorSet c;
  const _SectionHeader({required this.label, required this.c});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
    child: Text(label.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
            color: c.textLight, letterSpacing: 1.2)),
  );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final AppColorSet c;
  const _SettingsCard({required this.children, required this.c});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 12, offset: const Offset(0, 2))],
    ),
    child: Column(children: children),
  );
}

class _Divider extends StatelessWidget {
  final AppColorSet c;
  const _Divider({required this.c});
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 68, endIndent: 0, color: c.divider);
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String? subtitle;
  final bool value;
  final AppColorSet c;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    this.subtitle,
    required this.value,
    required this.c,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textDark)),
          if (subtitle != null)
            Text(subtitle!, style: TextStyle(fontSize: 12, color: c.textGrey)),
        ]),
      ),
      Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.primary,
      ),
    ]),
  );
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final AppColorSet c;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    this.subtitle,
    this.labelColor,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: labelColor ?? c.textDark)),
            if (subtitle != null)
              Text(subtitle!, style: TextStyle(fontSize: 12, color: c.textGrey)),
          ]),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 13, color: c.textLight),
      ]),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final AppColorSet c;
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(label, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: c.textDark)),
      ),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textLight)),
    ]),
  );
}
