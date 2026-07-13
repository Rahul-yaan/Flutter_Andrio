import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

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
  
  String _paymentMethod = 'Cash On Delivery';
  bool _agreedToTerms = false;
  bool _loading = false;
  bool _booked = false;

  final List<String> _truckTypes = [
    '4 Wheel', '6 Wheel', '8 Wheel', '10 Wheel',
    '12 Wheel', '14 Wheel', '16 Wheel', '18 Wheel',
    '22 Wheel', '22+ Wheel'
  ];

  double get _price {
    return double.tryParse(widget.hotel['price_per_night'].toString()) ?? 0;
  }

  double get _gstAmount => _price * 0.18;
  double get _totalPayable => _price + _gstAmount;

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
    );

    setState(() => _loading = false);

    if (res.containsKey('error')) {
      _showError(res['error']);
    } else {
      setState(() => _booked = true);
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
              const Text('Booking Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Hotel'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        title: Text(widget.hotel['name'], style: const TextStyle(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mocking the top UI from the screenshot for completeness
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                image: widget.hotel['primary_image'] != null
                    ? DecorationImage(
                        image: NetworkImage('http://127.0.0.1:8000/storage/' + widget.hotel['primary_image']['image_path']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.hotel['primary_image'] == null
                  ? const Center(child: Icon(Icons.hotel, size: 50, color: Colors.grey))
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.hotel['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.hotel['address'] ?? widget.hotel['city'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _openMap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0392B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Direction', style: TextStyle(fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 24),
            
            const Text('Booking Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Select Date
            const Text('Select Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
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
                      _bookingDate == null ? 'Select Date' : '${_bookingDate!.day.toString().padLeft(2, '0')}/${_bookingDate!.month.toString().padLeft(2, '0')}/${_bookingDate!.year}',
                      style: TextStyle(color: _bookingDate == null ? Colors.grey : Colors.black),
                    ),
                    const Icon(Icons.calendar_month, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Truck Type
            const Text('Select Your Truck Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            const Text('Truck No', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _truckNoController,
              decoration: InputDecoration(
                hintText: 'Enter Truck Number',
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Logistics Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _logisticsNameController,
              decoration: InputDecoration(
                hintText: 'Enter Logistics Name',
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Logistics Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _logisticsNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter Logistics Number',
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

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
                      const Text('Total Amount', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Text('₹42.37', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Promotion Applied', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Text('₹0.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GST ( 18% )', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Text('₹7.63', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payable Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const Text('₹50.00', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                    onPressed: () => setState(() => _paymentMethod = 'Cash On Delivery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _paymentMethod == 'Cash On Delivery' ? const Color(0xFFC0392B) : Colors.white,
                      foregroundColor: _paymentMethod == 'Cash On Delivery' ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: _paymentMethod == 'Cash On Delivery' ? Colors.transparent : Colors.grey[300]!),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(Icons.money, size: 16, color: _paymentMethod == 'Cash On Delivery' ? Colors.white : const Color(0xFFC0392B)),
                    label: const Text('Cash On Delivery', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _paymentMethod = 'Online Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _paymentMethod == 'Online Payment' ? const Color(0xFFC0392B) : Colors.white,
                      foregroundColor: _paymentMethod == 'Online Payment' ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: _paymentMethod == 'Online Payment' ? Colors.transparent : Colors.grey[300]!),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(Icons.payment, size: 16, color: _paymentMethod == 'Online Payment' ? Colors.white : Colors.black),
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
                    'I agree to Pay After Service and other terms & conditions.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _loading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('PROCEED', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
