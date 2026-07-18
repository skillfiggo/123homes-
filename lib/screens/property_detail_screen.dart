// lib/screens/property_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/property.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';
import '../main.dart';
import 'messages_screen.dart';
import 'agent_profile_screen.dart';

class PropertyDetailScreen extends StatelessWidget {
  final Property property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final agentList = context.read<AppState>().agents;
    
    Agent? resolvedAgent = property.agent;
    if (resolvedAgent == null && property.posterUid != null && agentList.isNotEmpty) {
      try {
        resolvedAgent = agentList.firstWhere((a) => a.uid == property.posterUid);
      } catch (_) {}
    }

    final idx = agentList.isEmpty ? 0 : property.agentIndex.clamp(0, agentList.length - 1);
    final agent = resolvedAgent ?? (agentList.isEmpty
        ? const Agent(id: 0, name: 'Agent', role: 'Verified Agent',
            avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=agent', rating: 4.8)
        : agentList[idx]);
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildImageSection(context, agent)),
          SliverToBoxAdapter(child: _buildBody(context, agent, c)),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext ctx, Agent agent) {
    return Stack(
      children: [
        SizedBox(
          height: 300, width: double.infinity,
          child: property.imagePath.startsWith('http')
              ? Image.network(
                  property.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppColors.primary.withValues(alpha: 0.2)),
                )
              : Image.asset(
                  property.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
        ),
        Positioned(
          top: 52, left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textDark),
            ),
          ),
        ),
        Positioned(
          bottom: 80, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == 0 ? 18 : 6, height: 6,
              decoration: BoxDecoration(
                color: i == 0 ? Colors.white : Colors.white54,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        ),
        Positioned(
          bottom: 16, left: 16, right: 16,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => AgentProfileScreen(agent: agent, agentIndex: property.agentIndex),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 18, backgroundImage: NetworkImage(agent.avatarUrl), backgroundColor: Colors.grey[200]),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(agent.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          Text(agent.role, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                          if (property.posterVerified)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, color: Colors.white, size: 9),
                                    SizedBox(width: 3),
                                    Text('Verified', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    Text(property.sqft, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    const Text('sq ft', style: TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext ctx, Agent agent, AppColorSet c) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final liked = state.isWishlisted(property.id);
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Text(property.floors,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textDark)),
                          const Spacer(),
                          Icon(Icons.keyboard_arrow_down_rounded, color: c.textLight),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _smBtn(Icons.location_on_outlined, c),
                  const SizedBox(width: 10),
                  _smBtn(Icons.open_in_new_rounded, c),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text(property.name,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.textDark))),
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.open_in_new_rounded, size: 16, color: c.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('₦', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.primary)),
                  const SizedBox(width: 2),
                  Text(property.price.replaceAll('₦', ''),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.textDark)),
                  const SizedBox(width: 6),
                  Text('/ Sq ft', style: TextStyle(fontSize: 13, color: c.textLight)),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: property.tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(20)),
                  child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textGrey)),
                )).toList(),
              ),
              const SizedBox(height: 14),
              Text(property.description,
                  style: TextStyle(fontSize: 14, color: c.textGrey, height: 1.6)),
              const SizedBox(height: 18),
              Row(
                children: [
                  _infoCell(Icons.bed_outlined, '${property.beds} Beds', c),
                  const SizedBox(width: 10),
                  _infoCell(Icons.bathtub_outlined, '${property.baths} Baths', c),
                  const SizedBox(width: 10),
                  _infoCell(Icons.location_on_outlined, property.location, c),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final agentId = agent.id;
                        // Create / find conv
                        try {
                          final convId = await SupabaseService.getOrCreateConversation(agentId);
                          if (!ctx.mounted) return;
                          // Navigate to chat directly
                          await Navigator.push(
                            ctx,
                            MaterialPageRoute(builder: (_) =>
                                ChatScreen(convId: convId, agentIndex: property.agentIndex)),
                          );
                          // Refresh conversation list in state
                          if (ctx.mounted) ctx.read<AppState>().refreshConversations();
                        } catch (e, s) {
                          debugPrint('Error in Contact Agent: $e\n$s');
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error contacting agent: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          // Fallback: just go to Messages tab
                          Navigator.pop(ctx);
                          MainShell.goToMessages(ctx);
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: const Text('Contact Agent',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => state.toggleWishlist(property.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: liked ? c.red : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.red.withValues(alpha: liked ? 1.0 : 0.5), width: 2),
                      ),
                      child: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: liked ? Colors.white : c.red, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _smBtn(IconData icon, AppColorSet c) {
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 20, color: c.textGrey),
    );
  }

  Widget _infoCell(IconData icon, String label, AppColorSet c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, size: 20, color: c.primary),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textGrey)),
          ],
        ),
      ),
    );
  }
}
