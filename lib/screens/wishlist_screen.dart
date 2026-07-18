// lib/screens/wishlist_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/property_card.dart';
import 'property_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Consumer<AppState>(
          builder: (ctx, state, _) {
            final saved = state.wishlisted;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      Text('My Wishlist',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textDark)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${saved.length}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.primary)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: saved.isEmpty
                      ? _buildEmpty(context, c)
                      : ListView.separated(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                          itemCount: saved.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (_, i) => PropertyCard(
                            property: saved[i],
                            onTap: () => Navigator.push(ctx,
                                MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: saved[i]))),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, AppColorSet c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.favorite_border_rounded, size: 32, color: c.primary),
          ),
          const SizedBox(height: 16),
          Text('No Saved Properties',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textDark)),
          const SizedBox(height: 8),
          Text('Tap the heart on any property to save it here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.textLight, height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Browse Properties', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
