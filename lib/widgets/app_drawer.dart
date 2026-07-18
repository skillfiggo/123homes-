// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../screens/add_property_screen.dart';
import '../screens/become_agent_screen.dart';
import '../screens/application_status_screen.dart';
import '../providers/app_state.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  static const _navItems = [
    _DrawerNavItem(icon: Icons.home_rounded,       label: 'Home'),
    _DrawerNavItem(icon: Icons.map_rounded,         label: 'Search & Maps'),
    _DrawerNavItem(icon: Icons.favorite_rounded,    label: 'Wishlist'),
    _DrawerNavItem(icon: Icons.chat_bubble_rounded, label: 'Inbox'),
    _DrawerNavItem(icon: Icons.person_rounded,      label: 'My Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Consumer<AppState>(
      builder: (ctx, state, _) => Drawer(
        width: MediaQuery.of(context).size.width * 0.82,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        backgroundColor: c.surface,
        child: Column(
          children: [
            _buildHeader(context, c),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNav(context, state, c),
                    _buildDivider(c),
                    _buildSettingsSection(context, state, c),
                    _buildDivider(c),
                    _buildFooter(context, c),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorSet c) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 18, 18, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.only(topRight: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Alex&backgroundColor=b6e3f4',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.white.withValues(alpha: 0.3)),
                    errorWidget: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alex Johnson',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('alex.johnson@email.com',
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNav(BuildContext context, AppState state, AppColorSet c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: _navItems.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final active = currentIndex == i;
          return _NavRow(
            item: item,
            active: active,
            colors: c,
            onTap: () {
              Navigator.of(context).pop();
              onNavigate(i);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, AppState state, AppColorSet c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 0, 6),
            child: Text('PREFERENCES',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: c.textLight, letterSpacing: 1.0)),
          ),
          _ToggleRow(
            icon: Icons.dark_mode_outlined,
            label: 'Dark Mode',
            value: state.isDarkMode,
            colors: c,
            onChanged: (_) => state.toggleDarkMode(),
          ),
          _ToggleRow(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            value: true,
            colors: c,
            onChanged: (_) {},
          ),
          _ToggleRow(
            icon: Icons.tune_rounded,
            label: 'Personalized Ads',
            value: false,
            colors: c,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppColorSet c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          // ── List a Property + Verification CTA ───────────────────────────
          Consumer<AppState>(
            builder: (ctx, state, _) => _buildVerificationCta(context, state, c),
          ),
          const SizedBox(height: 12),
          // ── Log Out ───────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await SupabaseService.signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
              label: const Text('Log Out',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFFF0F0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('123Homes  •  Version 1.0.2',
              style: TextStyle(fontSize: 11, color: c.textLight, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildVerificationCta(BuildContext context, AppState state, AppColorSet c) {
    return Column(
      children: [
        // Always: List a Property
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_home_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('List a Property', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Verification status CTA
        if (state.isVerified)
          // ✅ Verified badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 18),
                SizedBox(width: 8),
                Text('Verified Agent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
              ],
            ),
          )
        else if (state.applicationStatus == 'pending')
          // ⏳ Pending
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ApplicationStatusScreen()));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_top_rounded, color: Color(0xFFF97316), size: 16),
                  SizedBox(width: 8),
                  Text('Application Pending ⏳', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFC2410C))),
                ],
              ),
            ),
          )
        else if (state.applicationStatus == 'rejected')
          // ❌ Rejected — reapply
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BecomeAgentScreen()));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, color: Color(0xFFEF4444), size: 16),
                  SizedBox(width: 8),
                  Text('Reapply as Verified Agent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                ],
              ),
            ),
          )
        else
          // 🆕 Not applied — become agent
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BecomeAgentScreen()));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_outlined, color: c.primary, size: 16),
                  const SizedBox(width: 8),
                  Text('Get Verified ✨', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.primary)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDivider(AppColorSet c) => Container(
      height: 1, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: c.divider);
}

// ── Nav row ───────────────────────────────────────────────────────────────────
class _NavRow extends StatelessWidget {
  final _DrawerNavItem item;
  final bool active;
  final AppColorSet colors;
  final VoidCallback onTap;
  const _NavRow({required this.item, required this.active, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? c.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: active ? c.primary.withValues(alpha: 0.18) : c.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 17, color: active ? c.primary : c.textGrey),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(item.label,
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: active ? c.primary : c.textDark,
                  )),
            ),
            Icon(Icons.chevron_right_rounded, size: 18,
                color: active ? c.primary : c.divider),
          ],
        ),
      ),
    );
  }
}

// ── Toggle row ────────────────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final AppColorSet colors;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.icon, required this.label, required this.value, required this.colors, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: c.iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: c.textGrey),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textDark))),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _DrawerNavItem {
  final IconData icon;
  final String label;
  const _DrawerNavItem({required this.icon, required this.label});
}
