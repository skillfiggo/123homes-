// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/property.dart';
import '../providers/app_state.dart';
import '../widgets/property_card.dart';
import '../widgets/agent_card.dart';
import 'property_detail_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filter = 'All';
  final _filters = ['All', 'House', 'Apartment', 'Serviced Apartment', 'Villa', 'Condo', 'Land'];
  final _filterImages = {
    'House':              'assets/images/house1.png',
    'Apartment':          'assets/images/apartment1.png',
    'Serviced Apartment': 'assets/images/service_apartment1.png',
    'Villa':              'assets/images/villa1.png',
    'Condo':              'assets/images/condo1.png',
    'Land':               'assets/images/kano_park.png',
  };

  List<Property> _filtered(List<Property> all) {
    if (_filter == 'All') return all;
    return all.where((p) => p.type.toLowerCase() == _filter.toLowerCase()).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().refreshNotifications();
      }
    });
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    // Refresh count when user comes back
    if (mounted) {
      context.read<AppState>().refreshNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Consumer<AppState>(
          builder: (ctx, state, _) {
            final filtered = _filtered(state.allProperties);
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(c, state.unreadNotificationCount)),
                SliverToBoxAdapter(child: _buildHero(c)),
                SliverToBoxAdapter(child: _buildFilterPills(c)),
                SliverToBoxAdapter(child: _buildSectionHeader('Recommended for You', c)),
                if (state.isLoadingProperties)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_work_outlined, size: 64, color: c.textLight),
                            const SizedBox(height: 16),
                            Text('No listings yet',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textDark)),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to list a property! Tap "List Property" in your profile to get started.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: c.textGrey, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: PropertyCard(property: filtered[i], onTap: () => _openDetail(filtered[i])),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                SliverToBoxAdapter(child: _buildSectionHeader('Top Agents', c)),
                SliverToBoxAdapter(child: _buildAgentsRow(state.agents, c)),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorSet c, int unreadCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => MainShell.openDrawer(context),
            child: _iconBtn(Icons.menu_rounded, c),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _openNotifications,
            child: _iconBtn(Icons.notifications_outlined, c, count: unreadCount),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.primary, width: 2.5),
              ),
              child: ClipOval(
                child: Image.network(
                  'https://api.dicebear.com/7.x/avataaars/svg?seed=Alex&backgroundColor=b6e3f4',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.person, color: c.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, AppColorSet c, {int count = 0}) {
    final showBadge = count > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, size: 20, color: c.textDark),
        ),
        if (showBadge)
          Positioned(
            top: -4, right: -4,
            child: Container(
              padding: count > 9
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: c.red,
                shape: count > 9 ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: count > 9 ? null : BorderRadius.circular(10),
                border: Border.all(color: c.surface, width: 1.5),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHero(AppColorSet c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontFamily: 'Inter', color: c.textDark, fontWeight: FontWeight.w800, fontSize: 26, height: 1.25),
                children: [
                  const TextSpan(text: 'Made for You\n'),
                  TextSpan(text: 'Explore Properties', style: TextStyle(color: c.primary)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, anim, __) => FadeTransition(
                  opacity: anim,
                  child: const SearchScreen(),
                ),
                transitionDuration: const Duration(milliseconds: 250),
              ),
            ),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(Icons.search_rounded, size: 20, color: c.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills(AppColorSet c) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final active = _filter == f;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? c.primary : c.surface,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: active ? c.primary : Colors.transparent, width: 2),
                boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  if (_filterImages[f] != null) ...[
                    ClipOval(
                      child: Image.asset(_filterImages[f]!, width: 22, height: 22, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(f, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: active ? Colors.white : c.textGrey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColorSet c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.textDark)),
          const Spacer(),
          Text('See All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.primary)),
        ],
      ),
    );
  }

  Widget _buildAgentsRow(List<Agent> agentList, AppColorSet c) {
    if (agentList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text('No verified agents yet.', style: TextStyle(color: c.textGrey, fontSize: 13)),
      );
    }
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: agentList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => AgentCard(agent: agentList[i], agentIndex: i),
      ),
    );
  }

  void _openDetail(Property p) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p)));
  }
}
