// lib/screens/my_properties_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});
  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  List<Map<String, dynamic>> _listings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.fetchMyListings();
      if (mounted) setState(() { _listings = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    final c = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Listing?', style: TextStyle(color: c.textDark, fontWeight: FontWeight.w800)),
        content: Text('This will permanently remove your listing. This action cannot be undone.',
            style: TextStyle(color: c.textGrey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: c.textGrey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await SupabaseService.deleteListing(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing deleted'), backgroundColor: Color(0xFFEF4444)));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _edit(Map<String, dynamic> row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(listing: row, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: c.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Properties', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.textDark)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: c.primary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _listings.isEmpty
              ? _buildEmpty(c)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _listings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _ListingCard(
                      row: _listings[i],
                      onEdit: () => _edit(_listings[i]),
                      onDelete: () => _delete(_listings[i]['id'] as int),
                      onBoost: () => _boost(_listings[i]),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty(AppColorSet c) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.home_work_outlined, size: 64, color: c.textLight),
        const SizedBox(height: 16),
        Text('No listings yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textDark)),
        const SizedBox(height: 8),
        Text('Submit a property to see it here.', style: TextStyle(color: c.textGrey)),
      ]),
    );
  }

  void _boost(Map<String, dynamic> row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BoostSheet(
        listing: row,
        onBoosted: _load,
      ),
    );
  }
}

