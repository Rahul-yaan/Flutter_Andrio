import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HotelDetailScreen extends StatelessWidget {
  final Map hotel;

  HotelDetailScreen({required this.hotel});

  @override
  Widget build(BuildContext context) {
    final lat = double.parse(hotel['lat'].toString());
    final lng = double.parse(hotel['lng'].toString());

    return Scaffold(
      appBar: AppBar(title: Text(hotel['name'])),
      body: Column(
        children: [

          /// 🗺️ GOOGLE MAP
          Container(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(lat, lng),
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: MarkerId("hotel"),
                  position: LatLng(lat, lng),
                )
              },
            ),
          ),

          SizedBox(height: 10),

          Text("₹${hotel['price_per_hour']} / hr"),

          ElevatedButton(
            onPressed: () {},
            child: Text("Book Now"),
          )
        ],
      ),
    );
  }
}