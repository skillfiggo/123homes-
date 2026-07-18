// lib/screens/maps_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/property.dart';
import '../providers/app_state.dart';
import 'property_detail_screen.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});
  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final _search = TextEditingController();
  final _mapController = MapController();
  List<Property> _results = [];
  Property? _selected;

  static const _lagos = LatLng(6.455, 3.435);

  void _filter(List<Property> all) {
    final q = _search.text.toLowerCase();
    setState(() {
      _results = q.isEmpty
          ? List.from(all)
          : all.where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q)).toList();
    });
  }

  void _focusProperty(Property p) {
    setState(() => _selected = p);
    _mapController.move(LatLng(p.lat, p.lng), 14.5);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final all = context.watch<AppState>().allProperties;

    // Keep _results in sync when Supabase data loads or list changes
    if (_results.isEmpty && all.isNotEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _results = List.from(all));
      });
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildSearchBar(all, c),
            _buildMap(c),
            _buildResultsPanel(c),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(List<Property> all, AppColorSet c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: c.textLight),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => _filter(all),
                      style: TextStyle(color: c.textDark, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by location, city…',
                        hintStyle: TextStyle(color: c.textLight, fontSize: 14),
                        border: InputBorder.none, isDense: true,
                      ),
                    ),
                  ),
                  if (_search.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _search.clear();
                        _filter(all);
                      },
                      child: Icon(Icons.close_rounded, size: 16, color: c.textLight),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Icon(Icons.tune_rounded, size: 20, color: c.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(AppColorSet c) {
    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 24, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _lagos,
            initialZoom: 13.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.homes123.app',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: _results.map((p) {
                final isSelected = _selected?.id == p.id;
                return Marker(
                  point: LatLng(p.lat, p.lng),
                  width: isSelected ? 130 : 110,
                  height: 42,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selected = p);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p)));
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryDark : AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: isSelected ? 0.6 : 0.35),
                            blurRadius: isSelected ? 14 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipOval(
                            child: p.imagePath.startsWith('http')
                                ? Image.network(p.imagePath, width: 20, height: 20, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 20, height: 20,
                                        color: Colors.white.withValues(alpha: 0.3)))
                                : Image.asset(p.imagePath, width: 20, height: 20, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 20, height: 20,
                                        color: Colors.white.withValues(alpha: 0.3))),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(p.name.split(' ')[0],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                              overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsPanel(AppColorSet c) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                Text('Nearby Properties',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.textDark)),
                const Spacer(),
                Text('${_results.length} Found',
                    style: TextStyle(fontSize: 13, color: c.textLight, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _buildMapCard(_results[i], c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(Property p, AppColorSet c) {
    final isSelected = _selected?.id == p.id;
    return GestureDetector(
      onTap: () {
        _focusProperty(p);
        Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p)));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? c.primary : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(
            color: c.cardShadow,
            blurRadius: isSelected ? 16 : 12,
            offset: const Offset(0, 2),
          )],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              child: p.imagePath.startsWith('http')
                  ? Image.network(p.imagePath, width: 90, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 90, height: 80,
                          color: c.primary.withValues(alpha: 0.1)))
                  : Image.asset(p.imagePath, width: 90, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 90, height: 80,
                          color: c.primary.withValues(alpha: 0.1))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textDark)),
                  const SizedBox(height: 3),
                  Text(p.price, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.primary)),
                  const SizedBox(height: 4),
                  Text('${p.location} • ${p.beds} Beds • ${p.baths} Baths',
                      style: TextStyle(fontSize: 11, color: c.textLight)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 14,
                  color: isSelected ? c.primary : c.textLight),
            ),
          ],
        ),
      ),
    );
  }
}
