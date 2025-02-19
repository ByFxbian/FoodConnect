import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MarkerWidget {
  final String id;
  final String name;
  final LatLng position;
  final String iconPath;
  final String description;

  MarkerWidget({
    required this.id,
    required this.name,
    required this.position,
    required this.iconPath, 
    required this.description,
  });

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street}, ${place.locality}, ${place.country}";
      }
      return "Adresse nicht gefunden";
    } catch (e) {
      print("Fehler beim Abrufen der Adresse: $e");
      return "Adresse nicht verfügbar";
    }
  }

  Future<Marker> toMarker(BuildContext context) async {
    final BitmapDescriptor icon = await _getCustomIcon(iconPath);

    return Marker(
      markerId: MarkerId(id),
      position: position,
      icon: icon,
      onTap: () {
        _showMarkerPanel(context);
      },
    );
  }

  void _showMarkerPanel(BuildContext context) async {
    String address = await getAddressFromLatLng(position.latitude, position.longitude);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    address, // Hier wird die Adresse angezeigt
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(iconPath, height: 100),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    description,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<BitmapDescriptor> _getCustomIcon(String assetPath, {int width = 35}) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();

    ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    ByteData? resizedData = await fi.image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(resizedData!.buffer.asUint8List());
  }
}