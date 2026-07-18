// lib/screens/agent_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/property.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';
import 'property_detail_screen.dart';
import 'messages_screen.dart';
import '../widgets/property_card.dart';

class AgentProfileScreen extends StatefulWidget {
  final Agent agent;
  final int agentIndex;
  const AgentProfileScreen({super.key, required this.agent, required this.agentIndex});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── Phone reveal ──────────────────────────────────────────────
  bool _numberRevealed = false;
  late final AnimationController _revealCtrl;

  // ── Reviews ───────────────────────────────────────────────────
  List<Review> _reviews   = [];
  bool _loadingReviews    = false;
  int? _myExistingRating;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    if (widget.agent.uid != null) {
      _loadReviews();
      _loadMyRating();
    }
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final reviews = await SupabaseService.fetchAgentReviews(widget.agent.uid!);
      if (mounted) setState(() { _reviews = reviews; _loadingReviews = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _loadMyRating() async {
    try {
      final r = await SupabaseService.fetchMyReviewForAgent(widget.agent.uid!);
      if (mounted) setState(() => _myExistingRating = r);
    } catch (_) {}
  }

  void _revealNumber() {
    setState(() => _numberRevealed = true);
    _revealCtrl.forward();
  }

  Future<void> _dialNumber(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(ClipboardData(text: phone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Number copied: $phone'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // ── Rate-agent bottom sheet ───────────────────────────────────
  void _showRateSheet() {
    int selectedStars = _myExistingRating ?? 0;
    final commentCtrl = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = ctx.colors;
        return StatefulBuilder(builder: (sheetCtx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(width: 40, height: 5,
                      decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text('Rate ${widget.agent.name}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.textDark)),
                  const SizedBox(height: 6),
                  Text('Tap a star to rate this agent',
                      style: TextStyle(fontSize: 13, color: c.textGrey)),
                  const SizedBox(height: 22),

                  // Star row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final filled = i < selectedStars;
                      return GestureDetector(
                        onTap: () => setSheet(() => selectedStars = i + 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 44,
                            color: filled ? const Color(0xFFF59E0B) : c.textLight,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (selectedStars > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent'][selectedStars],
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Comment field
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    style: TextStyle(color: c.textDark, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Leave a comment (optional)…',
                      hintStyle: TextStyle(color: c.textLight, fontSize: 13),
                      filled: true,
                      fillColor: c.background,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (submitting || selectedStars == 0) ? null : () async {
                        setSheet(() => submitting = true);
                        try {
                          await SupabaseService.submitReview(
                            agentUid: widget.agent.uid!,
                            rating: selectedStars,
                            comment: commentCtrl.text,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadReviews();
                          setState(() => _myExistingRating = selectedStars);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('Review submitted! ⭐'),
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ));
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Error: $e'),
                                    backgroundColor: Colors.red));
                          }
                        } finally {
                          if (sheetCtx.mounted) setSheet(() => submitting = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: submitting
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _myExistingRating != null ? 'Update Review' : 'Submit Review',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isOwnProfile = SupabaseService.currentUser?.id == widget.agent.uid;

    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final agentProperties = state.allProperties
            .where((p) => p.agentIndex == widget.agentIndex)
            .toList();

        return Scaffold(
          backgroundColor: c.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, c),
              SliverToBoxAdapter(
                child: Column(children: [
                  _buildAgentDetails(context, c),
                  const SizedBox(height: 20),
                  _buildStatsRow(c, agentProperties.length),
                  if (widget.agent.uid != null) ...[
                    const SizedBox(height: 20),
                    _buildReviewsSection(c),
                  ],
                  const SizedBox(height: 24),
                  _buildPropertiesHeader(c, agentProperties.length),
                ]),
              ),
              if (agentProperties.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.home_work_outlined, size: 48, color: c.textLight),
                    const SizedBox(height: 12),
                    Text('No active listings',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textGrey)),
                  ])),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 12,
                      mainAxisSpacing: 12, childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final prop = agentProperties[index];
                      return PropertyCard(
                        property: prop,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: prop))),
                      );
                    }, childCount: agentProperties.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, c, isOwnProfile),
        );
      },
    );
  }

