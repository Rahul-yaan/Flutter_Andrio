import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'search_results_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

  double? _fromLat, _fromLng, _toLat, _toLng;
  bool _loading = false;
  int _currentIndex = 0;

  Future<void> _search() async {
    if (_fromCtrl.text.trim().isEmpty || _toCtrl.text.trim().isEmpty) {
      _snack('Enter both From and To locations');
      return;
    }
    if (_fromLat == null || _toLat == null) {
      _snack('Please select locations from suggestions');
      return;
    }

    setState(() => _loading = true);

    final result = await ApiService.searchHotels(
      fromLat: _fromLat!,
      fromLng: _fromLng!,
      toLat: _toLat!,
      toLng: _toLng!,
    );

    setState(() => _loading = false);

    if (result['hotels'] != null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchResultsPage(
              hotels: List<Map<String, dynamic>>.from(result['hotels']),
              fromLat: _fromLat!,
              fromLng: _fromLng!,
              toLat: _toLat!,
              toLng: _toLng!,
              fromCity: _fromCtrl.text,
              toCity: _toCtrl.text,
            ),
          ),
        );
      }
    } else {
      _snack(result['error'] ?? 'Search failed');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFC0392B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Find Hotels',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Search hotels on your route',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await ApiService.clearToken();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                              (r) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // From field
                  _LocationField(
                    controller: _fromCtrl,
                    hint: 'From — Starting city',
                    icon: Icons.radio_button_checked,
                    iconColor: const Color(0xFF27AE60),
                    onPlaceSelected: (lat, lng) {
                      setState(() {
                        _fromLat = lat;
                        _fromLng = lng;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // Swap button + To field
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            final tempText = _fromCtrl.text;
                            _fromCtrl.text = _toCtrl.text;
                            _toCtrl.text = tempText;
                            final tempLat = _fromLat;
                            final tempLng = _fromLng;
                            _fromLat = _toLat;
                            _fromLng = _toLng;
                            _toLat = tempLat;
                            _toLng = tempLng;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.swap_vert,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _LocationField(
                          controller: _toCtrl,
                          hint: 'To — Destination city',
                          icon: Icons.location_on,
                          iconColor: const Color(0xFFC0392B),
                          onPlaceSelected: (lat, lng) {
                            setState(() {
                              _toLat = lat;
                              _toLng = lng;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Search button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _search,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Color(0xFFC0392B),
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.search, size: 20),
                      label: Text(_loading ? 'Searching...' : 'Search Hotels'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFC0392B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How it works',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HowItWorksCard(
                      icon: Icons.search,
                      title: 'Search Your Route',
                      desc: 'Enter your starting city and destination',
                    ),
                    const SizedBox(height: 10),
                    _HowItWorksCard(
                      icon: Icons.map_outlined,
                      title: 'View on Map',
                      desc: 'See all hotels along your route on the map',
                    ),
                    const SizedBox(height: 10),
                    _HowItWorksCard(
                      icon: Icons.hotel,
                      title: 'Book & Stay',
                      desc: 'Pick your hotel and book instantly',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFC0392B),
        unselectedItemColor: const Color(0xFFBBBBBB),
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _LocationField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final Function(double lat, double lng) onPlaceSelected;

  const _LocationField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.onPlaceSelected,
  });

  @override
  State<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<_LocationField> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;

  Future<void> _getSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    final results = await ApiService.getPlaceSuggestions(input);
    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: widget.controller,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 13,
              ),
              prefixIcon: Icon(widget.icon, color: widget.iconColor, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            onChanged: _getSuggestions,
          ),
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: _suggestions.map((s) {
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.location_on,
                    color: Color(0xFFC0392B),
                    size: 18,
                  ),
                  title: Text(
                    s['description'] ?? '',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    widget.controller.text = s['description'] ?? '';
                    widget.onPlaceSelected(s['lat'], s['lng']);
                    setState(() => _showSuggestions = false);
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _HowItWorksCard({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E8E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFC0392B), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
