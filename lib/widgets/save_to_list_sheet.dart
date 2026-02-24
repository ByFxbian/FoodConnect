import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodconnect/services/firestore_service.dart';

class SaveToListSheet extends StatefulWidget {
  final String restaurantId;

  const SaveToListSheet({super.key, required this.restaurantId});

  static void show(BuildContext context, String restaurantId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SaveToListSheet(restaurantId: restaurantId),
    );
  }

  @override
  State<SaveToListSheet> createState() => _SaveToListSheetState();
}

class _SaveToListSheetState extends State<SaveToListSheet> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _userLists = [];

  @override
  void initState() {
    super.initState();
    _fetchLists();
  }

  Future<void> _fetchLists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final lists = await _firestoreService.getUserLists(user.uid);
      if (mounted) {
        setState(() {
          _userLists = lists;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching lists: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleRestaurantInList(Map<String, dynamic> list) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final listId = list['id'];
    List<dynamic> restaurantIds = list['restaurantIds'] ?? [];
    final isSaved = restaurantIds.contains(widget.restaurantId);

    setState(() {
      if (isSaved) {
        restaurantIds.remove(widget.restaurantId);
      } else {
        restaurantIds.add(widget.restaurantId);
      }
      list['restaurantIds'] = restaurantIds;
    });

    try {
      if (isSaved) {
        await _firestoreService.removeRestaurantFromList(
            user.uid, listId, widget.restaurantId);
      } else {
        await _firestoreService.addRestaurantToList(
            user.uid, listId, widget.restaurantId);
      }
    } catch (e) {
      debugPrint("Error updating list: $e");
      setState(() {
        if (isSaved) {
          restaurantIds.add(widget.restaurantId);
        } else {
          restaurantIds.remove(widget.restaurantId);
        }
        list['restaurantIds'] = restaurantIds;
      });
    }
  }

  Future<void> _createNewList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String listName = "";
    final result = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Neue Liste erstellen"),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Listenname, z. B. 'Pizza in Berlin'",
              ),
              onChanged: (val) => listName = val,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Abbrechen"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, listName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Erstellen"),
              ),
            ],
          );
        });

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService
            .createList(user.uid, result, restaurantIds: [widget.restaurantId]);
        await _fetchLists();
      } catch (e) {
        debugPrint("Error creating list: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Speichern in Liste",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3)),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(48.0),
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (_userLists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 48.0, horizontal: 24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.list_alt,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        "Du hast noch keine Listen",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Erstelle eine Liste, um deine Lieblingsrestaurants zu speichern.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _userLists.length,
                  itemBuilder: (context, index) {
                    final list = _userLists[index];
                    final List<dynamic> restaurantIds =
                        list['restaurantIds'] ?? [];
                    final isSaved = restaurantIds.contains(widget.restaurantId);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 4.0),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.format_list_bulleted,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      title: Text(
                        list['name'] ?? 'Ohne Namen',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${restaurantIds.length} Orte",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6)),
                      ),
                      trailing: isSaved
                          ? Icon(Icons.check_circle,
                              color: Theme.of(context).primaryColor)
                          : Icon(Icons.circle_outlined,
                              color: Theme.of(context).colorScheme.outline),
                      onTap: () => _toggleRestaurantInList(list),
                    );
                  },
                ),
              ),
            Divider(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton.icon(
                onPressed: _createNewList,
                icon: const Icon(Icons.add),
                label: const Text("Neue Liste erstellen"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
