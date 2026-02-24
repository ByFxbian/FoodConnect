import 'package:flutter/material.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:foodconnect/widgets/restaurant_detail_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ListDetailScreen extends StatefulWidget {
  final String listId;
  final Map<String, dynamic>? listData;

  const ListDetailScreen({super.key, required this.listId, this.listData});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _restaurants = [];

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    try {
      final List<dynamic> restaurantIds =
          widget.listData?['restaurantIds'] ?? [];

      List<Map<String, dynamic>> fetchedRestaurants = [];
      for (String id in restaurantIds) {
        final details = await _firestoreService.fetchRestaurantDetails(id);
        if (details != null && details.isNotEmpty) {
          details['id'] = id; // Ensure ID is present
          fetchedRestaurants.add(details);
        }
      }

      if (mounted) {
        setState(() {
          _restaurants = fetchedRestaurants;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching list details: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listName = widget.listData?['name'] ?? 'Liste';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(listName, style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _restaurants.isEmpty
              ? Center(
                  child: Text(
                    "Noch keine Restaurants in dieser Liste.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 40),
                  itemCount: _restaurants.length,
                  itemBuilder: (context, index) {
                    final rest = _restaurants[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildCard(rest),
                    );
                  },
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> rest) {
    final imageUrl = rest['photoUrl'] != null &&
            rest['photoUrl'].toString().isNotEmpty
        ? rest['photoUrl']
        : "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=1000&auto=format&fit=crop";

    return GestureDetector(
      onTap: () {
        RestaurantDetailSheet.show(context, rest);
      },
      child: Container(
        height: 130,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 130,
              height: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: Theme.of(context).colorScheme.outline),
                errorWidget: (_, __, ___) => Container(
                    color: Theme.of(context).colorScheme.outline,
                    child: const Icon(Icons.restaurant)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rest['name'] ?? "Restaurant",
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${rest['cuisines'] ?? 'Essen'} • ${rest['priceLevel'] ?? '€€'}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: Theme.of(context).primaryColor, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          "${rest['rating'] ?? 0.0}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
