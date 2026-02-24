import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:foodconnect/widgets/rating_dialog.dart';
import 'package:foodconnect/screens/user_profile_screen.dart';
import 'package:foodconnect/widgets/save_to_list_sheet.dart';
import 'package:go_router/go_router.dart';
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
  List<Map<String, dynamic>> _reviews = [];
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
      final reviewsFuture =
          firestoreService.getReviewsForRestaurant(widget.restaurantData['id']);
      double initialRating = double.tryParse(
              widget.restaurantData['rating']?.toString() ?? "0.0") ??
          0.0;

      _details = await detailsFuture;
      _address = await addressFuture;
      _reviews = await reviewsFuture;

      double averageRating = await firestoreService
          .calculateAverageRating(widget.restaurantData['id']);

      if (_reviews.isNotEmpty) {
        _finalRating = (initialRating * 0.5 + averageRating * 0.5);
      } else {
        _finalRating = initialRating;
      }
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

  void _navigateToUserProfileHelper(String userId) {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      if (userId == FirebaseAuth.instance.currentUser?.uid) {
        context.go('/profile');
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(userId: userId),
          ),
        );
      }
    });
  }

  void _showRatingDialogHelper() {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return RatingDialog(
            restaurantId: widget.restaurantData['id'],
            onRatingSubmitted: (rating, comment) async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              final String userId = user.uid;

              const String userName = "Nutzer";
              const String userProfileUrl = "";
              try {
                await firestoreService.addReview(widget.restaurantData['id'],
                    rating, comment, userId, userName, userProfileUrl);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Bewertung erfolgreich gespeichert!"),
                    backgroundColor: Colors.green,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Fehler: ${e.toString()}"),
                      backgroundColor: Colors.red));
                }
              }
            },
          );
        },
      );
    });
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("ID nicht gefunden")));
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

                      // Ratings Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Bewertungen",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: _showRatingDialogHelper,
                            child: const Text("Bewerten",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_reviews.isNotEmpty) ...[
                        Column(
                          children: _reviews.map((review) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => _navigateToUserProfileHelper(
                                        review['userId']),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          review['userProfileUrl'] != null &&
                                                  review['userProfileUrl']
                                                      .isNotEmpty
                                              ? NetworkImage(
                                                  review['userProfileUrl'])
                                              : null,
                                      child: (review['userProfileUrl'] ==
                                                  null ||
                                              review['userProfileUrl'].isEmpty)
                                          ? const Icon(Icons.person, size: 20)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                                review['userName'] ??
                                                    'Unbekannt',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                            Row(
                                              children: [
                                                Icon(Icons.star_rounded,
                                                    size: 16,
                                                    color: Theme.of(context)
                                                        .primaryColor),
                                                const SizedBox(width: 2),
                                                Text("${review['rating']}",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(review['comment'] ?? '',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        Text("Noch keine Bewertungen vorhanden.",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline)),
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
