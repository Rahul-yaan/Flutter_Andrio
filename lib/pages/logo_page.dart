import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'splash_page.dart';

class LogoPage extends StatefulWidget {
  const LogoPage({super.key});
  @override
  State<LogoPage> createState() => _LogoPageState();
}

class _LogoPageState extends State<LogoPage>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  late AnimationController _truckController;

  @override
  void initState() {
    super.initState();

    // Text & logo fade animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _textController, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _textController.forward();

    // Truck movement animation from left to right across the screen
    _truckController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );
    _truckController.forward();

    // Seamless navigation to SplashPage after the truck passes across
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (ctx, anim, secAnim) => const SplashPage(),
            transitionsBuilder: (ctx, anim, secAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _truckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFC0392B),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD32F2F), Color(0xFFC0392B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Truck Passing from Left to Right
              AnimatedBuilder(
                animation: _truckController,
                builder: (context, _) {
                  // Truck moves from offscreen left (-180px) to offscreen right (screenWidth + 80px)
                  final curvedVal = Curves.easeInOutCubic.transform(_truckController.value);
                  final truckX = -180.0 + (screenWidth + 260.0) * curvedVal;
                  return _TruckHighwayTrack(
                    truckX: truckX,
                    progress: _truckController.value,
                  );
                },
              ),

              const SizedBox(height: 32),

              // Brand Name & Tagline
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    children: [
                      const Text(
                        'Yaan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'HOTELS & STAYS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_shipping_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'HIGHWAY STAYS & PARKING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TruckHighwayTrack extends StatelessWidget {
  final double truckX;
  final double progress;

  const _TruckHighwayTrack({
    required this.truckX,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // Subtle physical bounce of the truck body while driving
    final double bounce = math.sin(progress * math.pi * 16) * 1.5;

    return SizedBox(
      height: 110,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          // Highway Road Line & Lane Markings
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Solid road baseline
                Container(
                  height: 2.5,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 4),
                // Highway dashed stripes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    12,
                    (i) => Container(
                      width: 16,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // The moving Truck passing from left to right
          Positioned(
            left: truckX,
            bottom: 20 + bounce,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Wind / Speed motion streaks behind truck
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, right: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 28,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 42,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 22,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.35),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),

                // Truck Body Image & Headlight Beam
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      'assets/images/truck_white.png',
                      height: 56,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => const Icon(
                        Icons.local_shipping_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    // Headlight beam projecting forward
                    Positioned(
                      right: -30,
                      bottom: 6,
                      child: Container(
                        width: 36,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.55),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
