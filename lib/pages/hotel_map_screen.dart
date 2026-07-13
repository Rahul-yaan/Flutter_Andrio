import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HotelMapScreen extends StatefulWidget {
  final Map<String, dynamic> hotel;

  const HotelMapScreen({super.key, required this.hotel});

  @override
  _HotelMapScreenState createState() => _HotelMapScreenState();
}

class _HotelMapScreenState extends State<HotelMapScreen> {
  GoogleMapController? mapController;
  Position? userLocation;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  String? routeDistance;
  String? routeDuration;
  bool isLoading = true;
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      double hotelLat = double.parse(widget.hotel['latitude'].toString());
      double hotelLng = double.parse(widget.hotel['longitude'].toString());

      try {
        userLocation = await _determinePosition();
      } catch (e) {
        userLocation = null;
      }

      markers.add(
        Marker(
          markerId: const MarkerId('hotel'),
          position: LatLng(hotelLat, hotelLng),
          infoWindow: InfoWindow(title: widget.hotel['name'] ?? 'Hotel'),
        ),
      );

      if (userLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('user'),
            position: LatLng(userLocation!.latitude, userLocation!.longitude),
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );

        final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
        final origin = '${userLocation!.latitude},${userLocation!.longitude}';
        final destination = '$hotelLat,$hotelLng';
        final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey';
        
        final res = await http.get(Uri.parse(url));
        final data = jsonDecode(res.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          routeDistance = leg['distance']['text'];
          routeDuration = leg['duration']['text'];
          
          final points = _decodePolyline(route['overview_polyline']['points']);
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: points,
              color: const Color(0xFFC0392B),
              width: 5,
            ),
          );
        } else {
          // Fallback straight line
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: [
                LatLng(userLocation!.latitude, userLocation!.longitude),
                LatLng(hotelLat, hotelLng),
              ],
              color: const Color(0xFFC0392B),
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
        }
      }
      
      setState(() {
        isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = 'Could not load map data.';
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return poly;
  }

  void _setMapBounds(GoogleMapController controller) {
    double hotelLat = double.parse(widget.hotel['latitude'].toString());
    double hotelLng = double.parse(widget.hotel['longitude'].toString());

    if (userLocation == null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(hotelLat, hotelLng), 14));
      });
      return;
    }

    double minLat = userLocation!.latitude < hotelLat ? userLocation!.latitude : hotelLat;
    double maxLat = userLocation!.latitude > hotelLat ? userLocation!.latitude : hotelLat;
    double minLng = userLocation!.longitude < hotelLng ? userLocation!.longitude : hotelLng;
    double maxLng = userLocation!.longitude > hotelLng ? userLocation!.longitude : hotelLng;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route to ${widget.hotel['name'] ?? 'Hotel'}'),
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC0392B)))
          : errorMsg.isNotEmpty
              ? Center(child: Text(errorMsg, style: const TextStyle(color: Colors.red)))
              : Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        mapController = controller;
                        _setMapBounds(controller);
                      },
                      initialCameraPosition: CameraPosition(
                        target: userLocation != null 
                            ? LatLng(userLocation!.latitude, userLocation!.longitude)
                            : LatLng(double.parse(widget.hotel['latitude'].toString()), double.parse(widget.hotel['longitude'].toString())),
                        zoom: 12.0,
                      ),
                      markers: markers,
                      polylines: polylines,
                      myLocationEnabled: userLocation != null,
                      myLocationButtonEnabled: userLocation != null,
                    ),
                    if (routeDistance != null && routeDuration != null)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                            ],
                            border: Border.all(color: const Color(0xFFC0392B).withOpacity(0.3), width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5E8E8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.directions_car, color: Color(0xFFC0392B), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Fastest Route from your Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text('$routeDuration ($routeDistance)', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
