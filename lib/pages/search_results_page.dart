import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'hotel_detail_page.dart';

class SearchResultsPage extends StatefulWidget {
  final List<Map<String, dynamic>> hotels;
  final double fromLat, fromLng, toLat, toLng;
  final String fromCity, toCity;

  const SearchResultsPage({
    super.key,
    required this.hotels,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.fromCity,
    required this.toCity,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  bool _showMap = true;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  void _buildMarkers() {
    final markers = <Marker>{};

    // From marker
    markers.add(
      Marker(
        markerId: const MarkerId('from'),
        position: LatLng(widget.fromLat, widget.fromLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: widget.fromCity),
      ),
    );

    // To marker
    markers.add(
      Marker(
        markerId: const MarkerId('to'),
        position: LatLng(widget.toLat, widget.toLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.toCity),
      ),
    );

    // Hotel markers
    for (var hotel in widget.hotels) {
      markers.add(
        Marker(
          markerId: MarkerId('hotel_${hotel['id']}'),
          position: LatLng(hotel['latitude'], hotel['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: hotel['name'],
            snippet: '₹${hotel['price_per_night']}/night',
          ),
          onTap: () => _goToHotel(hotel),
        ),
      );
    }

    setState(() => _markers = markers);
  }

  void _goToHotel(Map<String, dynamic> hotel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HotelDetailPage(hotelId: hotel['id'])),
    );
  }

  LatLng get _midpoint => LatLng(
    (widget.fromLat + widget.toLat) / 2,
    (widget.fromLng + widget.toLng) / 2,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        title: Text(
          '${widget.fromCity} → ${widget.toCity}',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showMap = !_showMap),
            icon: Icon(
              _showMap ? Icons.list : Icons.map,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              _showMap ? 'List' : 'Map',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Results count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  '${widget.hotels.length} hotels found on route',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF444444),
                  ),
                ),
              ],
            ),
          ),

          Expanded(child: _showMap ? _mapView() : _listView()),
        ],
      ),
    );
  }

  Widget _mapView() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _midpoint, zoom: 7),
          markers: _markers,
          onMapCreated: (controller) => _mapController = controller,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
        ),

        // Hotel list at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: widget.hotels.length,
              itemBuilder: (_, i) => _HotelMapCard(
                hotel: widget.hotels[i],
                onTap: () => _goToHotel(widget.hotels[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _listView() {
    if (widget.hotels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel, size: 64, color: Color(0xFFDDDDDD)),
            SizedBox(height: 16),
            Text(
              'No hotels found on this route',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.hotels.length,
      itemBuilder: (_, i) => _HotelListCard(
        hotel: widget.hotels[i],
        onTap: () => _goToHotel(widget.hotels[i]),
      ),
    );
  }
}

class _HotelMapCard extends StatelessWidget {
  final Map<String, dynamic> hotel;
  final VoidCallback onTap;

  const _HotelMapCard({required this.hotel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E8E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.hotel, color: Color(0xFFC0392B), size: 32),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hotel['name'] ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '₹${hotel['price_per_night']}/night',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFC0392B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HotelListCard extends StatelessWidget {
  final Map<String, dynamic> hotel;
  final VoidCallback onTap;

  const _HotelListCard({required this.hotel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFF5E8E8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: const Center(
                child: Icon(Icons.hotel, color: Color(0xFFC0392B), size: 36),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotel['city'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${hotel['price_per_night']}/night',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC0392B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E8E8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: Color(0xFFF39C12),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                hotel['rating'].toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
