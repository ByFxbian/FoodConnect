import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:foodconnect/widgets/save_to_list_sheet.dart';
import 'package:foodconnect/utils/snackbar_helper.dart';
import 'package:geocoding/geocoding.dart';

class RestaurantDetailSheet extends StatefulWidget {
  final Map<String, dynamic> restaurantData;

  const RestaurantDetailSheet({super.key, required this.restaurantData});

  static void show(BuildContext context, Map<String, dynamic> restaurantData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          RestaurantDetailSheet(restaurantData: restaurantData),
    );
  }

  @override
  State<RestaurantDetailSheet> createState() => _RestaurantDetailSheetState();
}

class _RestaurantDetailSheetState extends State<RestaurantDetailSheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _details;
  String? _address;
  double _finalRating = 0.0;

  final FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street}, ${place.locality}, ${place.country}";
      }
      return "Adresse nicht gefunden";
    } catch (e) {
      debugPrint("Fehler beim Abrufen der Adresse: $e");
      return "Adresse nicht verfügbar";
    }
  }

  Future<void> _loadData() async {
    try {
      final detailsFuture =
          firestoreService.fetchRestaurantDetails(widget.restaurantData['id']);
      final addressFuture = _getAddressFromLatLng(
          widget.restaurantData['latitude'],
          widget.restaurantData['longitude']);

      _details = await detailsFuture;
      _address = await addressFuture;
      _finalRating = double.tryParse(
              widget.restaurantData['rating']?.toString() ?? '0.0') ??
          0.0;
    } catch (e) {
      debugPrint("Fehler beim Laden der Marker-Panel-Daten: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollContainer) {
            return Center(child: CircularProgressIndicator.adaptive());
          });
    }

    final imageUrl = widget.restaurantData['photoUrl'] as String?;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollContainer) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
                top: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.5),
                    width: 1.0)),
          ),
          child: SingleChildScrollView(
            controller: scrollContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image Area
                if (imageUrl != null && imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Icon(Icons.restaurant,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Save Action Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.restaurantData['name'] ?? "Unbekannt",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: () {
                              if (widget.restaurantData['id'] != null) {
                                SaveToListSheet.show(
                                    context, widget.restaurantData['id']);
                              } else {
                                AppSnackBar.error(
                                    context, 'Restaurant-ID nicht gefunden.');
                              }
                            },
                            icon: const Icon(CupertinoIcons.bookmark),
                            color: Theme.of(context).primaryColor,
                            iconSize: 28,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Subinfo Row (Rating, Distance, etc.)
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 20,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              _finalRating.toStringAsFixed(1),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (_details?['priceLevel'] != null) ...[
                              const SizedBox(width: 12),
                              Text("•",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline)),
                              const SizedBox(width: 12),
                              Text(_details!['priceLevel'],
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ]),
                      const SizedBox(height: 16),

                      Text(
                        _address ?? "Adresse nicht verfügbar",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 24),

                      if (_details?['description'] != null) ...[
                        Text("Beschreibung",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_details!['description'],
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
