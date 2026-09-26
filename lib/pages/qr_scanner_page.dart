import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import 'hotel_detail_page.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final TextEditingController _codeCtrl = TextEditingController();

  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue?.trim();

    if (rawValue != null && rawValue.isNotEmpty) {
      _verifyAndProceed(rawValue);
    }
  }

  Future<void> _verifyAndProceed(String codeOrPayload) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFC0392B)),
                SizedBox(height: 16),
                Text(
                  'Verifying Hotel Standee...',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final res = await ApiService.scanHotelQr(codeOrPayload);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (res['status'] == 'verified' || res['can_book'] == true || (res['hotel'] != null && res['hotel']['id'] != null)) {
        final hotel = res['hotel'] ?? {};
        final int hotelId = hotel['id'] ?? res['hotel_id'] ?? 0;
        final String hotelName = hotel['name'] ?? res['hotel_name'] ?? 'Hotel';
        final String yaanId = hotel['yaan_id'] ?? res['yaan_id'] ?? 'YAAN';
        final String city = hotel['city'] ?? res['city'] ?? '';
        final String price = hotel['price_per_night']?.toString() ?? '';

        _showVerifiedModal(
          hotelId: hotelId,
          hotelName: hotelName,
          yaanId: yaanId,
          city: city,
          price: price,
        );
      } else {
        final errorMsg = res['message'] ?? res['error'] ?? 'Hotel QR code could not be verified. Please ask hotel reception.';
        _showErrorDialog(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      _showErrorDialog('Connection error: $e');
    }
  }

  void _showVerifiedModal({
    required int hotelId,
    required String hotelName,
    required String yaanId,
    required String city,
    required String price,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27AE60).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified Yaan Partner',
                        style: TextStyle(
                          color: Color(0xFF27AE60),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Spot Booking Ready',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC0392B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      yaanId,
                      style: const TextStyle(
                        color: Color(0xFFC0392B),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                hotelName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              if (city.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(city, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ],
              if (price.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'From ?$price / night',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC0392B),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx); // Close sheet
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HotelDetailPage(hotelId: hotelId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  label: const Text(
                    'Book This Hotel Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0392B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      setState(() => _isProcessing = false);
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Color(0xFFC0392B)),
            SizedBox(width: 8),
            Text('Scan Result'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
            },
            child: const Text('Try Again', style: TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    _codeCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Hotel ID', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the unique Hotel ID printed on the standee (e.g. YAAN-H0001)',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. YAAN-H0001',
                prefixIcon: const Icon(Icons.tag, color: Color(0xFFC0392B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFC0392B), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = _codeCtrl.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx);
                _verifyAndProceed(val);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            child: const Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan Hotel QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Flashlight',
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            tooltip: 'Switch Camera',
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // High-tech scanner frame overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFC0392B), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(width: 20, height: 4, color: Colors.white),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(width: 4, height: 20, color: Colors.white),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(width: 20, height: 4, color: Colors.white),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(width: 4, height: 20, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(width: 20, height: 4, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(width: 4, height: 20, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(width: 20, height: 4, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(width: 4, height: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Helper hint text
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Point camera at the YAAN Hotel Standee QR code at reception',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // Bottom Bar for Manual Entry
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _showManualInputDialog,
                  icon: const Icon(Icons.keyboard, color: Colors.white, size: 20),
                  label: const Text(
                    'Enter Hotel ID Manually',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0392B),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
