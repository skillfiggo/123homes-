// lib/screens/add_property_screen.dart
import 'dart:io';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Controllers
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sqftCtrl = TextEditingController();
  final _floorsCtrl = TextEditingController();
  final _bedsCtrl = TextEditingController();
  final _bathsCtrl = TextEditingController();

  // State
  String _selectedType = 'House';
  String _selectedBadge = 'New';
  List<XFile> _images = [];
  bool _isSubmitting = false;
  int _currentStep = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _propertyTypes = [
    _PropType(label: 'House',     icon: Icons.house_rounded),
    _PropType(label: 'Apartment', icon: Icons.apartment_rounded),
    _PropType(label: 'Serviced Apartment', icon: Icons.room_service_rounded),
    _PropType(label: 'Villa',     icon: Icons.villa_rounded),
    _PropType(label: 'Condo',     icon: Icons.domain_rounded),
    _PropType(label: 'Land',      icon: Icons.landscape_rounded),
  ];

  static const _badges = ['New', 'Hot', 'Best Deal', 'Featured', 'For Sale'];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _titleCtrl.dispose(); _priceCtrl.dispose(); _locationCtrl.dispose();
    _descCtrl.dispose(); _sqftCtrl.dispose(); _floorsCtrl.dispose();
    _bedsCtrl.dispose(); _bathsCtrl.dispose();
    super.dispose();
  }

  bool get _isLand => _selectedType == 'Land';

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() => _images = (_images + picked).take(6).toList());
    }
  }

  void _removeImage(int i) => setState(() => _images.removeAt(i));

  void _nextStep() {
    if (_currentStep < 2) {
      if (_currentStep == 0 && !_validateStep0()) return;
      if (_currentStep == 1 && !_validateStep1()) return;
      setState(() => _currentStep++);
      _fadeCtrl.forward(from: 0);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _fadeCtrl.forward(from: 0);
    }
  }

  bool _validateStep0() {
    if (_titleCtrl.text.trim().isEmpty) { _snack('Please enter a property title'); return false; }
    if (_priceCtrl.text.trim().isEmpty) { _snack('Please enter the price'); return false; }
    if (_locationCtrl.text.trim().isEmpty) { _snack('Please enter a location'); return false; }
    return true;
  }

  bool _validateStep1() {
    if (!_isLand) {
      if (_bedsCtrl.text.trim().isEmpty) { _snack('Enter number of bedrooms'); return false; }
      if (_bathsCtrl.text.trim().isEmpty) { _snack('Enter number of bathrooms'); return false; }
    }
    if (_sqftCtrl.text.trim().isEmpty) { _snack('Enter the area / sqm'); return false; }
    return true;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _submit() async {
    if (_images.isEmpty) { _snack('Please add at least one photo'); return; }
    setState(() => _isSubmitting = true);
    try {
      await SupabaseService.insertProperty(
        title: _titleCtrl.text.trim(),
        price: '₦${_priceCtrl.text.trim()}',
        location: _locationCtrl.text.trim(),
        type: _selectedType.toLowerCase(),
        beds: _isLand ? 0 : int.tryParse(_bedsCtrl.text) ?? 0,
        baths: _isLand ? 0 : int.tryParse(_bathsCtrl.text) ?? 0,
        sqft: _sqftCtrl.text.trim(),
        floors: _isLand ? '—' : (_floorsCtrl.text.trim().isEmpty ? '1' : _floorsCtrl.text.trim()),
        description: _descCtrl.text.trim(),
        badge: _selectedBadge,
        imageFiles: _images.map((x) => File(x.path)).toList(),
        posterVerified: context.read<AppState>().isVerified,
      );
      if (mounted) {
        _showSuccessSheet();
      }
    } catch (e) {
      if (mounted) _snack('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Property Listed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text('Your property has been submitted\nand is pending review.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.5)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.of(context).pop(); Navigator.of(context).pop(); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          _buildTopBar(c),
          _buildStepIndicator(c),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                child: Form(
                  key: _formKey,
                  child: [
                    _buildStep0(c),
                    _buildStep1(c),
                    _buildStep2(c),
                  ][_currentStep],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, c),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar(AppColorSet c) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
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
            child: Text('List Your Property',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.textDark)),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ───────────────────────────────────────────────────────────
  Widget _buildStepIndicator(AppColorSet c) {
    const steps = ['Basics', 'Details', 'Photos'];
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: List.generate(steps.length, (i) {
          final done = i < _currentStep;
          final active = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        decoration: BoxDecoration(
                          color: (done || active) ? c.primary : c.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(steps[i],
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: active ? c.primary : (done ? c.textGrey : c.textLight),
                          )),
                    ],
                  ),
                ),
                if (i < steps.length - 1) const SizedBox(width: 6),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── STEP 0: Basics ───────────────────────────────────────────────────────────
  Widget _buildStep0(AppColorSet c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _sectionTitle('Property Type', c),
        const SizedBox(height: 12),
        _buildTypeSelector(c),
        const SizedBox(height: 24),
        _sectionTitle('Property Title', c),
        const SizedBox(height: 8),
        _field(_titleCtrl, 'e.g. "Luxury 4-Bedroom Duplex in Lekki"', c: c, maxLines: 1),
        const SizedBox(height: 20),
        _sectionTitle('Asking Price (₦)', c),
        const SizedBox(height: 8),
        _field(_priceCtrl, 'e.g. 450,000', c: c, keyboardType: TextInputType.number, maxLines: 1),
        const SizedBox(height: 20),
        _sectionTitle('Location / Address', c),
        const SizedBox(height: 8),
        _field(_locationCtrl, 'e.g. Lekki Phase 1, Lagos', c: c, maxLines: 1),
        const SizedBox(height: 20),
        _sectionTitle('Listing Badge', c),
        const SizedBox(height: 8),
        _buildBadgePicker(c),
        const SizedBox(height: 20),
        _sectionTitle('Description', c),
        const SizedBox(height: 8),
        _field(_descCtrl, 'Describe the property, features, neighbourhood…', c: c, maxLines: 4),
      ],
    );
  }

  Widget _buildTypeSelector(AppColorSet c) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _propertyTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final t = _propertyTypes[i];
          final active = _selectedType == t.label;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = t.label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 84,
              decoration: BoxDecoration(
                color: active ? c.primary : c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: active ? c.primary : c.divider, width: 1.5),
                boxShadow: active
                    ? [BoxShadow(color: c.primary.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 4))]
                    : [BoxShadow(color: c.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(t.icon, size: 26, color: active ? Colors.white : c.textGrey),
                  const SizedBox(height: 6),
                   Text(t.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: active ? Colors.white : c.textGrey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgePicker(AppColorSet c) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _badges.map((b) {
        final active = _selectedBadge == b;
        return GestureDetector(
          onTap: () => setState(() => _selectedBadge = b),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? c.primary : c.surface,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: active ? c.primary : c.divider),
            ),
            child: Text(b,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: active ? Colors.white : c.textGrey)),
          ),
        );
      }).toList(),
    );
  }

  // ── STEP 1: Details ──────────────────────────────────────────────────────────
  Widget _buildStep1(AppColorSet c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (!_isLand) ...[
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionTitle('Bedrooms', c),
              const SizedBox(height: 8),
              _field(_bedsCtrl, '0', c: c, keyboardType: TextInputType.number, maxLines: 1),
            ])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionTitle('Bathrooms', c),
              const SizedBox(height: 8),
              _field(_bathsCtrl, '0', c: c, keyboardType: TextInputType.number, maxLines: 1),
            ])),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionTitle('Area (sqm)', c),
              const SizedBox(height: 8),
              _field(_sqftCtrl, 'e.g. 210', c: c, keyboardType: TextInputType.number, maxLines: 1),
            ])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionTitle('Floors', c),
              const SizedBox(height: 8),
              _field(_floorsCtrl, 'e.g. 2', c: c, keyboardType: TextInputType.number, maxLines: 1),
            ])),
          ]),
        ] else ...[
          _sectionTitle('Land Area (sqm or plots)', c),
          const SizedBox(height: 8),
          _field(_sqftCtrl, 'e.g. 500 or "2 Plots"', c: c, maxLines: 1),
        ],
        const SizedBox(height: 28),
        _buildAmenitiesHint(),
      ],
    );
  }

  Widget _buildAmenitiesHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tip: Complete descriptions with area, floors and amenities attract more buyers.',
              style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 2: Photos ───────────────────────────────────────────────────────────
  Widget _buildStep2(AppColorSet c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _sectionTitle('Property Photos', c),
        const SizedBox(height: 4),
        Text('Add up to 6 photos. First photo is the cover.',
            style: TextStyle(fontSize: 13, color: c.textGrey)),
        const SizedBox(height: 16),
        _buildPhotoGrid(c),
        const SizedBox(height: 24),
        if (_images.isNotEmpty) ...[
          _buildCoverPreview(c),
        ],
      ],
    );
  }

  Widget _buildPhotoGrid(AppColorSet c) {
    final slots = List.generate(6, (i) => i);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
      ),
      itemCount: slots.length,
      itemBuilder: (_, i) {
        if (i < _images.length) {
          return _imageTile(i);
        }
        if (i == _images.length && _images.length < 6) {
          return _addTile();
        }
        return Container(
          decoration: BoxDecoration(
            color: c.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
        );
      },
    );
  }

  Widget _imageTile(int i) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(File(_images[i].path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
        ),
        if (i == 0)
          Positioned(
            bottom: 6, left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: const Text('Cover', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        Positioned(
          top: -6, right: -6,
          child: GestureDetector(
            onTap: () => _removeImage(i),
            child: Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addTile() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, size: 28, color: AppColors.primary),
            const SizedBox(height: 4),
            Text('Add Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPreview(AppColorSet c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Cover Preview', c),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Image.file(File(_images[0].path), width: double.infinity, height: 180, fit: BoxFit.cover),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 14, left: 14,
                child: Text(_titleCtrl.text.isEmpty ? 'Your Property' : _titleCtrl.text,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _sectionTitle(String t, [AppColorSet? c]) {
    final color = c?.textDark ?? AppColors.textDark;
    return Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color));
  }

  Widget _field(TextEditingController ctrl, String hint, {
    AppColorSet? c,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final surface = c?.surface ?? Colors.white;
    final textDark = c?.textDark ?? AppColors.textDark;
    final textLight = c?.textLight ?? AppColors.textLight;
    final divider = c?.divider ?? const Color(0xFFE2E8F0);
    final primary = c?.primary ?? AppColors.primary;
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: textLight),
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primary, width: 1.5)),
      ),
    );
  }

  // ── Bottom navigation bar ────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context, AppColorSet c) {
    final isLast = _currentStep == 2;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: c.surface,
        boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.divider),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: c.textDark),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: isLast ? _submit : _nextStep,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isLast ? 'Submit Listing' : 'Continue',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 6),
                            Icon(isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                                color: Colors.white, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _PropType {
  final String label;
  final IconData icon;
  const _PropType({required this.label, required this.icon});
}
