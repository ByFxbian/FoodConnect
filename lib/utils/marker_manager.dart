import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerManager {
  static final MarkerManager _instance = MarkerManager._internal();
  factory MarkerManager() => _instance;
  MarkerManager._internal();

  BitmapDescriptor? customIcon;
  BitmapDescriptor? highlightedIcon;

  Future<void> loadCustomIcons() async {
    if (customIcon != null) return;

    try {
      customIcon =
          await _bitmapDescriptorFromAssetBytes('assets/icons/mapicon.png', 50);

      highlightedIcon =
          await _bitmapDescriptorFromAssetBytes('assets/icons/mapicon.png', 70);
    } catch (e) {
      print("Fehler beim Laden der Icons: $e");
    }
  }

  Future<BitmapDescriptor> _bitmapDescriptorFromAssetBytes(
      String path, int width) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui
        .instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData =
        await fi.image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception("Bild konnte nicht konvertiert werden.");
    }

    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  Future<BitmapDescriptor> getClusterIcon(int size, Color primaryColor) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = primaryColor;
    final Paint paint2 = Paint()..color = const Color(0xFFFFFFFF);

    canvas.drawCircle(const Offset(40, 40), 40, paint2);
    canvas.drawCircle(const Offset(40, 40), 36, paint1);

    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: size.toString(),
      style: const TextStyle(fontSize: 32, color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(40 - painter.width / 2, 40 - painter.height / 2),
    );

    final img = await pictureRecorder.endRecording().toImage(80, 80);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

}
