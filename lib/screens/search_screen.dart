// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/property.dart';
import '../providers/app_state.dart';
import '../widgets/property_card.dart';
import 'property_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  String _typeFilter = 'All';
  int _minBeds = 0;
  String _sortBy = 'Default';

  final _types = ['All', 'House', 'Apartment', 'Serviced Apartment', 'Villa', 'Condo', 'Land'];
  final _sorts = ['Default', 'Price ↑', 'Price ↓', 'Rating'];

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  List<Property> _applyFilters(List<Property> all) {
    var list = all.where((p) {
      final q = _query.toLowerCase();
      final matchQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q) ||
          p.type.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
      final matchType = _typeFilter == 'All' ||
          p.type.toLowerCase() == _typeFilter.toLowerCase();
      final matchBeds = _minBeds == 0 || p.beds >= _minBeds;
      return matchQuery && matchType && matchBeds;
    }).toList();

    switch (_sortBy) {
      case 'Price ↑':
        list.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
        break;
      case 'Price ↓':
        list.sort((a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)));
        break;
      case 'Rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return list;
  }

  int _parsePrice(String price) {
    return int.tryParse(price.replaceAll(RegExp(r'[₦,]'), '')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final allProperties = context.read<AppState>().allProperties;
    final results = _applyFilters(allProperties);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(c),
              _buildTypeFilters(c),
              _buildSubFilters(c),
              _buildResultCount(results.length, c),
              Expanded(child: _buildResults(results, c)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppColorSet c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: c.textDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(fontSize: 15, color: c.textDark, fontFamily: 'Inter'),
                decoration: InputDecoration(
                  hintText: 'Search by name, location, type…',
                  hintStyle: TextStyle(fontSize: 14, color: c.textLight, fontFamily: 'Inter'),
                  prefixIcon: Icon(Icons.search_rounded, color: c.primary, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          child: Icon(Icons.close_rounded, color: c.textLight, size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildSortButton(c),
        ],
      ),
    );
  }

  Widget _buildSortButton(AppColorSet c) {
    return GestureDetector(
      onTap: () => _showSortSheet(c),
      child: Container(
        width: 40, height: 48,
        decoration: BoxDecoration(
          color: _sortBy != 'Default' ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(Icons.sort_rounded,
            size: 20, color: _sortBy != 'Default' ? Colors.white : c.textDark),
      ),
    );
  }

  Widget _buildTypeFilters(AppColorSet c) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _types[i];
          final active = _typeFilter == t;
          return GestureDetector(
            onTap: () => setState(() => _typeFilter = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? c.primary : c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? c.primary : c.divider),
              ),
              child: Text(t,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: active ? Colors.white : c.textGrey)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubFilters(AppColorSet c) {
    final bedOptions = [0, 1, 2, 3, 4, 5];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Text('Min Beds:', style: TextStyle(fontSize: 13, color: c.textGrey, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          ...bedOptions.map((b) {
            final active = _minBeds == b;
            return GestureDetector(
              onTap: () => setState(() => _minBeds = b),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 6),
                width: 34, height: 30,
                decoration: BoxDecoration(
                  color: active ? c.primary : c.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(b == 0 ? 'Any' : '$b+',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: active ? Colors.white : c.textGrey)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultCount(int count, AppColorSet c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Text(
            _query.isEmpty && _typeFilter == 'All' && _minBeds == 0
                ? 'All Properties'
                : '$count result${count == 1 ? '' : 's'} found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textDark),
          ),
          const Spacer(),
          if (_hasActiveFilters())
            GestureDetector(
              onTap: _clearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Clear all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.primary)),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() =>
      _query.isNotEmpty || _typeFilter != 'All' || _minBeds != 0 || _sortBy != 'Default';

  void _clearAll() {
    _controller.clear();
    setState(() {
      _query = '';
      _typeFilter = 'All';
      _minBeds = 0;
      _sortBy = 'Default';
    });
  }

  Widget _buildResults(List<Property> results, AppColorSet c) {
    if (results.isEmpty) return _buildEmpty(c);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => PropertyCard(
        property: results[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: results[i])),
        ),
      ),
    );
  }

  Widget _buildEmpty(AppColorSet c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 32, color: c.primary),
          ),
          const SizedBox(height: 16),
          Text('No properties found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.textDark)),
          const SizedBox(height: 8),
          Text('Try a different name, location\nor adjust your filters',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.textLight, height: 1.5)),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _clearAll,
            icon: Icon(Icons.refresh_rounded, color: c.primary, size: 18),
            label: Text('Clear filters', style: TextStyle(color: c.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(AppColorSet c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: c.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Sort By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textDark)),
            const SizedBox(height: 12),
            ..._sorts.map((s) {
              final active = _sortBy == s;
              return GestureDetector(
                onTap: () {
                  setState(() => _sortBy = s);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: active ? c.primary.withValues(alpha: 0.1) : c.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active ? c.primary : Colors.transparent, width: 2),
                  ),
                  child: Row(
                    children: [
                      Text(s, style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: active ? c.primary : c.textDark)),
                      const Spacer(),
                      if (active) Icon(Icons.check_circle_rounded, color: c.primary, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
