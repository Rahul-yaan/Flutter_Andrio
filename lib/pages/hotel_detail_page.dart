import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';
import 'booking_page.dart';
import 'login_page.dart';
import 'hotel_map_screen.dart';
import '../utils/image_utils.dart';
class HotelDetailPage extends StatefulWidget {
  final int hotelId;
  const HotelDetailPage({super.key, required this.hotelId});

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  Map<String, dynamic>? _hotel;
  List<dynamic> _reviews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHotel();
  }

  Future<void> _loadHotel() async {
    final result = await ApiService.getHotelDetail(hotelId: widget.hotelId);
    final reviewResult =
        await ApiService.getHotelReviews(hotelId: widget.hotelId);

    setState(() {
      _loading = false;
      if (result['hotel'] != null) {
        _hotel = result['hotel'];
      } else {
        _error = result['error'] ?? 'Failed to load hotel';
      }
      if (reviewResult['reviews'] != null) {
        _reviews = reviewResult['reviews'];
      }
    });
  }

  void _showReviewDialog() {
    int rating = 5;
    final TextEditingController commentController = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Write a Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Rating', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFF39C12),
                          size: 40,
                        ),
                        onPressed: () {
                          setModalState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFC0392B)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: submitting ? null : () async {
                        final token = await ApiService.getToken();
                        if (token == null) {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                          return;
                        }
                        setModalState(() => submitting = true);
                        final res = await ApiService.submitReview(
                          hotelId: widget.hotelId,
                          rating: rating,
                          comment: commentController.text.trim(),
                        );
                        setModalState(() => submitting = false);
                        if (res.containsKey('error')) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error']), backgroundColor: Colors.red));
                          }
                        } else {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!'), backgroundColor: Colors.green));
                            _loadHotel(); // Reload reviews and hotel rating
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC0392B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: submitting 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  IconData _getAmenityIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('wifi')) return Icons.wifi;
    if (name.contains('parking')) return Icons.local_parking;
    if (name.contains('pool') || name.contains('swim')) return Icons.pool;
    if (name.contains('restaurant') || name.contains('dining') || name.contains('food')) return Icons.restaurant;
    if (name.contains('gym') || name.contains('fitness')) return Icons.fitness_center;
    if (name.contains('bar')) return Icons.local_bar;
    if (name.contains('laundry')) return Icons.local_laundry_service;
    if (name.contains('ac') || name.contains('air condition')) return Icons.ac_unit;
    if (name.contains('spa')) return Icons.spa;
    if (name.contains('tv')) return Icons.tv;
    if (name.contains('fuel')) return Icons.local_gas_station;
    if (name.contains('rest room') || name.contains('toilet') || name.contains('shower')) return Icons.bathroom;
    if (name.contains('atm')) return Icons.atm;
    if (name.contains('first aid') || name.contains('medical')) return Icons.medical_services;
    if (name.contains('store') || name.contains('convenience')) return Icons.store;
    if (name.contains('seating')) return Icons.event_seat;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFC0392B))),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFC0392B),
          foregroundColor: Colors.white,
          title: const Text('Hotel Detail'),
        ),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFFC0392B),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Builder(
                    builder: (context) {
                      String? imageUrl = ImageUtils.getHotelImageUrl(_hotel);

                      if (imageUrl != null) {
                        return Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFFF5E8E8),
                            child: const Center(
                              child: Icon(Icons.hotel, size: 80, color: Color(0xFFC0392B)),
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          color: const Color(0xFFF5E8E8),
                          child: const Center(
                            child: Icon(Icons.hotel, size: 80, color: Color(0xFFC0392B)),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _hotel!['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E8E8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: Color(0xFFF39C12)),
                            const SizedBox(width: 4),
                            Text(
                              _hotel!['rating'].toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Color(0xFFC0392B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_hotel!['city']} — ${_hotel!['address']}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Price and rooms
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Column(
                            children: [
                              const Text('Price/Night',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888888))),
                              const SizedBox(height: 4),
                              Text(
                                '₹${_hotel!['price_per_night']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFC0392B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Column(
                            children: [
                              const Text('Available Slots',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888888))),
                              const SizedBox(height: 4),
                              Text(
                                '${_hotel!['available_rooms']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF27AE60),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  if (_hotel!['description'] != null) ...[
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hotel!['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Amenities
                  const Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      List<dynamic> amenitiesList = [];
                      if (_hotel!['amenities'] != null) {
                        if (_hotel!['amenities'] is List) {
                          amenitiesList = _hotel!['amenities'] as List;
                        } else if (_hotel!['amenities'].toString().isNotEmpty) {
                          amenitiesList = _hotel!['amenities'].toString().split(',');
                        }
                      }
                      
                      if (amenitiesList.isEmpty) {
                        return const Text(
                          'No amenities listed.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        );
                      }
                      
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: amenitiesList.map((amenity) {
                          String amenityName = '';
                          if (amenity is Map && amenity.containsKey('name')) {
                            amenityName = amenity['name'].toString();
                          } else {
                            amenityName = amenity.toString();
                            amenityName = amenity.toString().trim();
                          }
                          return Container(
                            width: (MediaQuery.of(context).size.width - 56) / 2, // 2 columns
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5E8E8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.check, color: Color(0xFFC0392B), size: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    amenityName.trim(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }
                  ),
                  const SizedBox(height: 16),

                  // Reviews
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showReviewDialog,
                        icon: const Icon(Icons.edit, size: 16, color: Color(0xFFC0392B)),
                        label: const Text('Write a Review', style: TextStyle(color: Color(0xFFC0392B), fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  if (_reviews.isEmpty)
                    const Text(
                      'No reviews yet.',
                      style: TextStyle(color: Color(0xFF888888)),
                    )
                  else
                    ..._reviews.map((r) => _ReviewCard(review: r)),

                  const SizedBox(height: 24),
                  const Text(
                    'Location & Route',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SmallRouteMap(hotel: _hotel!),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Book Now button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _hotel!['available_rooms'] == 0
                ? null
                : () async {
                    final token = await ApiService.getToken();
                    if (token == null) {
                      if (mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                      }
                    } else {
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingPage(hotel: _hotel!),
                          ),
                        );
                      }
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
              _hotel!['available_rooms'] == 0
                  ? 'No Slots Available'
                  : 'Book Now — ₹${_hotel!['price_per_night']}/night',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review['user']?['name'] ?? 'User',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    size: 14,
                    color: i < (review['rating'] ?? 0)
                        ? const Color(0xFFF39C12)
                        : const Color(0xFFDDDDDD),
                  ),
                ),
              ),
            ],
          ),
          if (review['comment'] != null) ...[
            const SizedBox(height: 6),
            Text(
              review['comment'],
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallRouteMap extends StatelessWidget {
  final Map<String, dynamic> hotel;
  const _SmallRouteMap({required this.hotel});

  @override
  Widget build(BuildContext context) {
    double hotelLat = 0.0;
    double hotelLng = 0.0;
    try {
      hotelLat = double.parse(hotel['latitude'].toString());
      hotelLng = double.parse(hotel['longitude'].toString());
    } catch (e) {
      // fallback
    }

    final target = LatLng(hotelLat, hotelLng);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HotelMapScreen(hotel: hotel),
          ),
        );
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: target,
                zoom: 15.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('hotel'),
                  position: target,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                )
              },
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            // Startup style overlay
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC0392B),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View on Map',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.open_in_full, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}