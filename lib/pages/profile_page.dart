import 'package:flutter/material.dart';
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

  Future<void> _openLegalPage(String endpoint, String title) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFC0392B)),
      ),
    );

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
      final url = Uri.parse('$baseUrlStr$endpoint');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 25));

      if (mounted) Navigator.of(context).pop(); // Dismiss loading

      String? contentText;
      List sections = [];

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic>) {
          final Map<String, dynamic> targetMap = (data['data'] is Map<String, dynamic>)
              ? data['data']
              : data;

          sections = targetMap['sections'] ?? data['sections'] ?? [];

          final rawText = targetMap['content'] ??
              targetMap['text'] ??
              targetMap['page_content'] ??
              targetMap['about'] ??
              targetMap['terms'] ??
              targetMap['privacy'] ??
              targetMap['contact'] ??
              targetMap['description'] ??
              targetMap['details'] ??
              targetMap['body'] ??
              targetMap['message'] ??
              data['content'] ??
              data['text'] ??
              data['page_content'] ??
              data['about'] ??
              data['terms'] ??
              data['privacy'] ??
              data['contact'] ??
              data['description'] ??
              data['details'] ??
              data['body'] ??
              data['message'];

          if (rawText != null && rawText.toString().trim().isNotEmpty) {
            contentText = _cleanHtml(rawText.toString());
          } else if (targetMap['html_content'] != null || targetMap['html'] != null || data['html_content'] != null) {
            final rawHtml = targetMap['html_content'] ?? targetMap['html'] ?? data['html_content'];
            contentText = _cleanHtml(rawHtml.toString());
          }
        }
      }

      final String finalContent = (contentText != null && contentText.trim().isNotEmpty)
          ? contentText
          : _getFallbackText(title);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerLegalDetailViewerPage(
              title: title,
              content: finalContent,
              sections: sections,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerLegalDetailViewerPage(
              title: title,
              content: _getFallbackText(title),
              sections: const [],
            ),
          ),
        );
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
If you have any questions or concerns about these Terms, please contact us via support.''';
    } else if (title.contains('Privacy')) {
      return '''Privacy Policy for Yaan
Effective Date: August 21, 2026

1. Information We Collect
We collect personal and vehicle-related information when you register or use the App:
 • Name
 • Email ID
 • Phone Number
 • Truck Number
 • Logistics Company Name
 • Wheel Type

2. Use of Information
We use your information for:
 • Creating and managing your account
 • Processing bookings
 • Sending invoices and confirmations
 • Improving our App and services
 • Customer support and updates

3. Data Storage and Security
Your personal data is stored securely and is not shared with third parties except with hotels where bookings are made.

4. Changes to Privacy Policy
We reserve the right to update this Privacy Policy at any time. Continued use of the App constitutes acceptance of the new policy.''';
    } else if (title.contains('About')) {
      return '''About Yaan

Our Mission
Yaan connects logistics companies, fleet owners, and independent truck drivers with verified highway hotels and dhabas across India. We ensure drivers get safe overnight parking, clean restrooms, and complimentary meals while providing hotel partners with consistent bookings.

Why Choose Yaan?
 • Verified Highway Locations: Secure parking spaces at verified hotels and dhabas along major national & state highways.
 • Driver Comfort: Booking includes complimentary breakfast for drivers and access to clean washroom facilities.
 • Seamless Payments: Instant online booking, transparent billing, and GST invoices.
 • Partner Ecosystem: Empowering local dhabas and hotels with technology, fair commissions, and reliable monthly payouts.

Company Information
Yaan is a registered sole proprietorship firm operating from Gujarat, India, dedicated to revolutionizing highway logistics and parking infrastructure.''';
    } else if (title.contains('Contact')) {
      return '''Contact Us

Yaan Customer Support:
Email: yaan.smt@gmail.com
Phone: +91 9023325725

Address: Gujarat, India

We are available to assist with your truck parking bookings, app inquiries, and support requests.''';
    } else if (title.contains('Share')) {
      return '''Share Yaan App

Share Yaan with truck drivers, fleet owners, and logistics partners to help them find safe overnight truck parking across major highways in India!''';
    } else if (title.contains('Rate')) {
      return '''Rate Yaan App

We value your feedback! If you enjoy using Yaan, please rate us on the Play Store to help us serve you better.''';
    }
    return 'Information currently unavailable. Please check back later.';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F7F7),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFC0392B))),
      );
    }

    final name = _userData?['name'] ?? 'User';
    final email = _userData?['email'] ?? '';
    final phone = _userData?['phone'] ?? '';
    final avatar = _userData?['avatar'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          // Top Red Section & Profile Card
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                color: const Color(0xFFC0392B),
                padding: const EdgeInsets.only(top: 60, left: 20),
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
                top: 110,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        child: avatar == null
                            ? Text(
                                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFFC0392B)),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                          _loadProfile(); // reload after returning
                        },
                        icon: const Icon(Icons.edit_square, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 70), // Spacing for the overlapping card

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
                          _openLegalPage('/user/about', 'About Us');
                        }),
                        const Divider(height: 1, indent: 50, endIndent: 20),
                        _buildListTile(Icons.privacy_tip_outlined, 'Privacy Policy', () {
                          _openLegalPage('/customer/privacy-policy', 'Privacy Policy');
                        }),
                        const Divider(height: 1, indent: 50, endIndent: 20),
                        _buildListTile(Icons.headset_mic_outlined, 'Contact Us', () {
                          _openLegalPage('/user/contact', 'Contact Us');
                        }),
                        const Divider(height: 1, indent: 50, endIndent: 20),
                        _buildListTile(Icons.share_outlined, 'Share App', () {
                          _openLegalPage('/user/share', 'Share App');
                        }),
                        const Divider(height: 1, indent: 50, endIndent: 20),
                        _buildListTile(Icons.star_border, 'Rate Us', () {
                          _openLegalPage('/user/rate', 'Rate Us');
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

class CustomerLegalDetailViewerPage extends StatelessWidget {
  final String title;
  final String content;
  final List sections;

  const CustomerLegalDetailViewerPage({
    Key? key,
    required this.title,
    required this.content,
    required this.sections,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sections.isNotEmpty)
              ...sections.map((sec) {
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
                content,
                style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF334155)),
              ),
          ],
        ),
      ),
    );
  }
}