  // ── App bar ──────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, AppColorSet c) {
    return SliverAppBar(
      expandedHeight: 120, pinned: true, elevation: 0,
      backgroundColor: c.surface,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: c.background, shape: BoxShape.circle),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: c.textDark),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [c.primary.withValues(alpha: 0.15), c.surface],
            ),
          ),
        ),
      ),
    );
  }

  // ── Agent details card ───────────────────────────────────────
  Widget _buildAgentDetails(BuildContext context, AppColorSet c) {
    final phone    = widget.agent.phone;
    final hasPhone = phone != null && phone.isNotEmpty;
    final rc       = widget.agent.reviewCount;
    final rating   = widget.agent.rating;

    return Container(
      color: c.surface,
      width: double.infinity,
      child: Column(children: [
        // Avatar
        Stack(children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.primary.withValues(alpha: 0.25), width: 3),
              boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: ClipOval(child: Image.network(widget.agent.avatarUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: c.iconBg,
                    child: Icon(Icons.person, color: c.textLight, size: 40)))),
          ),
          Positioned(
            bottom: 0, right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 20),
            ),
          ),
        ]),
        const SizedBox(height: 14),

        // Name
        Text(widget.agent.name,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.textDark)),
        const SizedBox(height: 4),
        Text(widget.agent.role,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textGrey)),
        const SizedBox(height: 10),

        // Rating display — real or "No ratings yet"
        rc == 0
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.star_outline_rounded, size: 16, color: c.textLight),
                const SizedBox(width: 5),
                Text('No ratings yet',
                    style: TextStyle(fontSize: 13, color: c.textLight, fontWeight: FontWeight.w500)),
              ])
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.star_rounded, size: 16, color: c.star),
                const SizedBox(width: 4),
                Text('$rating',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.star)),
                const SizedBox(width: 4),
                Text('($rc ${rc == 1 ? 'review' : 'reviews'})',
                    style: TextStyle(fontSize: 12, color: c.textGrey)),
              ]),

        const SizedBox(height: 20),

        // Phone reveal
        if (hasPhone)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _numberRevealed
                  ? _buildRevealedNumber(c, phone)
                  : _buildShowNumberButton(c),
            ),
          ),
        const SizedBox(height: 14),
      ]),
    );
  }

  Widget _buildShowNumberButton(AppColorSet c) => GestureDetector(
    key: const ValueKey('show_btn'),
    onTap: _revealNumber,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.primary.withValues(alpha: 0.5), width: 1.5),
        color: c.primary.withValues(alpha: 0.06),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.phone_outlined, size: 17, color: c.primary),
        const SizedBox(width: 8),
        Text('Show Phone Number',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.primary)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(6)),
          child: const Text('TAP',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ]),
    ),
  );

  Widget _buildRevealedNumber(AppColorSet c, String phone) => GestureDetector(
    key: const ValueKey('number_revealed'),
    onTap: () => _dialNumber(phone),
    child: Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: [
          const Color(0xFF16A34A).withValues(alpha: 0.12),
          const Color(0xFF16A34A).withValues(alpha: 0.06),
        ]),
        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A), shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.35), blurRadius: 8)],
          ),
          child: const Icon(Icons.phone_rounded, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 12),
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(phone, style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800,
              color: Color(0xFF16A34A), letterSpacing: 0.5)),
          const Text('Tap to call',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF16A34A))),
        ]),
        const SizedBox(width: 10),
        const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF16A34A)),
      ]),
    ),
  );

  // ── Stats row ────────────────────────────────────────────────
  Widget _buildStatsRow(AppColorSet c, int activeListings) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: BoxDecoration(
      color: c.surface, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _statCol(c, '$activeListings', 'Listings'),
      _divider(c),
      _statCol(c, '5+', 'Years Exp'),
      _divider(c),
      _statCol(c, '98%', 'Success'),
    ]),
  );

  Widget _statCol(AppColorSet c, String val, String label) => Column(children: [
    Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textDark)),
    const SizedBox(height: 3),
    Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.textGrey)),
  ]);

  Widget _divider(AppColorSet c) => Container(width: 1, height: 28, color: c.divider);

  // ── Reviews section ──────────────────────────────────────────
  Widget _buildReviewsSection(AppColorSet c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.surface, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Icon(Icons.reviews_rounded, size: 16, color: c.primary),
            const SizedBox(width: 8),
            Text('Reviews', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.textDark)),
            const Spacer(),
            if (_myExistingRating != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(children: [
                  const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 3),
                  Text('You rated $_myExistingRating',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309))),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 12),

        // Loading / empty / list
        if (_loadingReviews)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text('No reviews yet. Be the first to rate this agent!',
                style: TextStyle(fontSize: 13, color: c.textGrey)),
          )
        else
          ..._reviews.take(3).map((r) => _buildReviewTile(c, r)),

        if (_reviews.length > 3)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text('+${_reviews.length - 3} more reviews',
                style: TextStyle(fontSize: 12, color: c.textLight)),
          )
        else
          const SizedBox(height: 4),
      ]),
    );
  }

  Widget _buildReviewTile(AppColorSet c, Review r) {
    final fallback = 'https://api.dicebear.com/7.x/initials/svg?seed=${Uri.encodeComponent(r.reviewerName)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 18,
            backgroundImage: NetworkImage(r.reviewerAvatar ?? fallback),
            backgroundColor: c.iconBg),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(r.reviewerName,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textDark)),
            const Spacer(),
            // Stars
            Row(children: List.generate(5, (i) => Icon(
              i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 13, color: const Color(0xFFF59E0B),
            ))),
          ]),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(r.comment!, style: TextStyle(fontSize: 12, color: c.textGrey, height: 1.4)),
          ],
        ])),
      ]),
    );
  }

  Widget _buildPropertiesHeader(AppColorSet c, int count) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      Text('Active Listings ($count)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textDark)),
    ]),
  );

  // ── Bottom bar ───────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context, AppColorSet c, bool isOwnProfile) {
    final hasUid   = widget.agent.uid != null;
    final canRate  = hasUid && !isOwnProfile;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
          color: c.surface, border: Border(top: BorderSide(color: c.divider))),
      child: SafeArea(
        child: Row(children: [
          // Chat button
          Expanded(
            flex: canRate ? 6 : 10,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  final convId = await SupabaseService.getOrCreateConversation(widget.agent.id);
                  if (!context.mounted) return;
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>
                          ChatScreen(convId: convId, agentIndex: widget.agentIndex)));
                  if (context.mounted) context.read<AppState>().refreshConversations();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to open chat: $e')));
                  }
                }
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Chat with Agent',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),

          // Rate button
          if (canRate) ...[
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: ElevatedButton(
                onPressed: _showRateSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _myExistingRating != null
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFFFF7ED),
                  foregroundColor: const Color(0xFFB45309),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFFDE68A)),
                  ),
                  elevation: 0,
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    _myExistingRating != null ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 18, color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _myExistingRating != null ? '$_myExistingRating★' : 'Rate',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
