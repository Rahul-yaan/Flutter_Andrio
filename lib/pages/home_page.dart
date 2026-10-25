import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../services/notification_service.dart';
import '../models/notification_item.dart';
import 'search_results_page.dart';
import 'login_page.dart';
import 'my_bookings_page.dart';
import 'profile_page.dart';
import 'qr_scanner_page.dart';
import 'notifications_page.dart';

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
  int _unreadNotificationsCount = 0;
  NotificationItem? _bannerNotification;

  // Admin promotional banners & offers state
  List<Map<String, dynamic>> _adminBanners = [];
  bool _loadingBanners = true;
  late final PageController _bannerPageController = PageController();
  int _currentBannerPage = 0;
  Timer? _bannerTimer;
  String _supportPhone = '+91 7777991598';

  @override
  void initState() {
    super.initState();
    _loadNotificationsData();
    _loadBannersData();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationsData() async {
    final count = await NotificationService.getUnreadCount();
    final banner = await NotificationService.getLatestBannerNotification();
    if (mounted) {
      setState(() {
        _unreadNotificationsCount = count;
        _bannerNotification = banner;
      });
    }
  }

  Future<void> _loadBannersData() async {
    try {
      final res = await ApiService.getBannersData(target: 'user');
      if (mounted) {
        List<Map<String, dynamic>> bannersList = [];
        if (res['banners'] is List) {
          bannersList = List<Map<String, dynamic>>.from(res['banners']);
        } else if (res['data'] is List) {
          bannersList = List<Map<String, dynamic>>.from(res['data']);
        }

        final phone = res['support_phone']?.toString();

        setState(() {
          _adminBanners = bannersList;
          if (phone != null && phone.trim().isNotEmpty) {
            _supportPhone = phone.trim();
          }
          _loadingBanners = false;
        });
        _startBannerTimer();
      }
    } catch (e) {
      if (mounted) setState(() => _loadingBanners = false);
    }
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (_adminBanners.length > 1) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (!mounted || !_bannerPageController.hasClients) return;
        final nextPage = (_currentBannerPage + 1) % _adminBanners.length;
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _search() async {
    if (_fromCtrl.text.trim().isEmpty || _toCtrl.text.trim().isEmpty) {
      _snack('Enter both From and To locations'.tr());
      return;
    }
    if (_fromLat == null || _toLat == null) {
      _snack('Please select locations from suggestions'.tr());
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
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Modern Premium Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFC0392B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC0392B).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Find Hotels'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Search hotels on your route'.tr(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Language Selector Pill Button
                        GestureDetector(
                          onTap: () => LanguageService.showLanguageSelector(context),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white38, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.translate_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  LanguageService.isHindi ? 'हिंदी' : 'EN',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Notification Icon Button for Admin Offers & News
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                tooltip: 'Notifications & Offers',
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NotificationsPage(),
                                    ),
                                  );
                                  _loadNotificationsData();
                                  _loadBannersData();
                                },
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            if (_unreadNotificationsCount > 0)
                              Positioned(
                                right: 6,
                                top: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFD700),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _unreadNotificationsCount > 9
                                          ? '9+'
                                          : '$_unreadNotificationsCount',
                                      style: const TextStyle(
                                        color: Color(0xFF8B1E0F),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () async {
                              await ApiService.clearToken();
                              if (mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginPage()),
                                  (route) => false,
                                );
                              }
                            },
                            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Modern Route Search Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // From field
                          _LocationField(
                            controller: _fromCtrl,
                            hint: 'Starting city'.tr(),
                            icon: Icons.my_location,
                            iconColor: const Color(0xFF27AE60),
                            onPlaceSelected: (lat, lng) {
                              setState(() {
                                _fromLat = lat;
                                _fromLng = lng;
                              });
                            },
                          ),

                          // Route line connector with swap icon
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 2,
                                  height: 20,
                                  color: Colors.grey.shade300,
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    final tmpText = _fromCtrl.text;
                                    final tmpLat = _fromLat;
                                    final tmpLng = _fromLng;

                                    setState(() {
                                      _fromCtrl.text = _toCtrl.text;
                                      _fromLat = _toLat;
                                      _fromLng = _toLng;

                                      _toCtrl.text = tmpText;
                                      _toLat = tmpLat;
                                      _toLng = tmpLng;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF0F0),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFF5D6D6)),
                                    ),
                                    child: const Icon(
                                      Icons.swap_vert_rounded,
                                      color: Color(0xFFC0392B),
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),

                          // To field
                          _LocationField(
                            controller: _toCtrl,
                            hint: 'Destination city'.tr(),
                            icon: Icons.location_on,
                            iconColor: const Color(0xFFC0392B),
                            onPlaceSelected: (lat, lng) {
                              setState(() {
                                _toLat = lat;
                                _toLng = lng;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Search button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _search,
                        icon: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFC0392B),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.search, size: 22),
                        label: Text(
                          _loading ? 'Searching...'.tr() : 'Search Hotels'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFC0392B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification Bar for Latest Offer or News from Admin
                    if (_bannerNotification != null) ...[
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsPage(),
                            ),
                          );
                          _loadNotificationsData();
                          _loadBannersData();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _bannerNotification!.type == 'offer'
                                  ? [const Color(0xFFFFF8E7), const Color(0xFFFEF0D0)]
                                  : [const Color(0xFFEBF5FB), const Color(0xFFD4E6F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _bannerNotification!.type == 'offer'
                                  ? const Color(0xFFF39C12).withValues(alpha: 0.4)
                                  : const Color(0xFF3498DB).withValues(alpha: 0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _bannerNotification!.type == 'offer'
                                      ? const Color(0xFFF39C12).withValues(alpha: 0.2)
                                      : const Color(0xFF3498DB).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _bannerNotification!.type == 'offer'
                                      ? Icons.local_offer_rounded
                                      : Icons.campaign_rounded,
                                  size: 18,
                                  color: _bannerNotification!.type == 'offer'
                                      ? const Color(0xFFD35400)
                                      : const Color(0xFF2980B9),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _bannerNotification!.type == 'offer'
                                              ? 'ADMIN OFFER'
                                              : 'ADMIN NEWS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _bannerNotification!.type == 'offer'
                                                ? const Color(0xFFD35400)
                                                : const Color(0xFF2980B9),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        if (_bannerNotification!.discountPercent != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFC0392B),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${_bannerNotification!.discountPercent}% OFF',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _bannerNotification!.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _bannerNotification!.message,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF666666),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF888888)),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () async {
                                  await NotificationService.dismissBanner(_bannerNotification!.id);
                                  if (mounted) {
                                    setState(() => _bannerNotification = null);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Spot Booking with QR Card
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QrScannerPage()),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C3E50), Color(0xFF1A252F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC0392B),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Spot Booking with QR'.tr(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Badge(label: Text('SPOT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Scan hotel reception QR code for instant room booking'.tr(),
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),

                    // Promotional Banner Card Slider / Carousel (Image 2)
                    _buildBannerCarousel(),

                    // Support & Query Chat Card (Image 2)
                    _buildSupportCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFFC0392B),
          unselectedItemColor: const Color(0xFFBBBBBB),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          currentIndex: _currentIndex,
          onTap: (i) async {
            if (i == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrScannerPage()),
              );
            } else if (i == 2) {
              final token = await ApiService.getToken();
              if (token == null) {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                }
              } else {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyBookingsPage()),
                  );
                }
              }
            } else if (i == 3) {
              final token = await ApiService.getToken();
              if (token == null) {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                }
              } else {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                }
              }
            } else {
              setState(() => _currentIndex = i);
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_rounded),
              ),
              label: 'Home'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.qr_code_scanner_rounded),
              ),
              label: 'Scan QR'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.calendar_month_rounded),
              ),
              label: 'Bookings'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_rounded),
              ),
              label: 'Profile'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BANNER CAROUSEL & CARDS (IMAGE 2)
  // ==========================================
  Widget _buildBannerCarousel() {
    if (_loadingBanners) {
      return Container(
        height: 180,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFC0392B),
            strokeWidth: 2,
          ),
        ),
      );
    }

    final hasBanners = _adminBanners.isNotEmpty;
    final count = hasBanners ? _adminBanners.length : 1;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerPageController,
            itemCount: count,
            onPageChanged: (i) {
              setState(() => _currentBannerPage = i);
            },
            itemBuilder: (context, index) {
              if (!hasBanners) {
                return _buildDefaultBannerPlaceholder();
              }
              final banner = _adminBanners[index];
              return _buildAdminBannerCard(banner);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Active indicator dots (Image 2 style: red elongated pill for active, grey dots for inactive)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            hasBanners ? (_adminBanners.length > 1 ? _adminBanners.length : 1) : 3,
            (index) {
              final isActive = index == (hasBanners ? _currentBannerPage : 0);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: isActive ? 22 : 6,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFC0392B) : const Color(0xFFD6D6D6),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminBannerCard(Map<String, dynamic> banner) {
    final title = banner['title']?.toString() ?? 'Special Offer';
    final desc = banner['description']?.toString() ?? '';
    final imageUrl = banner['image_url']?.toString() ?? banner['image_path']?.toString();
    final promoCode = banner['discount_code']?.toString() ?? banner['promo_code']?.toString();
    final discountRaw = banner['discount_percentage'] ?? banner['discount_percent'];
    final discount = discountRaw != null ? num.tryParse(discountRaw.toString())?.round() : null;

    final hasImage = imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http');

    return GestureDetector(
      onTap: () => _onBannerTap(banner),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image or Fallback Gradient
              if (hasImage)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallbackBannerBg(discount),
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: const Color(0xFF2C3E50),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white70,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                )
              else
                _buildFallbackBannerBg(discount),

              // Gradient Overlay for optimal readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),

              // Badges & Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top row: Offer tag / discount & coupon code
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC0392B),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_offer_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                discount != null && discount > 0
                                    ? '$discount% OFF'
                                    : 'HOTEL OFFER',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (promoCode != null && promoCode.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white38),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  promoCode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.copy_rounded, color: Colors.white70, size: 12),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Bottom info: Title and description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            desc,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBannerBg(int? discount) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF1A252F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(
              Icons.hotel_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultBannerPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF1A252F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.hotel_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0392B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'HOTEL & SPOT OFFERS'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Exclusive Highway Deals'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Book verified highway partner hotels with instant spot QR check-in & best room rates.'.tr(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFC0392B),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC0392B).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Got Query? Reach out us at'.tr(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _supportPhone,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _launchWhatsApp(_supportPhone),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
            label: Text(
              'CHAT WITH US'.tr(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFC0392B),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final whatsappNumber = cleanDigits.length == 10 ? '91$cleanDigits' : cleanDigits;
    final url = Uri.parse('https://wa.me/$whatsappNumber?text=Hello%20Yaan%20Support');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _snack('Reach us at $phone');
      }
    } catch (_) {
      _snack('Reach us at $phone');
    }
  }

  void _onBannerTap(Map<String, dynamic> banner) {
    final promoCode = banner['discount_code']?.toString() ?? banner['promo_code']?.toString();
    if (promoCode != null && promoCode.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: promoCode));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BannerDetailSheet(
        banner: banner,
        onCopyCode: (code) {
          Clipboard.setData(ClipboardData(text: code));
          _snack('Coupon code "$code" copied!');
        },
      ),
    );
  }
}

