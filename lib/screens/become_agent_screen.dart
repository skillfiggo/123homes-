// lib/screens/become_agent_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';

class BecomeAgentScreen extends StatefulWidget {
  const BecomeAgentScreen({super.key});

  @override
  State<BecomeAgentScreen> createState() => _BecomeAgentScreenState();
}

class _BecomeAgentScreenState extends State<BecomeAgentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _businessCtrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _expCtrl      = TextEditingController();

  File? _cacFile;
  String? _cacFileName;
  bool _isSubmitting = false;
  bool _submitted = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _businessCtrl.dispose();
    _phoneCtrl.dispose();
    _expCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCac() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _cacFile = File(result.files.single.path!);
        _cacFileName = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cacFile == null) {
      _snack('Please upload your CAC Certificate');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await SupabaseService.submitAgentApplication(
        businessName:    _businessCtrl.text.trim(),
        phone:           _phoneCtrl.text.trim(),
        experienceYears: int.tryParse(_expCtrl.text.trim()) ?? 0,
        cacDoc:          _cacFile!,
      );
      // Refresh profile so AppState reflects the new pending status
      if (mounted) {
        await context.read<AppState>().refreshProfile();
        setState(() { _isSubmitting = false; _submitted = true; });
        _animCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _snack('Submission failed: ${e.toString()}');
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: _submitted ? _buildSuccess(c) : _buildForm(c),
        ),
      ),
    );
  }

  Widget _buildForm(AppColorSet c) {
    return Column(
      children: [
        _buildHeader(c),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [c.primary.withValues(alpha: 0.12), c.primary.withValues(alpha: 0.04)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Become a Verified Agent',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.textDark)),
                              const SizedBox(height: 4),
                              Text('Your listings will show a ✅ Verified badge,\nbuilding trust with potential buyers.',
                                  style: TextStyle(fontSize: 12, color: c.textGrey, height: 1.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  _label('Business / Agency Name', c),
                  const SizedBox(height: 8),
                  _field(_businessCtrl, 'e.g. Sunrise Realty Ltd', c,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 20),

                  _label('Phone Number', c),
                  const SizedBox(height: 8),
                  _field(_phoneCtrl, 'e.g. 08012345678', c,
                      keyboard: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null),
                  const SizedBox(height: 20),

                  _label('Years of Experience', c),
                  const SizedBox(height: 8),
                  _field(_expCtrl, 'e.g. 5', c,
                      keyboard: TextInputType.number,
                      validator: (v) => (v == null || int.tryParse(v.trim()) == null) ? 'Enter a valid number' : null),
                  const SizedBox(height: 20),

                  _label('CAC Certificate', c),
                  const SizedBox(height: 4),
                  Text('Upload your Corporate Affairs Commission certificate\n(PDF, JPG, or PNG)',
                      style: TextStyle(fontSize: 12, color: c.textGrey, height: 1.5)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickCac,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _cacFile != null
                            ? c.primary.withValues(alpha: 0.08)
                            : c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _cacFile != null ? c.primary : c.divider,
                          width: _cacFile != null ? 2 : 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _cacFile != null ? Icons.description_rounded : Icons.upload_file_rounded,
                            color: _cacFile != null ? c.primary : c.textLight,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _cacFile != null ? _cacFileName! : 'Tap to upload CAC document',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _cacFile != null ? FontWeight.w600 : FontWeight.w400,
                                color: _cacFile != null ? c.primary : c.textLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_cacFile != null)
                            GestureDetector(
                              onTap: () => setState(() { _cacFile = null; _cacFileName = null; }),
                              child: Icon(Icons.close_rounded, size: 18, color: c.textLight),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: c.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Submit Application',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(AppColorSet c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 48),
            ),
            const SizedBox(height: 24),
            Text('Application Submitted!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textDark)),
            const SizedBox(height: 12),
            Text(
              'We\'ve received your application.\nOur team will review it within 24–48 hours and notify you of the outcome.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.textGrey, height: 1.6),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0xFFF97316), size: 16),
                  const SizedBox(width: 8),
                  Text('Status: Pending Review',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFC2410C))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Back to Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorSet c) {
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
          Text('Agent Verification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.textDark)),
        ],
      ),
    );
  }

  Widget _label(String text, AppColorSet c) =>
      Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textDark));

  Widget _field(
    TextEditingController ctrl,
    String hint,
    AppColorSet c, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: validator,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: c.textLight),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.primary, width: 1.5)),
        errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444))),
      ),
    );
  }
}
