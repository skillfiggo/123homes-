// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/property.dart';
import 'my_properties_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().refreshNotifications();
      }
    });
  }

  Future<void> _load() async {
    if (mounted) {
      await context.read<AppState>().refreshNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Consumer<AppState>(
      builder: (context, state, _) {
        final notifs = state.notifications;
        return Scaffold(
          backgroundColor: c.background,
          appBar: AppBar(
            backgroundColor: c.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: c.textDark),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Notifications',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.textDark)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: c.primary, size: 20),
                onPressed: _load,
              ),
            ],
          ),
          body: state.isLoadingNotifications
              ? const Center(child: CircularProgressIndicator())
              : notifs.isEmpty
                  ? _buildEmpty(c)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: notifs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _NotifCard(
                          notif: notifs[i],
                          onTap: () => _handleTap(notifs[i]),
                        ),
                      ),
                    ),
        );
      },
    );
  }

  void _handleTap(AppNotification notif) {
    switch (notif.type) {
      case NotificationType.listingApproved:
      case NotificationType.listingRejected:
      case NotificationType.listingPending:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyPropertiesScreen()));
      case NotificationType.newMessage:
        Navigator.pop(context); // go back, then messages tab handles it
    }
  }

  Widget _buildEmpty(AppColorSet c) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.notifications_none_rounded, size: 36, color: c.primary.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 20),
        Text('All caught up!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.textDark)),
        const SizedBox(height: 8),
        Text("You have no notifications right now.\nCheck back after listing a property.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c.textGrey, height: 1.6)),
      ]),
    );
  }
}

// ── Notification Card ─────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  const _NotifCard({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cfg = _config(notif.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cfg.borderColor.withValues(alpha: 0.25), width: 1.2),
          boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: cfg.iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(cfg.icon, size: 20, color: cfg.iconColor),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(notif.title,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.textDark)),
                    ),
                    const SizedBox(width: 8),
                    Text(_timeAgo(notif.time),
                        style: TextStyle(fontSize: 11, color: c.textLight)),
                  ]),
                  const SizedBox(height: 4),
                  Text(notif.body,
                      style: TextStyle(fontSize: 12, color: c.textGrey, height: 1.5)),
                  if (notif.type == NotificationType.listingRejected) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Tap to edit & resubmit →',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                    ),
                  ],
                  if (notif.type == NotificationType.listingApproved) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('View your listing →',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _NotifConfig _config(NotificationType type) {
    switch (type) {
      case NotificationType.listingApproved:
        return _NotifConfig(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFF16A34A),
        );
      case NotificationType.listingRejected:
        return _NotifConfig(
          icon: Icons.cancel_rounded,
          iconColor: const Color(0xFFEF4444),
          iconBg: const Color(0xFFFFF0F0),
          borderColor: const Color(0xFFEF4444),
        );
      case NotificationType.listingPending:
        return _NotifConfig(
          icon: Icons.hourglass_top_rounded,
          iconColor: const Color(0xFFF97316),
          iconBg: const Color(0xFFFFF7ED),
          borderColor: const Color(0xFFF97316),
        );
      case NotificationType.newMessage:
        return _NotifConfig(
          icon: Icons.chat_bubble_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBg: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFF2563EB),
        );
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final d = time.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _NotifConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color borderColor;
  const _NotifConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.borderColor,
  });
}
