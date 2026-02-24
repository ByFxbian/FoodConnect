import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodconnect/services/database_service.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:foodconnect/utils/snackbar_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Bottom sheet to search and add restaurants to a specific list.
class AddRestaurantSheet extends StatefulWidget {
  final String listId;
  final List<String> existingRestaurantIds;

  const AddRestaurantSheet({
    super.key,
    required this.listId,
    required this.existingRestaurantIds,
  });

  static Future<bool?> show(
      BuildContext context, String listId, List<String> existingIds) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRestaurantSheet(
        listId: listId,
        existingRestaurantIds: existingIds,
      ),
    );
  }

  @override
  State<AddRestaurantSheet> createState() => _AddRestaurantSheetState();
}

class _AddRestaurantSheetState extends State<AddRestaurantSheet> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _dbService = DatabaseService();
  final _firestoreService = FirestoreService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  List<Map<String, dynamic>> _results = [];
  Set<String> _addedIds = {};
  bool _searching = false;
  bool _didAdd = false;

  @override
  void initState() {
    super.initState();
    _addedIds = Set<String>.from(widget.existingRestaurantIds);
    // Auto-focus search after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _loadAllRestaurants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAllRestaurants() async {
    setState(() => _searching = true);
    final all = await _dbService.getAllRestaurants();
    if (mounted) {
      setState(() {
        _results = all;
        _searching = false;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _loadAllRestaurants();
      return;
    }
    setState(() => _searching = true);
    final results = await _dbService.searchRestaurants(query.trim());
    if (mounted) {
      setState(() {
        _results = results;
        _searching = false;
      });
    }
  }

  Future<void> _addToList(Map<String, dynamic> restaurant) async {
    if (_userId == null) return;
    final id = restaurant['id'] as String;
    HapticFeedback.lightImpact();

    await _firestoreService.addRestaurantToList(_userId, widget.listId, id);
    setState(() {
      _addedIds.add(id);
      _didAdd = true;
    });
    if (mounted) {
      AppSnackBar.success(context, '${restaurant['name']} hinzugefügt');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Handle ───
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Header ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Restaurant hinzufügen',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context, _didAdd),
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 28),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── Search Field ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Restaurant suchen…',
                prefixIcon: Icon(CupertinoIcons.search,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _loadAllRestaurants();
                        },
                        icon: const Icon(CupertinoIcons.clear_circled_solid,
                            size: 20),
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ─── Results ───
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator.adaptive())
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.search,
                                  size: 48,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text('Keine Restaurants gefunden',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5))),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 32),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 72,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.08),
                        ),
                        itemBuilder: (context, index) {
                          final r = _results[index];
                          final id = r['id'] as String;
                          final name = r['name'] ?? 'Restaurant';
                          final icon = r['icon'] as String?;
                          final rating = r['rating']?.toString() ?? '';
                          final cuisines = r['cuisines'] ?? '';
                          final alreadyAdded = _addedIds.contains(id);

                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: icon != null && icon.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: icon,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          color: theme.colorScheme
                                              .surfaceContainerHighest,
                                          child: Icon(
                                              CupertinoIcons.building_2_fill,
                                              size: 20,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.3)),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          color: theme.colorScheme
                                              .surfaceContainerHighest,
                                          child: Icon(
                                              CupertinoIcons.building_2_fill,
                                              size: 20,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.3)),
                                        ),
                                      )
                                    : Container(
                                        color: theme.colorScheme
                                            .surfaceContainerHighest,
                                        child: Icon(
                                            CupertinoIcons.building_2_fill,
                                            size: 20,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.3)),
                                      ),
                              ),
                            ),
                            title: Text(name,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              [
                                if (rating.isNotEmpty) '⭐ $rating',
                                if (cuisines.toString().isNotEmpty)
                                  cuisines.toString(),
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5)),
                            ),
                            trailing: alreadyAdded
                                ? Icon(CupertinoIcons.checkmark_circle_fill,
                                    color: Colors.green.shade600, size: 28)
                                : IconButton(
                                    onPressed: () => _addToList(r),
                                    icon: Icon(CupertinoIcons.plus_circle_fill,
                                        size: 28, color: theme.primaryColor),
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
