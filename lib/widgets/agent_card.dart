// lib/widgets/agent_card.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/property.dart';
import '../screens/agent_profile_screen.dart';

class AgentCard extends StatelessWidget {
  final Agent agent;
  final int agentIndex;
  const AgentCard({super.key, required this.agent, required this.agentIndex});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AgentProfileScreen(agent: agent, agentIndex: agentIndex),
          ),
        );
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.primary.withValues(alpha: 0.25), width: 2.5),
            ),
            child: ClipOval(
              child: Image.network(agent.avatarUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: c.iconBg,
                  child: Icon(Icons.person, color: c.textLight))),
            ),
          ),
          const SizedBox(height: 8),
          Text(agent.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textDark)),
          const SizedBox(height: 2),
          Text(agent.role, style: TextStyle(fontSize: 11, color: c.textLight)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, size: 12, color: c.star),
              const SizedBox(width: 3),
              Text('${agent.rating}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.star)),
            ],
          ),
        ],
      ),
    ));
  }
}
