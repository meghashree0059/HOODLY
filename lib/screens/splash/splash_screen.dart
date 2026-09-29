import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';

/// Hoodly Splash Screen
///
/// Full-screen gradient (#6C3EF4 → #4F2ED9) with:
/// - Animated logo (scale + fade in)
/// - App name "Hoodly" with letter-spacing
/// - Tagline with fade
/// - Subtle pulsing glow behind the logo
/// - Decorative background circles
/// - Auto-navigates to Onboarding after 3 seconds
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ────────────────────────────────────
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _pulseController;
  late final AnimationController _bgCirclesController;

  // ── Logo animations ──────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;

  // ── Text animations ──────────────────────────────────────────
  late final Animation<double> _appNameOpacity;
  late final Animation<Offset> _appNameSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;

  // ── Glow pulse ───────────────────────────────────────────────
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  // ── BG circles ───────────────────────────────────────────────
  late final Animation<double> _bgCircleScale;

  @override
  void initState() {
    super.initState();
    _setSystemOverlay();
    _initAnimations();
    _startSequence();
  }

  void _setSystemOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  void _initAnimations() {
    // ── Logo Controller (0 → 900ms) ───────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // ── Text Controller (400ms delay, 800ms total) ────────────
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _appNameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _appNameSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // ── Pulse Controller (repeating) ──────────────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseOpacity = Tween<double>(begin: 0.18, end: 0.38).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ── BG Circles Controller ─────────────────────────────────
    _bgCirclesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bgCircleScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _bgCirclesController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Future<void> _startSequence() async {
    // Background circles fade in first
    _bgCirclesController.forward();

    // Logo animates in after a brief pause
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _logoController.forward();

    // Text fades in while logo is still animating
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _textController.forward();

    // Resolve session & navigation direction
    await Future.delayed(const Duration(milliseconds: 2450));
    if (!mounted) return;
    await _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && !session.isExpired) {
      if (mounted) context.go(AppRoutes.home);
      return;
    }

    final storage = await StorageService.getInstance();
    final hasSeenOnboarding = storage.getBool(StorageKeys.hasSeenOnboarding) ?? false;
    
    if (mounted) {
      if (hasSeenOnboarding) {
        context.go(AppRoutes.login);
      } else {
        context.go(AppRoutes.onboarding);
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _bgCirclesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6C3EF4), // #6C3EF4
              Color(0xFF4F2ED9), // #4F2ED9
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Decorative Background Circles ─────────────────
            _buildBackgroundCircles(size),

            // ── Main Content ──────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Logo ──────────────────────────────────────
                _buildLogoSection(),

                const SizedBox(height: AppConstants.spaceXL),

                // ── App Name ──────────────────────────────────
                _buildAppName(),

                const SizedBox(height: AppConstants.spaceSM),

                // ── Tagline ───────────────────────────────────
                _buildTagline(),
              ],
            ),

            // ── Bottom Loading Dots ───────────────────────────
            Positioned(
              bottom: 60 + MediaQuery.paddingOf(context).bottom,
              child: _buildLoadingDots(),
            ),
          ],
        ),
      ),
    );
  }

  /// Large translucent circles for depth / glassmorphism feel
  Widget _buildBackgroundCircles(Size size) {
    return AnimatedBuilder(
      animation: _bgCircleScale,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Top-right large circle
            Positioned(
              top: -size.height * 0.12,
              right: -size.width * 0.22,
              child: Transform.scale(
                scale: _bgCircleScale.value,
                child: Container(
                  width: size.width * 0.85,
                  height: size.width * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),

            // Bottom-left medium circle
            Positioned(
              bottom: -size.height * 0.08,
              left: -size.width * 0.3,
              child: Transform.scale(
                scale: _bgCircleScale.value,
                child: Container(
                  width: size.width * 0.75,
                  height: size.width * 0.75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),

            // Mid small circle (top-left)
            Positioned(
              top: size.height * 0.15,
              left: -size.width * 0.1,
              child: Transform.scale(
                scale: _bgCircleScale.value,
                child: Container(
                  width: size.width * 0.3,
                  height: size.width * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
            ),

            // Bottom-right tiny circle
            Positioned(
              bottom: size.height * 0.18,
              right: size.width * 0.06,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),

            // Top-left tiny dot
            Positioned(
              top: size.height * 0.22,
              right: size.width * 0.12,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Logo — icon inside a white rounded container with glow
  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, _) {
        return FadeTransition(
          opacity: _logoOpacity,
          child: SlideTransition(
            position: _logoSlide,
            child: ScaleTransition(
              scale: _logoScale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing glow ring
                  Transform.scale(
                    scale: _pulseScale.value,
                    child: Container(
                      width: AppConstants.logoSize + 48,
                      height: AppConstants.logoSize + 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: _pulseOpacity.value),
                      ),
                    ),
                  ),

                  // Outer soft ring
                  Container(
                    width: AppConstants.logoSize + 24,
                    height: AppConstants.logoSize + 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),

                  // Main logo container
                  Container(
                    width: AppConstants.logoSize,
                    height: AppConstants.logoSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _HoodlyLogoIcon(size: AppConstants.logoIconSize),
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

  /// "Hoodly" app name text
  Widget _buildAppName() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, _) {
        return FadeTransition(
          opacity: _appNameOpacity,
          child: SlideTransition(
            position: _appNameSlide,
            child: Text(
              AppConstants.appName,
              style: AppTextStyles.splashAppName,
            ),
          ),
        );
      },
    );
  }

  /// Tagline text
  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, _) {
        return FadeTransition(
          opacity: _taglineOpacity,
          child: SlideTransition(
            position: _taglineSlide,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.space3XL,
              ),
              child: Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: AppTextStyles.splashTagline,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Three animated loading dots at the bottom
  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, _) {
        return FadeTransition(
          opacity: _taglineOpacity,
          child: const _BouncingDots(),
        );
      },
    );
  }
}

/// Custom Hoodly logo icon — house/location pin mark built with Canvas
class _HoodlyLogoIcon extends StatelessWidget {
  final double size;
  const _HoodlyLogoIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HoodlyLogoPainter(),
      ),
    );
  }
}

class _HoodlyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {

    final w = size.width;
    final h = size.height;

    // ── Gradient fill ────────────────────────────────────────
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6C3EF4), Color(0xFF4F2ED9)],
    );

    // ── Location Pin Body ────────────────────────────────────
    final pinPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final pinPath = Path();
    final cx = w * 0.5;
    final cy = h * 0.38;
    final r = w * 0.33;

    // Draw the pin head (circle)
    pinPath.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    // Draw the pin tail pointing downward
    pinPath.moveTo(cx - r * 0.45, cy + r * 0.7);
    pinPath.quadraticBezierTo(cx, h * 0.94, cx, h * 0.94);
    pinPath.quadraticBezierTo(cx, h * 0.94, cx + r * 0.45, cy + r * 0.7);
    pinPath.close();

    canvas.drawPath(pinPath, pinPaint);

    // ── White inner circle (hole) ────────────────────────────
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), r * 0.42, holePaint);

    // ── Small house icon inside hole ─────────────────────────
    final housePaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final houseW = r * 0.55;
    final houseH = r * 0.45;
    final hx = cx - houseW / 2;
    final hy = cy - houseH / 2 + r * 0.04;

    // Roof triangle
    final roofPath = Path()
      ..moveTo(cx, hy - houseH * 0.42)
      ..lineTo(hx - houseW * 0.12, hy)
      ..lineTo(hx + houseW + houseW * 0.12, hy)
      ..close();
    canvas.drawPath(roofPath, housePaint);

    // Body rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(hx + houseW * 0.06, hy, houseW * 0.88, houseH),
        const Radius.circular(2),
      ),
      housePaint,
    );

    // Door (white cutout)
    final doorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final doorW = houseW * 0.28;
    final doorH = houseH * 0.52;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - doorW / 2,
          hy + houseH - doorH,
          doorW,
          doorH,
        ),
        const Radius.circular(1.5),
      ),
      doorPaint,
    );
  }

  @override
  bool shouldRepaint(_HoodlyLogoPainter oldDelegate) => false;
}

/// Three bouncing dots loading indicator
class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _anims = _controllers
        .map((c) => Tween<double>(begin: 0.0, end: -10.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    _startBounce();
  }

  Future<void> _startBounce() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 180));
      if (mounted) _controllers[i].repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (context, _) {
            return Transform.translate(
              offset: Offset(0, _anims[i].value),
              child: Container(
                width: 7,
                height: 7,
                margin: EdgeInsets.symmetric(
                  horizontal: i == 1 ? 6 : 0,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: i == 1 ? 1.0 : 0.6),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
