// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodconnect/screens/home_screen.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class MarkerWidget {
  final String id;
  final String name;
  final LatLng position;
  final String iconPath;
  final String description;
  final String openingHours;
  final String rating;
  final BuildContext parentContext;

  MarkerWidget({
    required this.id,
    required this.name,
    required this.position,
    required this.iconPath, 
    required this.description,
    required this.openingHours,
    required this.rating,
    required this.parentContext,
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
    final BitmapDescriptor icon = BitmapDescriptor.fromBytes(await _loadAssetIconBytes("assets/icons/mapicon.png", 115));

    return Marker(
      markerId: MarkerId(id),
      position: position,
      icon: icon,
      onTap: () {
        showMarkerPanel();
      },
    );
  }

  void showMarkerPanel() async {
    print("🟢 Marker Panel für $name wird geöffnet!");

    String address = await getAddressFromLatLng(position.latitude, position.longitude);


    showModalBottomSheet(
      context: _HomeScreenState.parentContext,
      isScrollControlled: true,
      backgroundColor: Theme.of(parentContext).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
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
                        child: Image.network(iconPath, height: 100, errorBuilder: (context, error, stackTrace) {
                          return Image.asset("assets/icons/mapicon.png", height: 100);
                        }),
                      ),
                    ),
                    SizedBox(height: 16),
                  if (description.isNotEmpty) ...[
                    Text(
                      "📌 Beschreibung",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(description, style: TextStyle(fontSize: 16)),
                    SizedBox(height: 16),
                  ],
                  if (address.isNotEmpty) ...[
                    Text(
                      "📍 Adresse",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(address, style: TextStyle(fontSize: 16)),
                    SizedBox(height: 16),
                  ],
                  if (openingHours.isNotEmpty) ...[
                    Text(
                      "🕒 Öffnungszeiten",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _formatOpeningHours(openingHours),
                    ),
                    SizedBox(height: 16),
                  ],
                  if (rating.isNotEmpty) ...[
                    Text(
                      "⭐ Bewertung",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text("${rating.toString()} / 5.0", style: TextStyle(fontSize: 16)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static List<Widget> _formatOpeningHours(String openingHours) {
    final Map<String, String> daysMap = {
      "Monday": "Montag",
      "Tuesday": "Dienstag",
      "Wednesday": "Mittwoch",
      "Thursday": "Donnerstag",
      "Friday": "Freitag",
      "Saturday": "Samstag",
      "Sunday": "Sonntag"
    };

    List<Widget> formattedHours = [];
    List<String> lines = openingHours.split(" | ");
    for(var line in lines) {
      List<String> parts = line.split(": ");
      if(parts.length == 2) {
        String day = daysMap[parts[0]] ?? parts[0];
        String time = _convertTo24HourFormat(parts[1]);

        if (time.toLowerCase().contains("open 24 hours")) {
          time = "Durchgehend geöffnet";
        } else if (time.toLowerCase().contains("closed")) {
          time = "Geschlossen";
        }

        formattedHours.add(Text("$day: $time", style: TextStyle(fontSize: 16)));
      } else {
        formattedHours.add(Text(line, style: TextStyle(fontSize: 16)));
      }
    }
    return formattedHours;
  }

  static String _convertTo24HourFormat(String timeRange) {
    return timeRange.replaceAllMapped(
      RegExp(r'(\d{1,2}):(\d{2})\s?(AM|PM)\s?[–-]\s?(\d{1,2}):(\d{2})\s?(AM|PM)'),
      (Match m) {
        int startHour = int.parse(m[1]!);
        String startMinute = m[2]!;
        String startPeriod = m[3]!;

        int endHour = int.parse(m[4]!);
        String endMinute = m[5]!;
        String endPeriod = m[6]!;

        // Umwandlung der Startzeit
        if (startPeriod == "PM" && startHour != 12) {
          startHour += 12;
        } else if (startPeriod == "AM" && startHour == 12) {
          startHour = 0;
        }

        // Umwandlung der Endzeit
        if (endPeriod == "PM" && endHour != 12) {
          endHour += 12;
        } else if (endPeriod == "AM" && endHour == 12) {
          endHour = 0;
        }

        return "${startHour.toString().padLeft(2, '0')}:$startMinute - ${endHour.toString().padLeft(2, '0')}:$endMinute";
      },
    );
  }

  // ignore: unused_element
  static Future<BitmapDescriptor> _getCustomIcon(String assetPath, {int width = 115}) async {
    if(assetPath.startsWith("http") || assetPath.startsWith("https")) {
      try {
        final http.Response response = await http.get(Uri.parse(assetPath));
        if (response.statusCode == 200) {
          final Uint8List bytes = response.bodyBytes;
          ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
          ui.FrameInfo fi = await codec.getNextFrame();
          ByteData? resizedData = await fi.image.toByteData(format: ui.ImageByteFormat.png);

          return BitmapDescriptor.fromBytes(resizedData!.buffer.asUint8List());
        }
      } catch (e) {
        print("Fehler beim Laden des Icons: $e");
      }
    }

    return BitmapDescriptor.fromBytes(await _loadAssetIconBytes("assets/icons/mapicon.png", width));
  }

  static Future<Uint8List> _loadAssetIconBytes(String assetPath, int width) async {
    ByteData data = await rootBundle.load(assetPath);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    ByteData? resizedData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return resizedData!.buffer.asUint8List();
  }
}