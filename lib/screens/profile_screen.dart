// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../main.dart';
import 'login_screen.dart';
import 'my_properties_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Consumer<AppState>(
      builder: (ctx, state, _) => Scaffold(
        backgroundColor: c.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHero(context, state),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildMenuGroup(context, c, [
                      _MenuItem(
                        icon: Icons.favorite_border_rounded,
                        label: 'My Wishlist',
                        color: const Color(0xFFFF4757),
                        bg: const Color(0xFFFFF0F3),
                        onTap: () => MainShell.goToTab(context, TabIndex.wishlist),
                      ),
                      _MenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'My Messages',
                        color: const Color(0xFF2563EB),
                        bg: const Color(0xFFEFF6FF),
                        onTap: () => MainShell.goToMessages(context),
                      ),
                      _MenuItem(
                        icon: Icons.home_outlined,
                        label: 'My Properties',
                        color: const Color(0xFF22C55E),
                        bg: const Color(0xFFF0FDF4),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPropertiesScreen())),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _buildMenuGroup(context, c, [
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        color: const Color(0xFFF97316),
                        bg: const Color(0xFFFFF7ED),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                      ),
                      _MenuItem(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        color: const Color(0xFF64748B),
                        bg: const Color(0xFFF8FAFC),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _buildLogout(context, c),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, AppState state) {
    final fallbackAvatar = 'https://api.dicebear.com/7.x/initials/svg?seed=${Uri.encodeComponent(state.fullName)}&backgroundColor=b6e3f4';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)]),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showEditProfileModal(context, state),
            child: Stack(
              children: [
                Container(
                  width: 86, height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 4),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      state.avatarUrl ?? fallbackAvatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white.withValues(alpha: 0.3),
                        child: const Icon(Icons.person, color: Colors.white, size: 40)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded, size: 13, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(state.fullName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(state.email,
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          // Verification badge
          if (state.isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 13),
                  SizedBox(width: 5),
                  Text('Verified Agent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            )
          else if (state.applicationStatus == 'pending')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 5),
                  Text('Pending Verification', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(num: '${state.wishlistCount}', label: 'Saved'),
                const _StatDivider(),
                _StatItem(num: '${state.chatConversations.length}', label: 'Inquiries'),
                const _StatDivider(),
                _StatItem(num: '${state.allProperties.length}', label: 'Listings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(BuildContext context, AppColorSet c, List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          final item = e.value;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: e.key == 0 ? const Radius.circular(20) : Radius.zero,
                  bottom: isLast ? const Radius.circular(20) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: item.bg, borderRadius: BorderRadius.circular(10)),
                        child: Icon(item.icon, size: 17, color: item.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(item.label,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textDark))),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: c.textLight),
                    ],
                  ),
                ),
              ),
              if (!isLast) Divider(height: 1, indent: 68, color: c.divider),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogout(BuildContext context, AppColorSet c) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(16)),
      child: TextButton.icon(
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF4757), size: 18),
        label: const Text('Log Out',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFF4757))),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, AppState state) {
    final nameCtrl  = TextEditingController(text: state.fullName);
    final phoneCtrl = TextEditingController(text: state.phone ?? '');
    File? selectedImage;
    bool updating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = ctx.colors;
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final fallbackAvatar = 'https://api.dicebear.com/7.x/initials/svg?seed=${Uri.encodeComponent(state.fullName)}&backgroundColor=b6e3f4';
            return Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(modalCtx).viewInsets.bottom + 30),
              child: SingleChildScrollView(
               child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 5,
                    decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 20),
                  Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.textDark)),
                  const SizedBox(height: 24),
                  // Avatar Edit
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                      if (picked != null) {
                        setModalState(() {
                          selectedImage = File(picked.path);
                        });
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: c.primary.withValues(alpha: 0.2), width: 3),
                          ),
                          child: ClipOval(
                            child: selectedImage != null
                                ? Image.file(selectedImage!, fit: BoxFit.cover)
                                : Image.network(
                                    state.avatarUrl ?? fallbackAvatar,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Name field
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: c.textDark),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(color: c.textGrey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.primary),
                      ),
                      filled: true,
                      fillColor: c.background,
                    ),
                  ),

                  // Phone field — verified agents only
                  if (state.isVerified) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: c.textDark),
                      decoration: InputDecoration(
                        labelText: 'Contact Phone Number',
                        labelStyle: const TextStyle(color: Color(0xFF16A34A)),
                        hintText: 'e.g. +234 801 234 5678',
                        hintStyle: TextStyle(color: c.textLight, fontSize: 13),
                        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF16A34A), size: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF16A34A).withValues(alpha: 0.04),
                        helperText: 'Buyers see this when they tap "Show Number" on your profile',
                        helperStyle: TextStyle(fontSize: 11, color: c.textLight),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 13),
                        const SizedBox(width: 5),
                        Text('Visible on your Verified Agent card only',
                            style: TextStyle(fontSize: 11, color: c.textGrey)),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: updating
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) return;

                              setModalState(() { updating = true; });
                              try {
                                 await state.updateUserProfile(
                                   name: name,
                                   imageFile: selectedImage,
                                   phone: state.isVerified ? phoneCtrl.text : null,
                                 );
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Failed to update profile: $e')),
                                  );
                                }
                              } finally {
                                if (modalCtx.mounted) setModalState(() { updating = false; });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: updating
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
               ),
              ),
            );
          },
        );
      },
    );
  }
}


class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;
  const _MenuItem({required this.icon, required this.label, required this.color, required this.bg, this.onTap});
}

class _StatItem extends StatelessWidget {
  final String num, label;
  const _StatItem({required this.num, required this.label});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(num, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
    ],
  );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.25));
}
