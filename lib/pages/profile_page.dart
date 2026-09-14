import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final res = await ApiService.getProfile();
    if (mounted) {
      setState(() {
        _userData = res['user'];
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await ApiService.clearToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _openLegalPage(String endpoint, String title) {
    if (title.contains('Share')) {
      _showShareDialog();
      return;
    }

    if (title.contains('Rate')) {
      _showRateUsDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerLegalDetailViewerPage(
          title: title,
          endpoint: endpoint,
        ),
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.share, color: Color(0xFFC0392B)),
              SizedBox(width: 8),
              Text('Share Yaan App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Share Yaan App with fellow drivers and fleet owners to book highway truck parking & stay easily!',
                style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              SizedBox(height: 12),
              SelectableText(
                'https://yaan.com/download-app',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC0392B)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: 'https://yaan.com/download-app'));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('App link copied to clipboard!')),
                );
              },
              child: const Text('COPY LINK', style: TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
              child: const Text('CLOSE', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showRateUsDialog() {
    int selectedStars = 5;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Rate Yaan App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How is your experience with Yaan?', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedStars ? Icons.star : Icons.star_border,
                          color: const Color(0xFFF39C12),
                          size: 32,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            selectedStars = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you for rating Yaan!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
                  child: const Text('SUBMIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC0392B)),
        ),
      );
    }

    final name = _userData?['name'] ?? 'User';
    final email = _userData?['email'] ?? '';
    final phone = _userData?['phone'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          // Header Card
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                color: const Color(0xFFC0392B),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20, top: 40),
                child: const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFF5E8E8),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC0392B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          if (_userData == null) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfilePage(userData: _userData!),
                            ),
                          );
                          _loadProfile();
                        },
                        icon: const Icon(Icons.edit_square, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 70),

          // Other Information
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Other Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(Icons.description_outlined, 'Terms & Conditions', () {
                          _openLegalPage('/customer/terms-and-conditions', 'Terms & Conditions');
                        }),
                        const Divider(height: 1, indent: 50, endIndent: 20),
                        _buildListTile(Icons.info_outline, 'About Us', () {
                          _openLegalPage('/user/about-us', 'About Us');
                        }),
                        const Divider(height: 1, indent: 50, endIndent: 20),
                        _buildListTile(Icons.privacy_tip_outlined, 'Privacy Policy', () {
                          _openLegalPage('/customer/privacy-policy', 'Privacy Policy');
                        }),
                        const Divider(height: 1, indent: 50, endIndent: 20),
                        _buildListTile(Icons.headset_mic_outlined, 'Contact Us', () {
                          _openLegalPage('/user/contact-us', 'Contact Us');
                        }),
                        const Divider(height: 1, indent: 50, endIndent: 20),
                        _buildListTile(Icons.share_outlined, 'Share App', () {
                          _openLegalPage('/user/share-app', 'Share App');
                        }),
                        const Divider(height: 1, indent: 50, endIndent: 20),
                        _buildListTile(Icons.star_border, 'Rate Us', () {
                          _openLegalPage('/user/rate-us', 'Rate Us');
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC0392B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'LOG OUT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class CustomerLegalDetailViewerPage extends StatefulWidget {
  final String title;
  final String endpoint;

  const CustomerLegalDetailViewerPage({
    super.key,
    required this.title,
    required this.endpoint,
  });

  @override
  State<CustomerLegalDetailViewerPage> createState() => _CustomerLegalDetailViewerPageState();
}

class _CustomerLegalDetailViewerPageState extends State<CustomerLegalDetailViewerPage> {
  String _content = '';
  List _sections = [];
  bool _fetchingApi = true;

  @override
  void initState() {
    super.initState();
    _content = _getFallbackText(widget.title);
    _fetchDynamicContent();
  }

  Future<void> _fetchDynamicContent() async {
    try {
      final token = await ApiService.getToken();
      final headers = {
        'Accept': 'application/json',
        'X-App-Type': 'customer',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final baseUrlStr = ApiService.baseUrl.isNotEmpty
          ? ApiService.baseUrl
          : 'https://yaan-backend.onrender.com/api';
      final url = Uri.parse('$baseUrlStr${widget.endpoint}');

      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic>) {
          final Map<String, dynamic> targetMap = (data['data'] is Map<String, dynamic>)
              ? data['data']
              : data;

          final sec = targetMap['sections'] ?? data['sections'];
          if (sec != null && sec is List && sec.isNotEmpty) {
            _sections = sec;
          }

          final rawText = targetMap['content'] ??
              targetMap['text'] ??
              targetMap['page_content'] ??
              targetMap['about'] ??
              targetMap['terms'] ??
              targetMap['privacy'] ??
              targetMap['contact'] ??
              targetMap['description'] ??
              data['content'] ??
              data['text'];

          if (rawText != null && rawText.toString().trim().isNotEmpty) {
            _content = _cleanHtml(rawText.toString());
          }
        }
      }
    } catch (e) {
      // Keep rich fallback content
    } finally {
      if (mounted) {
        setState(() {
          _fetchingApi = false;
        });
      }
    }
  }

  static String _cleanHtml(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</h2>|</h3>|</h1>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static String _getFallbackText(String title) {
    if (title.contains('Terms')) {
      return '''Terms & Conditions for Customers
Effective Date: August 21, 2026

1. Acceptance of Terms
By downloading, accessing, or using the Yaan App, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions, as well as our Privacy Policy. If you do not agree to these terms, please do not use the App.

2. Services Provided
Yaan enables users to locate and book overnight truck parking spaces at registered hotels and dhabas listed on our platform. These listings may also include complimentary breakfast, restrooms, or other amenities as offered by the respective partner.

3. User Registration and Information
To use the App, users must register by providing accurate information including name, email, phone number, vehicle type, and truck details.

4. Booking Process
Users can search for and book parking at partner hotels via the App. All bookings are subject to availability. Once a booking is confirmed, an invoice will be sent via email within 48 hours.

5. Role of Yaan
Yaan acts solely as a technology platform connecting users with hotels that provide truck parking facilities. Yaan does not own or operate any hotels, dhabas, or parking locations.

6. Limitation of Liability
Yaan shall not be held liable for any damage, theft, or incident involving vehicles, cargo, or personal property occurring during transit or while parked at listed locations.

7. Cancellation and Refund Policy
Yaan does not offer cancellations or refunds once a booking is made and payment is processed.

8. Governing Law
These Terms shall be governed by and construed in accordance with the laws of the State of Gujarat, India.

9. Contact Information
If you have any questions or concerns about these Terms, please contact us via support@yaan.com.''';
    } else if (title.contains('Privacy')) {
      return '''Privacy Policy for Yaan
Effective Date: August 21, 2026

1. Information We Collect
We collect information you provide directly to us when using the Yaan App, such as when you create an account, search for parking, or contact customer support. This includes:
- Account Details: Name, Email Address, Phone Number.
- Vehicle & Logistics Info: Truck Number, Truck Type, Logistics Provider Name.
- Location Data: Pickup & destination location parameters for route-based search.

2. How We Use Your Information
We use the information we collect to:
- Provide, maintain, and improve our parking search and booking services.
- Process transactions and send booking confirmation receipts.
- Send technical notices, security alerts, and administrative messages.
- Respond to your comments, questions, and customer service requests.

3. Data Sharing & Security
We do not sell your personal data to third parties. We implement industry-standard encryption and security measures to protect your information against unauthorized access, disclosure, or alteration.

4. Your Rights
You may access, update, or request deletion of your account details at any time through the profile settings page in the App.

5. Contact Us
If you have any questions about this Privacy Policy, please contact our support team at privacy@yaan.com.''';
    } else if (title.contains('About')) {
      return '''About Yaan Platform
Welcome to Yaan — India's premier highway truck parking and hotel booking solution.

Our Mission:
Yaan is dedicated to empowering truck drivers, logistics partners, and highway hotel owners by providing safe, verified, and convenient overnight parking and rest facilities along major transportation corridors.

Key Features:
- Route-based Hotel & Parking Search
- Verified Highway Dhabas & Stay Amenities
- Fast Online & Pay-at-Hotel Bookings
- Instant Digital Invoices & Receipts
- 24/7 Dedicated Support for Drivers

Whether you are navigating long-distance routes or managing a logistics fleet, Yaan ensures comfort, safety, and reliability on every trip.''';
    } else if (title.contains('Contact')) {
      return '''Contact Yaan Customer Support

We are here to assist you 24 hours a day, 7 days a week.

📞 Customer Helpline:
+91 97277 10396

📧 Support Email:
support@yaan.com

🏢 Corporate Office:
Yaan Logistics & Tech Hub,
Civil Hospital Rd, Bharuch, Gujarat 392001, India

⏰ Operating Hours:
24/7 Customer Support Available''';
    }
    return 'For more information, please contact Yaan Support at support@yaan.com.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_fetchingApi)
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: LinearProgressIndicator(color: Color(0xFFC0392B), backgroundColor: Color(0xFFF5E8E8)),
              ),

            if (_sections.isNotEmpty)
              ..._sections.map((sec) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sec['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sec['content'] ?? '',
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF334155)),
                      ),
                      if (sec['items'] != null && sec['items'] is List)
                        ...List<Widget>.from(
                          (sec['items'] as List).map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
                                  Expanded(
                                    child: Text(
                                      item.toString(),
                                      style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF334155)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList()
            else
              Text(
                _content,
                style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF334155)),
              ),
          ],
        ),
      ),
    );
  }
}
