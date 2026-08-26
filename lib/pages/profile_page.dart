import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(Key? key);

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
      final response = await http.get(
        Uri.parse('https://yaan-backend.onrender.com/api$endpoint'),
        headers: {
          'Accept': 'application/json',
          'X-App-Type': 'customer',
        },
      ).timeout(const Duration(seconds: 12));

      if (mounted) Navigator.of(context).pop(); // Dismiss loading

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String contentText = data['content'] ?? data['description'] ?? 'No information available.';
        final List sections = data['sections'] ?? [];

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerLegalDetailViewerPage(
                title: title,
                content: contentText,
                sections: sections,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load page information.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
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
