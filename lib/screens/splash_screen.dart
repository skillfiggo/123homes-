// lib/screens/splash_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── controllers ──────────────────────────────────────────────
  late final AnimationController _bgCtrl;      // background gradient pan
  late final AnimationController _logoCtrl;    // logo entrance
  late final AnimationController _dotsCtrl;    // floating particles
  late final AnimationController _textCtrl;    // tagline slide-up
  late final AnimationController _shimCtrl;    // shimmer sweep
  late final AnimationController _pulseCtrl;   // logo pulse ring
  late final AnimationController _exitCtrl;    // exit scale + fade

  // ── animations ───────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _textOffset;
  late final Animation<double> _textOpacity;
  late final Animation<double> _shimmer;
  late final Animation<double> _pulse;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitOpacity;

  bool _done = false;

  @override
  void initState() {
    super.initState();

    // ── background slow pan ──────────────────────────────────────
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);

    // ── logo entrance (bounce) ───────────────────────────────────
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4, curve: Curves.easeIn)));

    // ── floating dots ────────────────────────────────────────────
    _dotsCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    // ── tagline slide-up ─────────────────────────────────────────
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _textOffset = Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textOpacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));

    // ── shimmer sweep ────────────────────────────────────────────
    _shimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _shimmer = Tween<double>(begin: -1, end: 2).animate(
        CurvedAnimation(parent: _shimCtrl, curve: Curves.easeInOut));

    // ── pulse ring ───────────────────────────────────────────────
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _pulse = Tween<double>(begin: 0.9, end: 1.5).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    // ── exit ─────────────────────────────────────────────────────
    _exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _exitScale = Tween<double>(begin: 1, end: 1.1).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    // step 1 – logo bounces in
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();

    // step 2 – shimmer once logo is visible
    await Future.delayed(const Duration(milliseconds: 600));
    _shimCtrl.forward();

    // step 3 – tagline rises
    await Future.delayed(const Duration(milliseconds: 300));
    _textCtrl.forward();

    // step 4 – hold, then exit
    await Future.delayed(const Duration(milliseconds: 1400));
    await _exitCtrl.forward();
    if (mounted) setState(() => _done = true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _dotsCtrl.dispose();
    _textCtrl.dispose();
    _shimCtrl.dispose();
    _pulseCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _bgCtrl, _logoCtrl, _dotsCtrl, _textCtrl, _shimCtrl, _pulseCtrl, _exitCtrl
      ]),
      builder: (_, __) {
        return Opacity(
          opacity: _exitOpacity.value,
          child: Transform.scale(
            scale: _exitScale.value,
            child: Scaffold(
              body: Stack(
                children: [
                  // ── Animated gradient background ──────────────
                  _AnimatedGradientBg(progress: _bgCtrl.value, size: size),

                  // ── Floating particle dots ────────────────────
                  _ParticleDots(progress: _dotsCtrl.value, size: size),

                  // ── Grid / map lines overlay ──────────────────
                  CustomPaint(
                    size: size,
                    painter: _GridPainter(),
                  ),

                  // ── Centre content ────────────────────────────
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulse ring behind logo
                        Stack(alignment: Alignment.center, children: [
                          // Pulse ring
                          Opacity(
                            opacity: (1 - (_pulse.value - 0.9) / 0.6).clamp(0.0, 0.35),
                            child: Transform.scale(
                              scale: _pulse.value,
                              child: Container(
                                width: 120, height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.6), width: 2),
                                ),
                              ),
                            ),
                          ),

                          // Logo card with shimmer
                          Transform.scale(
                            scale: _logoScale.value.clamp(0.0, 1.3),
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: _LogoCard(shimmer: _shimmer.value),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 28),

                        // Brand name
                        SlideTransition(
                          position: _textOffset,
                          child: FadeTransition(
                            opacity: _textOpacity,
                            child: Column(children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Colors.white, Color(0xFFBFDBFE)],
                                ).createShader(bounds),
                                child: const Text(
                                  '123Homes',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2), width: 1),
                                ),
                                child: const Text(
                                  'Find your perfect home in Nigeria',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Bottom loading strip ──────────────────────
                  Positioned(
                    bottom: 56,
                    left: 0, right: 0,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(children: [
                        _LoadingDots(progress: _dotsCtrl.value),
                        const SizedBox(height: 12),
                        Text(
                          'Loading…',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Logo card with shimmer ─────────────────────────────────────────────────
class _LogoCard extends StatelessWidget {
  final double shimmer;
  const _LogoCard({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.6),
            blurRadius: 32,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(children: [
          // Logo image
          Center(
            child: Image.asset(
              'assets/images/123homes_logo.png',
              width: 70,
              height: 70,
              fit: BoxFit.contain,
            ),
          ),
          // Shimmer overlay
          if (shimmer > -1)
            Positioned.fill(
              child: CustomPaint(painter: _ShimmerPainter(shimmer)),
            ),
        ]),
      ),
    );
  }
}

// ── Shimmer painter ────────────────────────────────────────────────────────
class _ShimmerPainter extends CustomPainter {
  final double progress; // -1 → 2
  _ShimmerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final x = progress * size.width;
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0.35),
        Colors.white.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(x - size.width * 0.5, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, Paint()..shader = gradient);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ── Animated gradient background ──────────────────────────────────────────
class _AnimatedGradientBg extends StatelessWidget {
  final double progress;
  final Size size;
  const _AnimatedGradientBg({required this.progress, required this.size});

  @override
  Widget build(BuildContext context) {
    // Interpolate between two gradient positions
    final t = (math.sin(progress * math.pi)).abs();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.lerp(
              Alignment.topLeft, const Alignment(-0.5, -1.0), t)!,
          end: Alignment.lerp(
              Alignment.bottomRight, const Alignment(1.2, 0.8), t)!,
          colors: const [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF1D4ED8),
            Color(0xFF0EA5E9),
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ),
      ),
    );
  }
}

// ── Floating particle dots ─────────────────────────────────────────────────
class _ParticleDots extends StatelessWidget {
  final double progress;
  final Size size;
  const _ParticleDots({required this.progress, required this.size});

  static final _rng = math.Random(42);
  static final _particles = List.generate(18, (i) => _Particle(
    x:     _rng.nextDouble(),
    y:     _rng.nextDouble(),
    r:     2 + _rng.nextDouble() * 3,
    speed: 0.3 + _rng.nextDouble() * 0.7,
    phase: _rng.nextDouble() * math.pi * 2,
  ));

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _ParticlePainter(progress, _particles),
    );
  }
}

class _Particle {
  final double x, y, r, speed, phase;
  const _Particle({required this.x, required this.y, required this.r,
      required this.speed, required this.phase});
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  _ParticlePainter(this.progress, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final t = (progress * p.speed + p.phase / (math.pi * 2)) % 1.0;
      final dy = -size.height * 0.3 * t;
      final dx = math.sin(t * math.pi * 2 + p.phase) * 20;
      final opacity = (math.sin(t * math.pi)).clamp(0.0, 1.0) * 0.5;
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(
          Offset(p.x * size.width + dx, p.y * size.height + dy), p.r, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ── Background grid / map lines ────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Diagonal accent
    final diagPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    canvas.drawLine(Offset.zero, Offset(size.width * 0.5, size.height), diagPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width * 0.5, size.height), diagPaint);
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ── Three-dot loading indicator ────────────────────────────────────────────
class _LoadingDots extends StatelessWidget {
  final double progress; // 0 → 1 repeating
  const _LoadingDots({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = (progress - i * 0.15).clamp(0.0, 1.0);
        final scale = 0.6 + 0.4 * (math.sin(phase * math.pi * 2)).abs();
        final opacity = 0.3 + 0.7 * (math.sin(phase * math.pi * 2)).abs();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
