import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../utils/image_utils.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic> hotel;
  const BookingPage({super.key, required this.hotel});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _bookingDate;
  String? _selectedTruckType;
  final TextEditingController _truckNoController = TextEditingController();
  final TextEditingController _logisticsNameController = TextEditingController();
  final TextEditingController _logisticsNumberController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  
  String _paymentMethod = 'Online Payment';
  bool _agreedToTerms = false;
  bool _loading = false;
  bool _booked = false;
  
  // Available admin offers state
  List<Map<String, dynamic>> _availableOffers = [];
  bool _loadingOffers = true;
  Map<String, dynamic>? _appliedOffer;
  String _appliedPromoCode = '';
  String? _couponError;
  bool _showAllOffers = false;

  late Razorpay _razorpay;
  int? _currentBookingId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadAvailableOffers();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _truckNoController.dispose();
    _logisticsNameController.dispose();
    _logisticsNumberController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableOffers() async {
    try {
      final banners = await ApiService.getBanners(target: 'user');
      if (mounted) {
        // Filter banners that provide discounts or coupon codes
        final offers = banners.where((b) {
          final pct = num.tryParse((b['discount_percentage'] ?? b['discount_percent'] ?? 0).toString()) ?? 0;
          final code = (b['discount_code'] ?? b['promo_code'])?.toString() ?? '';
          return pct > 0 || code.isNotEmpty;
        }).toList();

        setState(() {
          _availableOffers = offers;
          _loadingOffers = false;
        });

        // If hotel has a default active discount percentage, check if it matches an offer
        final hotelPct = double.tryParse((widget.hotel['active_discount_percentage'] ?? 0).toString()) ?? 0;
        if (hotelPct > 0 && _appliedOffer == null && offers.isNotEmpty) {
          // Pre-select matching offer if available
          final matching = offers.firstWhere(
            (o) => (num.tryParse((o['discount_percentage'] ?? o['discount_percent'] ?? 0).toString()) ?? 0) == hotelPct,
            orElse: () => offers.first,
          );
          _selectOffer(matching, showToast: false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOffers = false);
    }
  }

  void _applyCoupon(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      setState(() => _couponError = 'Please enter a coupon code');
      return;
    }

    final matched = _availableOffers.firstWhere(
      (b) {
        final bCode = (b['discount_code'] ?? b['promo_code'])?.toString().trim().toUpperCase();
        final bTitle = (b['title'])?.toString().trim().toUpperCase();
        return bCode == cleanCode || (bCode != null && cleanCode == bCode) || (bTitle != null && bTitle.contains(cleanCode));
      },
      orElse: () => {},
    );

    if (matched.isNotEmpty) {
      final codeToUse = matched['discount_code']?.toString() ?? cleanCode;
      setState(() {
        _appliedOffer = matched;
        _appliedPromoCode = codeToUse;
        _couponController.text = codeToUse;
        _couponError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer "$codeToUse" applied! ${_discountPct.toStringAsFixed(0)}% discount saved.'),
          backgroundColor: const Color(0xFF27AE60),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _couponError = 'Invalid or expired promo code';
      });
    }
  }

  void _selectOffer(Map<String, dynamic> offer, {bool showToast = true}) {
    final code = offer['discount_code']?.toString() ?? offer['promo_code']?.toString() ?? offer['title']?.toString() ?? '';
    setState(() {
      _appliedOffer = offer;
      _appliedPromoCode = code;
      _couponController.text = code;
      _couponError = null;
    });
    if (showToast) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer applied! ${_discountPct.toStringAsFixed(0)}% OFF on total.'),
          backgroundColor: const Color(0xFF27AE60),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedOffer = null;
      _appliedPromoCode = '';
      _couponController.clear();
      _couponError = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offer removed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String? _lastTransactionId;

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentBookingId == null) return;
    setState(() => _loading = true);
    final paymentId = response.paymentId ?? '';
    final res = await ApiService.verifyPayment(
      bookingId: _currentBookingId!,
      razorpayPaymentId: paymentId,
      razorpayOrderId: response.orderId ?? '',
      razorpaySignature: response.signature ?? '',
      transactionId: paymentId,
    );
    setState(() => _loading = false);
    if (res.containsKey('error')) {
      _showError(res['error']);
    } else {
      setState(() {
        _lastTransactionId = paymentId;
        _booked = true;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _loading = false);
    _showError('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showError('External wallet selected: ${response.walletName}');
  }

  final List<String> _truckTypes = [
    '4 Wheel', '6 Wheel', '8 Wheel', '10 Wheel',
    '12 Wheel', '14 Wheel', '16 Wheel', '18 Wheel',
    '22 Wheel', '22+ Wheel'
  ];

  double get _originalPrice {
    return double.tryParse((widget.hotel['original_price'] ?? widget.hotel['price_per_night']).toString()) ?? 0;
  }

  double get _discountPct {
    if (_appliedOffer != null) {
      final rawPct = _appliedOffer!['discount_percentage'] ?? _appliedOffer!['discount_percent'];
      final p = double.tryParse(rawPct?.toString() ?? '0') ?? 0;
      if (p > 0) return p;
    }
    return double.tryParse((widget.hotel['active_discount_percentage'] ?? 0).toString()) ?? 0;
  }

  double get _discountAmount {
    if (_discountPct > 0) {
      return double.parse((_originalPrice * (_discountPct / 100)).toStringAsFixed(2));
    }
    if (_appliedOffer == null && widget.hotel['discount_amount'] != null) {
      return double.tryParse(widget.hotel['discount_amount'].toString()) ?? 0;
    }
    return 0;
  }

  double get _discountedBasePrice {
    final diff = _originalPrice - _discountAmount;
    return diff > 0 ? double.parse(diff.toStringAsFixed(2)) : 0;
  }

  double get _gstAmount => double.parse((_discountedBasePrice * 0.18).toStringAsFixed(2));

  double get _totalPayable => double.parse((_discountedBasePrice + _gstAmount).toStringAsFixed(2));

  Future<void> _openMap() async {
    final lat = widget.hotel['latitude'];
    final lng = widget.hotel['longitude'];
    Uri url;

    if (lat != null && lng != null && lat.toString().isNotEmpty && lng.toString().isNotEmpty) {
      url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    } else {
      final address = widget.hotel['address'] ?? widget.hotel['city'];
      if (address == null || address.toString().trim().isEmpty) {
        _showError('Location not available');
        return;
      }
      url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address.toString())}');
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not open map');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _bookingDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFC0392B)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _bookingDate = picked);
    }
  }

  Future<void> _submitBooking() async {
    if (_bookingDate == null) {
      _showError('Please select a booking date');
      return;
    }
    if (_selectedTruckType == null) {
      _showError('Please select a truck type');
      return;
    }
    if (_truckNoController.text.trim().isEmpty) {
      _showError('Please enter truck number');
      return;
    }
    if (_logisticsNameController.text.trim().isEmpty) {
      _showError('Please enter logistics name');
      return;
    }
    if (_logisticsNumberController.text.trim().isEmpty) {
      _showError('Please enter logistics number');
      return;
    }
    if (!_agreedToTerms) {
      _showError('Please agree to terms and conditions');
      return;
    }

    setState(() => _loading = true);

    final res = await ApiService.createBooking(
      hotelId: widget.hotel['id'],
      bookingDate: _bookingDate!.toIso8601String().split('T')[0],
      truckType: _selectedTruckType!,
      truckNo: _truckNoController.text.trim(),
      logisticsName: _logisticsNameController.text.trim(),
      logisticsNumber: _logisticsNumberController.text.trim(),
      paymentMethod: _paymentMethod,
      discountPercentage: _discountPct > 0 ? _discountPct : null,
      discountAmount: _discountAmount > 0 ? _discountAmount : null,
      discountCode: _appliedPromoCode.isNotEmpty ? _appliedPromoCode : null,
    );

    if (res.containsKey('error')) {
      setState(() => _loading = false);
      _showError(res['error']);
    } else {
      final booking = res['booking'];
      final orderId = res['order_id'] ?? res['razorpay_order_id'] ?? (booking != null ? booking['razorpay_order_id'] : null);
      final keyId = res['key'] ?? res['razorpay_key_id'] ?? dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_test_TJg3E5sTryKc0U';
      final amountPaise = res['amount'] ?? res['amount_in_paise'] ?? ((double.tryParse(booking?['total_payable']?.toString() ?? '0') ?? 0) * 100).toInt();

      if (orderId != null) {
        _currentBookingId = booking?['id'];
        String cleanContact = _logisticsNumberController.text.trim().replaceAll(RegExp(r'\D'), '');
        var options = {
          'key': keyId,
          'amount': amountPaise,
          'currency': 'INR',
          'name': widget.hotel['name'] ?? 'Booking',
          'description': 'Booking Payment',
          'order_id': orderId,
          'prefill': {
            'contact': cleanContact.isNotEmpty ? cleanContact : '9876543210',
            'email': 'user@example.com'
          },
          'retry': {
            'enabled': true,
            'max_count': 1
          }
        };
        try {
          _razorpay.open(options);
        } catch (e) {
          setState(() => _loading = false);
          _showError(e.toString());
        }
      } else {
        setState(() {
          _loading = false;
          _booked = true;
        });
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_booked) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFC0392B),
          foregroundColor: Colors.white,
          title: const Text('Booking Confirmed'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              Text('Booking Successful!'.tr(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Paid Total: ₹${_totalPayable.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              if (_discountAmount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Offer Discount Saved: -₹${_discountAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF27AE60), fontWeight: FontWeight.bold),
                ),
              ],
              if (_lastTransactionId != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Txn ID: $_lastTransactionId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Back to Home'.tr()),
              )
            ],
          ),
        ),
      );
    }

    final String? hotelImage = ImageUtils.getHotelImageUrl(widget.hotel);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hotel['name'] ?? 'Book Hotel', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hotelImage != null && hotelImage.isNotEmpty
                        ? Image.network(
                            hotelImage,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.hotel, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.hotel, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.hotel['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.hotel['address'] ?? widget.hotel['city'] ?? '',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _openMap,
                          child: const Row(
                            children: [
                              Icon(Icons.directions, size: 14, color: Color(0xFFC0392B)),
                              SizedBox(width: 4),
                              Text('View on Map', style: TextStyle(fontSize: 12, color: Color(0xFFC0392B), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Date Selection
            const Text('Select Booking Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _bookingDate == null
                          ? 'Choose date'
                          : '${_bookingDate!.day}/${_bookingDate!.month}/${_bookingDate!.year}',
                      style: TextStyle(color: _bookingDate == null ? Colors.grey : Colors.black),
                    ),
                    const Icon(Icons.calendar_month, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Truck Type
            Text('Select Your Truck Type'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _truckTypes.map((type) {
                final isSelected = _selectedTruckType == type;
                return ChoiceChip(
                  label: Text(type, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black)),
                  selected: isSelected,
                  selectedColor: const Color(0xFFC0392B),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: isSelected ? const Color(0xFFC0392B) : Colors.grey[300]!),
                  ),
                  onSelected: (val) {
                    setState(() => _selectedTruckType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Text Inputs
            Text('Truck No'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _truckNoController,
              decoration: InputDecoration(
                hintText: 'Enter Truck Number (e.g. GJ16AB7888)'.tr(),
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            Text('Logistics Name'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _logisticsNameController,
              decoration: InputDecoration(
                hintText: 'Enter Logistics Name'.tr(),
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            Text('Logistics Number'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _logisticsNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter Logistics Number'.tr(),
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // OFFERS & COUPONS SECTION
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_offer_rounded, size: 16, color: Color(0xFFC0392B)),
                    const SizedBox(width: 6),
                    Text(
                      'Apply Offer or Coupon Code'.tr(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                  ],
                ),
                if (_availableOffers.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _showAllOffers = !_showAllOffers),
                    child: Text(
                      _showAllOffers ? 'Hide Offers'.tr() : ('View Offers'.tr() + ' (${_availableOffers.length})'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC0392B)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Coupon Code Input Field Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _appliedOffer != null
                      ? const Color(0xFF27AE60)
                      : (_couponError != null ? Colors.red.shade300 : Colors.grey.shade200),
                  width: _appliedOffer != null ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      enabled: _appliedOffer == null,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      decoration: InputDecoration(
                        hintText: 'Enter Promo Code (e.g. YAANSPOT)'.tr(),
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.normal, letterSpacing: 0),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 18, color: Colors.grey),
                        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      onSubmitted: (val) => _applyCoupon(val),
                    ),
                  ),
                  if (_appliedOffer != null)
                    TextButton.icon(
                      onPressed: _removeCoupon,
                      icon: const Icon(Icons.close, size: 14, color: Colors.red),
                      label: Text('REMOVE'.tr(), style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _applyCoupon(_couponController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC0392B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text('APPLY'.tr(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),

            if (_couponError != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(_couponError!, style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
              ),
            ],

            // Applied Offer Banner Card
            if (_appliedOffer != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offer "$_appliedPromoCode" Applied!',
                            style: const TextStyle(
                              color: Color(0xFF1E7E34),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'You saved ₹${_discountAmount.toStringAsFixed(2)} (${_discountPct.toStringAsFixed(0)}% OFF on base price)',
                            style: const TextStyle(
                              color: Color(0xFF27AE60),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Available Admin Offers List
            if (_loadingOffers)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC0392B)))),
              )
            else if (_availableOffers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                children: (_showAllOffers ? _availableOffers : _availableOffers.take(2)).map((offer) {
                  final isApplied = _appliedOffer == offer ||
                      (_appliedPromoCode.isNotEmpty && (offer['discount_code']?.toString().toUpperCase() == _appliedPromoCode.toUpperCase()));
                  final pct = num.tryParse((offer['discount_percentage'] ?? offer['discount_percent'] ?? 0).toString())?.round() ?? 0;
                  final code = offer['discount_code']?.toString() ?? offer['promo_code']?.toString();
                  final title = offer['title']?.toString() ?? 'Special Offer';
                  final desc = offer['description']?.toString() ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isApplied ? const Color(0xFFFFF7F7) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isApplied ? const Color(0xFFC0392B) : Colors.grey.shade200,
                        width: isApplied ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_offer, color: Color(0xFFC0392B), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (code != null && code.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC0392B).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        code,
                                        style: const TextStyle(
                                          color: Color(0xFFC0392B),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  if (pct > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF27AE60),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$pct% OFF',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                title,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                              ),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  desc,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isApplied)
                          OutlinedButton(
                            onPressed: _removeCoupon,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: Text('REMOVE'.tr(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        else
                          ElevatedButton(
                            onPressed: () => _selectOffer(offer),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC0392B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              visualDensity: VisualDensity.compact,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: Text('APPLY'.tr(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),

            // Payment Details
            const Text('Payment Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Room Base Price', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('₹${_originalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Offer Discount (${_discountPct.toStringAsFixed(0)}% OFF${_appliedPromoCode.isNotEmpty ? ' - $_appliedPromoCode' : ''})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF27AE60),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '-₹${_discountAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF27AE60),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GST ( 18% )', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('₹${_gstAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payable Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(
                        '₹${_totalPayable.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFC0392B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method
            const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC0392B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.transparent),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.payment, size: 16, color: Colors.white),
                    label: const Text('Online Payment', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Terms
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreedToTerms,
                    activeColor: const Color(0xFFC0392B),
                    onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'I agree to the Terms & Conditions and Cancellation Policy of Yaan.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Confirm & Pay ₹${_totalPayable.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}