// ── Listing Card ──────────────────────────────────────────────────────────────
class _ListingCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onBoost;
  const _ListingCard({
    required this.row,
    required this.onEdit,
    required this.onDelete,
    required this.onBoost,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final status = (row['status'] as String?) ?? 'pending';
    final imgs = (row['image_urls'] as List<dynamic>?);
    final coverUrl = (imgs != null && imgs.isNotEmpty) ? imgs.first as String : null;

    final statusColor = status == 'approved'
        ? const Color(0xFF16A34A)
        : status == 'rejected'
            ? const Color(0xFFEF4444)
            : const Color(0xFFF97316);
    final statusBg = status == 'approved'
        ? const Color(0xFFF0FDF4)
        : status == 'rejected'
            ? const Color(0xFFFFF0F0)
            : const Color(0xFFFFF7ED);
    final statusLabel = status == 'approved' ? '✅ Approved' : status == 'rejected' ? '❌ Rejected' : '⏳ Pending';

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cover image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: AspectRatio(
            aspectRatio: 2.2,
            child: coverUrl != null
                ? Image.network(coverUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder(c))
                : _imgPlaceholder(c),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(row['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.textDark)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(row['price'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.primary)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 13, color: c.textLight),
              const SizedBox(width: 3),
              Expanded(child: Text(row['location'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.textGrey))),
            ]),
            if (status == 'rejected' && row['admin_note'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(10)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(row['admin_note'], style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)))),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            // ── Boost / Boosted indicator ────────────────────────────────
            if (status == 'approved') ...[
              if ((row['is_promoted'] as bool?) == true)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🚀', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 6),
                      Text('Boosted to Top', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onBoost,
                    icon: const Text('⚡', style: TextStyle(fontSize: 13)),
                    label: const Text('Boost to Top', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 15, color: c.primary),
                  label: Text('Edit', style: TextStyle(fontWeight: FontWeight.w700, color: c.primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                  label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _imgPlaceholder(AppColorSet c) => Container(
    color: c.primary.withValues(alpha: 0.08),
    child: Center(child: Icon(Icons.home_rounded, size: 48, color: c.primary.withValues(alpha: 0.3))),
  );
}

// ── Edit Bottom Sheet ─────────────────────────────────────────────────────────
class _EditSheet extends StatefulWidget {
  final Map<String, dynamic> listing;
  final VoidCallback onSaved;
  const _EditSheet({required this.listing, required this.onSaved});
  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _title, _price, _location, _desc, _sqft, _floors, _beds, _baths;
  late String _type, _badge;
  late List<String> _existingUrls;
  final List<XFile> _newImages = [];
  bool _saving = false;

  static const _types = ['House', 'Apartment', 'Serviced Apartment', 'Villa', 'Condo', 'Land'];
  static const _badges = ['New', 'Hot', 'Best Deal', 'Featured', 'For Sale'];

  @override
  void initState() {
    super.initState();
    final r = widget.listing;
    _title    = TextEditingController(text: r['title'] ?? '');
    _price    = TextEditingController(text: r['price'] ?? '');
    _location = TextEditingController(text: r['location'] ?? '');
    _desc     = TextEditingController(text: r['description'] ?? '');
    _sqft     = TextEditingController(text: r['sqft'] ?? '');
    _floors   = TextEditingController(text: r['floors'] ?? '');
    _beds     = TextEditingController(text: '${r['beds'] ?? 0}');
    _baths    = TextEditingController(text: '${r['baths'] ?? 0}');
    _type     = r['type'] ?? 'House';
    _badge    = r['badge'] ?? 'New';
    _existingUrls = ((r['image_urls'] as List<dynamic>?) ?? []).cast<String>();
  }

  @override
  void dispose() {
    for (final c in [_title, _price, _location, _desc, _sqft, _floors, _beds, _baths]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickMore() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) setState(() => _newImages.addAll(picked));
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and price are required')));
      return;
    }
    setState(() => _saving = true);
    try {
      await SupabaseService.updateListing(
        id: widget.listing['id'] as int,
        title: _title.text.trim(),
        price: _price.text.trim(),
        location: _location.text.trim(),
        type: _type,
        beds: int.tryParse(_beds.text) ?? 0,
        baths: int.tryParse(_baths.text) ?? 0,
        sqft: _sqft.text.trim(),
        floors: _floors.text.trim(),
        description: _desc.text.trim(),
        badge: _badge,
        newImageFiles: _newImages.map((x) => File(x.path)).toList(),
        existingImageUrls: _existingUrls,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing updated — pending admin review')));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.6,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Handle
          Container(margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4, decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(4))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: Text('Edit Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.textDark))),
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: c.textGrey))),
            ]),
          ),
          Expanded(
            child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
              _field(_title, 'Title', c),
              _field(_price, 'Price (e.g. ₦440,000)', c),
              _field(_location, 'Location', c),
              _field(_desc, 'Description', c, maxLines: 3),
              Row(children: [
                Expanded(child: _field(_beds, 'Bedrooms', c, numeric: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_baths, 'Bathrooms', c, numeric: true)),
              ]),
              Row(children: [
                Expanded(child: _field(_sqft, 'Sqft', c)),
                const SizedBox(width: 10),
                Expanded(child: _field(_floors, 'Floors', c)),
              ]),
              const SizedBox(height: 12),
              Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textGrey)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _types.map((t) {
                final sel = _type == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: sel,
                  onSelected: (_) => setState(() => _type = t),
                  selectedColor: c.primary,
                  labelStyle: TextStyle(color: sel ? Colors.white : c.textDark, fontWeight: FontWeight.w600),
                );
              }).toList()),
              const SizedBox(height: 12),
              Text('Badge', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textGrey)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _badges.map((b) {
                final sel = _badge == b;
                return ChoiceChip(
                  label: Text(b),
                  selected: sel,
                  onSelected: (_) => setState(() => _badge = b),
                  selectedColor: c.primary,
                  labelStyle: TextStyle(color: sel ? Colors.white : c.textDark, fontWeight: FontWeight.w600),
                );
              }).toList()),
              const SizedBox(height: 16),
              // Existing images
              if (_existingUrls.isNotEmpty) ...[
                Text('Current Photos (${_existingUrls.length})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textGrey)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(_existingUrls[i], width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _existingUrls.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Add more photos
              OutlinedButton.icon(
                onPressed: _pickMore,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text('Add More Photos (${_newImages.length} new)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, AppColorSet c, {int maxLines = 1, bool numeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: c.textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: c.textGrey, fontSize: 13),
          filled: true,
          fillColor: c.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

// ── Boost Sheet ───────────────────────────────────────────────────────────────
class _BoostSheet extends StatefulWidget {
  final Map<String, dynamic> listing;
  final VoidCallback onBoosted;
  const _BoostSheet({required this.listing, required this.onBoosted});
  @override
  State<_BoostSheet> createState() => _BoostSheetState();
}

class _BoostSheetState extends State<_BoostSheet> {
  int _selectedPlan = 1; // index: 0=1-day, 1=7-day, 2=30-day
  bool _processing = false;

  static const _plans = [
    {'label': '1-Day Boost',  'price': '₦1,500',  'desc': 'Get seen today'},
    {'label': '7-Day Boost',  'price': '₦8,000',  'desc': 'Best value pick'},
    {'label': '30-Day Boost', 'price': '₦25,000', 'desc': 'Maximum exposure'},
  ];

  Future<void> _confirm() async {
    setState(() => _processing = true);
    try {
      await SupabaseService.promoteListing(widget.listing['id'] as int);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚀 Your listing is now Boosted to the top!'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        widget.onBoosted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(4)),
        ),
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            const Text('⚡', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Boost to Top', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  'Promote "${widget.listing['title'] ?? 'your listing'}"',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Choose a Boost Plan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textDark)),
        const SizedBox(height: 12),
        // Plan cards
        ..._plans.asMap().entries.map((e) {
          final idx = e.key;
          final plan = e.value;
          final selected = _selectedPlan == idx;
          return GestureDetector(
            onTap: () => setState(() => _selectedPlan = idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFF7ED) : c.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? const Color(0xFFF59E0B) : c.divider,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? const Color(0xFFF59E0B) : Colors.transparent,
                    border: Border.all(
                      color: selected ? const Color(0xFFF59E0B) : c.divider,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(plan['label']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textDark)),
                    Text(plan['desc']!, style: TextStyle(fontSize: 12, color: c.textGrey)),
                  ]),
                ),
                Text(plan['price']!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.primary)),
              ]),
            ),
          );
        }),
        const SizedBox(height: 8),
        // Confirm button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _processing ? null : _confirm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
            ),
            child: _processing
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(
                    'Confirm — ${_plans[_selectedPlan]['price']}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text('Simulated checkout — no real payment processed.', style: TextStyle(fontSize: 11, color: c.textLight)),
      ]),
    );
  }
}
