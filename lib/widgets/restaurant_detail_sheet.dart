import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:foodconnect/widgets/save_to_list_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🔥 Fix: Added CachedNetworkImage
import 'package:foodconnect/utils/snackbar_helper.dart';
import 'package:foodconnect/utils/match_calculator.dart';
import 'package:foodconnect/widgets/match_badge.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Map<String, dynamic>? _userData;
  String? _address;
  double _finalRating = 0.0;
  
  // ─── Notes State ───
  String? _personalNote;
  bool _isEditingNote = false;
  final TextEditingController _noteController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

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
      final user = FirebaseAuth.instance.currentUser;
      DocumentSnapshot? userDoc;
      if (user != null) {
        userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      }

      final detailsFuture =
          firestoreService.fetchRestaurantDetails(widget.restaurantData['id']);
      final addressFuture = _getAddressFromLatLng(
          widget.restaurantData['latitude'],
          widget.restaurantData['longitude']);

      _details = await detailsFuture;
      _address = await addressFuture;
      if (userDoc != null && userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>;
        
        // Fetch personal note
        _personalNote = await firestoreService.getRestaurantNote(
          user!.uid, 
          widget.restaurantData['id']
        );
        _noteController.text = _personalNote ?? '';
      }
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

  Future<void> _saveNote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final newNote = _noteController.text.trim();
    setState(() {
      _isEditingNote = false;
      _personalNote = newNote.isEmpty ? null : newNote;
    });
    
    await firestoreService.saveRestaurantNote(
      user.uid, 
      widget.restaurantData['id'], 
      newNote,
    );
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
                Stack(
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Hero(
                        tag: 'restaurant_image_${widget.restaurantData['id'] ?? imageUrl}',
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(24)),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest),
                            errorWidget: (_, __, ___) => Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.restaurant, size: 64)),
                          ),
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
                    Positioned(
                      top: 16,
                      right: 16,
                      child: MatchBadge(
                        matchScore: _userData != null ? MatchCalculator.calculate(
                          _userData!,
                          widget.restaurantData,
                        ) : 0,
                      ),
                    ),
                  ],
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
                                AppSnackBar.error(context, "Kann nicht gespeichert werden (ID fehlt)");
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

                      // ─── Personal Note Section ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Persönliche Notiz",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          if (!_isEditingNote)
                            IconButton(
                              icon: Icon(Icons.edit, size: 20, color: Theme.of(context).primaryColor),
                              onPressed: () => setState(() => _isEditingNote = true),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isEditingNote)
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextField(
                                controller: _noteController,
                                maxLines: 3,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: "Z.B. 'Unbedingt die Trüffel-Pasta probieren!'",
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(16),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8, bottom: 8),
                                child: TextButton(
                                  onPressed: _saveNote,
                                  child: const Text("Speichern"),
                                ),
                              )
                            ],
                          ),
                        )
                      else if (_personalNote != null && _personalNote!.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _isEditingNote = true),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _personalNote!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => setState(() => _isEditingNote = true),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Text(
                              "Notiz hinzufügen...",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
