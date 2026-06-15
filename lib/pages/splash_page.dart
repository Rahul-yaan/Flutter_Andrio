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

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.search,
      'title': 'Find Your Perfect Stay',
      'desc': 'Browse hundreds of hotels and rooms near you in seconds.',
    },
    {
      'icon': Icons.calendar_today,
      'title': 'Easy Booking',
      'desc': 'Book instantly with secure payments and instant confirmation.',
    },
    {
      'icon': Icons.star,
      'title': 'Trusted Reviews',
      'desc': 'Real reviews from real guests to help you decide.',
    },
  ];

  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Red header bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: const Color(0xFFC0392B),
              child: const Text(
                'StayEase',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600),
              ),
            ),

            // Page dots
            const SizedBox(height: 20),
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

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E8E8),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(p['icon'] as IconData,
                              size: 56, color: const Color(0xFFC0392B)),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          p['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p['desc'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF888888),
                              height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Buttons
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
                              curve: Curves.easeInOut);
                        } else {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterPage()));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC0392B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                          _current == 2 ? 'Get Started' : 'Next',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const LoginPage())),
                    child: const Text('Already have an account? Login',
                        style: TextStyle(color: Color(0xFF888888))),
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