// lib/screens/application_status_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import 'become_agent_screen.dart';

class ApplicationStatusScreen extends StatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  State<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await context.read<AppState>().refreshProfile();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AppState>();
    final status = state.applicationStatus;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: c.surface,
                boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 12, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: c.textDark),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Verification Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.textDark)),
                  ),
                  // Refresh button
                  GestureDetector(
                    onTap: _refreshing ? null : _refresh,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _refreshing
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
                            )
                          : Icon(Icons.refresh_rounded, size: 20, color: c.primary),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: c.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: _buildStatusBody(context, c, status, state),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBody(BuildContext context, AppColorSet c, String? status, AppState state) {
    if (status == 'approved' || state.isVerified) {
      return _buildApproved(context, c);
    } else if (status == 'rejected') {
      return _buildRejected(context, c, state.applicationAdminNote);
    } else {
      return _buildPending(context, c);
    }
  }

  Widget _buildPending(BuildContext context, AppColorSet c) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90, height: 90,
          decoration: const BoxDecoration(color: Color(0xFFFFF7ED), shape: BoxShape.circle),
          child: const Center(
            child: SizedBox(
              width: 44, height: 44,
              child: CircularProgressIndicator(color: Color(0xFFF97316), strokeWidth: 3),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Application Under Review',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textDark)),
        const SizedBox(height: 12),
        Text(
          'We\'ve received your application and it\'s being reviewed by our team. This usually takes 24–48 hours.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: c.textGrey, height: 1.6),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_top_rounded, color: Color(0xFFF97316), size: 18),
              SizedBox(width: 8),
              Text('Pending Review', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFC2410C))),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Hint to pull-to-refresh
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swipe_down_rounded, size: 15, color: c.textLight),
            const SizedBox(width: 6),
            Text(
              'Pull down or tap ↻ to check for updates',
              style: TextStyle(fontSize: 12, color: c.textLight),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApproved(BuildContext context, AppColorSet c) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90, height: 90,
          decoration: const BoxDecoration(color: Color(0xFFF0FDF4), shape: BoxShape.circle),
          child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 48),
        ),
        const SizedBox(height: 24),
        Text('You\'re a Verified Agent! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textDark)),
        const SizedBox(height: 12),
        Text(
          'Congratulations! Your verification has been approved. Your listings now display the Verified Agent badge.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: c.textGrey, height: 1.6),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
              SizedBox(width: 8),
              Text('Verified Agent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Back to Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildRejected(BuildContext context, AppColorSet c, String? adminNote) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(color: c.red.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.cancel_rounded, color: c.red, size: 48),
        ),
        const SizedBox(height: 24),
        Text('Application Not Approved',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textDark)),
        const SizedBox(height: 12),
        Text(
          'Unfortunately, your verification application was not approved at this time.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: c.textGrey, height: 1.6),
        ),
        if (adminNote != null && adminNote.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.red.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reason:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.red)),
                const SizedBox(height: 4),
                Text(adminNote, style: TextStyle(fontSize: 13, color: c.textGrey, height: 1.5)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BecomeAgentScreen()),
              );
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reapply', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Back to Home', style: TextStyle(color: c.textGrey, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
