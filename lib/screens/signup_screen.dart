// lib/screens/signup_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../main.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMsg;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final res = await SupabaseService.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        fullName: _nameCtrl.text.trim(),
      );

      if (!mounted) return;

      // Supabase may require email confirmation depending on your project settings.
      // If the session is immediately available, go to home. Otherwise, notify user.
      if (res.session != null) {
        Navigator.of(context).pushAndRemoveUntil(
          _slide(const MainShell()),
          (route) => false,
        );
      } else {
        // Email confirmation required — navigate to OTP screen
        setState(() { _isLoading = false; });
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(email: _emailCtrl.text.trim()),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() { _isLoading = false; _errorMsg = e.message; });
    } catch (e) {
      setState(() { _isLoading = false; _errorMsg = 'Something went wrong. Please try again.'; });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Same background as login
          Positioned.fill(
            child: Image.asset(
              'assets/images/kano_park.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0.6, 0.0),
            ),
          ),
          // Dark gradient for readability (signup has more fields)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x88000000)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Brand header ─────────────────────────────────
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                // Back button
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 20, offset: const Offset(0, 8)),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset('assets/images/123homes_logo.png',
                                        width: 42, height: 42, fit: BoxFit.contain),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text('Create Account',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                                const SizedBox(height: 6),
                                const Text('Join 123Homes and find your dream property',
                                  style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // ── Glassmorphism card ────────────────────────────
                            ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Error banner
                                      if (_errorMsg != null) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(_errorMsg!,
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                      ],

                                      // Full Name
                                      _buildField(
                                        controller: _nameCtrl,
                                        hint: 'Full name',
                                        icon: Icons.person_outline_rounded,
                                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                                      ),
                                      const SizedBox(height: 12),

                                      // Email
                                      _buildField(
                                        controller: _emailCtrl,
                                        hint: 'Email address',
                                        icon: Icons.email_outlined,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return 'Please enter your email';
                                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),

                                      // Password
                                      _buildField(
                                        controller: _passCtrl,
                                        hint: 'Password',
                                        icon: Icons.lock_outline_rounded,
                                        obscure: _obscurePass,
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                              color: const Color(0xFF64748B), size: 20),
                                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                        ),
                                        validator: (v) {
                                          if (v == null || v.length < 6) return 'Password must be at least 6 characters';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),

                                      // Confirm Password
                                      _buildField(
                                        controller: _confirmCtrl,
                                        hint: 'Confirm password',
                                        icon: Icons.lock_outline_rounded,
                                        obscure: _obscureConfirm,
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                              color: const Color(0xFF64748B), size: 20),
                                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                        ),
                                        validator: (v) {
                                          if (v != _passCtrl.text) return 'Passwords do not match';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Submit button
                                      SizedBox(
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _submit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor: Colors.black54,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                            elevation: 0,
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(width: 20, height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                              : const Text('Create Account',
                                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Already have account ──────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account?',
                                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Sign in',
                                    style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable frosted input field ──────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          errorStyle: const TextStyle(height: 0), // suppress inline error (we show banner)
        ),
      ),
    );
  }

  PageRouteBuilder _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          SlideTransition(position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)), child: child),
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