class _BannerDetailSheet extends StatelessWidget {
  final Map<String, dynamic> banner;
  final Function(String) onCopyCode;

  const _BannerDetailSheet({
    required this.banner,
    required this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    final title = banner['title']?.toString() ?? 'Special Offer';
    final desc = banner['description']?.toString() ?? '';
    final promoCode = banner['discount_code']?.toString() ?? banner['promo_code']?.toString();
    final discountRaw = banner['discount_percentage'] ?? banner['discount_percent'];
    final discount = discountRaw != null ? num.tryParse(discountRaw.toString())?.round() : null;
    final validTill = banner['valid_till']?.toString() ?? banner['expires_at']?.toString();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  discount != null && discount > 0 ? '$discount% SPECIAL OFFER' : 'ADMIN ANNOUNCEMENT',
                  style: const TextStyle(
                    color: Color(0xFF27AE60),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF555555),
                height: 1.4,
              ),
            ),
          ],
          if (promoCode != null && promoCode.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC0392B).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COUPON CODE'.tr(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF888888),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promoCode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Color(0xFFC0392B),
                          ),
                        ),
                        if (validTill != null && validTill.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Valid: $validTill',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF777777)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => onCopyCode(promoCode),
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text('Copy'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC0392B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Explore Hotels & Book Now'.tr(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
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
  Timer? _debounce;

  void _getSuggestions(String input) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (input.trim().length < 2) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
        return;
      }

      final results = await ApiService.getPlaceSuggestions(input);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: TextField(
            controller: widget.controller,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(widget.icon, color: widget.iconColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: _getSuggestions,
          ),
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _suggestions.map((s) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E8E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFC0392B),
                      size: 18,
                    ),
                  ),
                  title: Text(
                    s['description'] ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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