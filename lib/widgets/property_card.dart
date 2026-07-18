// lib/widgets/property_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/property.dart';
import '../providers/app_state.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  const PropertyCard({super.key, required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final liked = state.isWishlisted(property.id);
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                AspectRatio(
                  aspectRatio: 1.6,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: property.imagePath.startsWith('http')
                              ? Image.network(
                                  property.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: c.primary.withValues(alpha: 0.1),
                                    child: Icon(Icons.home_rounded, size: 48, color: c.primary),
                                  ),
                                )
                              : Image.asset(
                                  property.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: c.primary.withValues(alpha: 0.1),
                                    child: Icon(Icons.home_rounded, size: 48, color: c.primary),
                                  ),
                                ),
                        ),
                      ),
                      // Promoted ⚡ badge (top-left when promoted)
                      if (property.isPromoted)
                        Positioned(
                          top: 10, left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('⚡', style: TextStyle(fontSize: 9)),
                                SizedBox(width: 3),
                                Text('Promoted', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      // Regular badge — shifts down when promoted
                      Positioned(
                        top: property.isPromoted ? 36 : 10, left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)),
                          child: Text(property.badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.primary)),
                        ),
                      ),
                      // Verified Agent badge
                      if (property.posterVerified)
                        Positioned(
                          bottom: 10, left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, color: Colors.white, size: 10),
                                SizedBox(width: 4),
                                Text('Verified Agent', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      // Heart
                      Positioned(
                        top: 10, right: 10,
                        child: GestureDetector(
                          onTap: () => state.toggleWishlist(property.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 16,
                              color: liked ? c.red : c.textLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              property.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textDark),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            property.price,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8, runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _meta(Icons.location_on_outlined, property.location, c),
                          _meta(Icons.star_rounded, '${property.rating}', c, starColor: true),
                          _meta(Icons.bed_outlined, '${property.beds} Beds', c),
                          _meta(Icons.bathtub_outlined, '${property.baths} Baths', c),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _meta(IconData icon, String text, AppColorSet c, {bool starColor = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: starColor ? c.star : c.textLight),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: c.textGrey)),
      ],
    );
  }
}
