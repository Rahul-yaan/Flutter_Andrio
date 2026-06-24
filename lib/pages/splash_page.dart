import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'register_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _controller = PageController();
  int _current = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.search_rounded,
      'color': const Color(0xFF5B8DEF),
      'bg': const Color(0xFFEAF0FD),
      'title': 'Welcome to Yaan!',
      'desc':
          'Find and reserve highway hotels easily. Enjoy comfortable and convenient stays wherever you are.',
    },
    {
      'icon': Icons.calendar_month_rounded,
      'color': const Color(0xFFE67E22),
      'bg': const Color(0xFFFDF0E0),
      'title': 'Discover and Book',
      'desc':
          'Discover hotels with hassle-free booking on almost any budget. We help you find the perfect quality.',
    },
    {
      'icon': Icons.schedule_rounded,
      'color': const Color(0xFF27AE60),
      'bg': const Color(0xFFE8F8F0),
      'title': 'Manage Your Schedule',
      'desc':
          'Avoid getting early. Manage your schedule and enjoy a drive, book today and make tomorrow more comfortable.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration placeholder
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: p['bg'] as Color,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(
                            p['icon'] as IconData,
                            size: 100,
                            color: p['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          p['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          p['desc'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF888888),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots indicator
            SmoothPageIndicator(
              controller: _controller,
              count: 3,
              effect: const ExpandingDotsEffect(
                activeDotColor: Color(0xFFC0392B),
                dotColor: Color(0xFFDDDDDD),
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3,
              ),
            ),

            const SizedBox(height: 32),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_current < 2) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC0392B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _current == 2 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(color: Color(0xFF888888)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
