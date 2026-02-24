import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:foodconnect/widgets/restaurant_detail_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

class ListDetailScreen extends StatefulWidget {
  final String listId;
  final Map<String, dynamic>? listData;

  const ListDetailScreen({super.key, required this.listId, this.listData});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = true;
  List<Map<String, dynamic>> _restaurants = [];
  late String _listName;
  late bool _isPublic;

  // Inline rename
  bool _isEditingName = false;
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    _listName = widget.listData?['name'] ?? 'Liste';
    _isPublic = widget.listData?['isPublic'] ?? false;
    _nameController = TextEditingController(text: _listName);
    _nameFocusNode = FocusNode();
    _nameFocusNode.addListener(_onNameFocusChange);
    _fetchRestaurants();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.removeListener(_onNameFocusChange);
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _onNameFocusChange() {
    if (!_nameFocusNode.hasFocus && _isEditingName) {
      _saveInlineName();
    }
  }

  void _startInlineRename() {
    setState(() {
      _isEditingName = true;
      _nameController.text = _listName;
    });
    // Request focus after the frame rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  Future<void> _saveInlineName() async {
    final newName = _nameController.text.trim();
    setState(() => _isEditingName = false);
    if (newName.isNotEmpty && newName != _listName && _userId != null) {
      await _firestoreService.renameList(_userId, widget.listId, newName);
      setState(() => _listName = newName);
    }
  }

  Future<void> _fetchRestaurants() async {
    try {
      final List<dynamic> restaurantIds =
          widget.listData?['restaurantIds'] ?? [];

      List<Map<String, dynamic>> fetchedRestaurants = [];
      for (String id in restaurantIds) {
        final details = await _firestoreService.fetchRestaurantDetails(id);
        if (details != null && details.isNotEmpty) {
          details['id'] = id;
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Rename ───
  void _showRenameDialog() {
    final controller = TextEditingController(text: _listName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liste umbenennen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Neuer Name'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && _userId != null) {
                await _firestoreService.renameList(
                    _userId, widget.listId, newName);
                setState(() => _listName = newName);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  // ─── Toggle visibility ───
  Future<void> _toggleVisibility() async {
    if (_userId == null) return;
    final newVal = !_isPublic;
    await _firestoreService.toggleListVisibility(
        _userId, widget.listId, newVal);
    setState(() => _isPublic = newVal);
  }

  // ─── Delete list ───
  void _confirmDeleteList() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liste löschen?'),
        content: const Text(
            'Diese Liste wird unwiderruflich gelöscht. Restaurants bleiben erhalten.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (_userId != null) {
                await _firestoreService.deleteList(_userId, widget.listId);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  // ─── Custom cover upload ───
  Future<void> _uploadCustomCover() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (photo == null || _userId == null) return;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('list_covers/$_userId/${widget.listId}.jpg');
      await ref.putFile(File(photo.path));
      final url = await ref.getDownloadURL();
      await _firestoreService.updateListCoverUrl(_userId, widget.listId, url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cover-Bild aktualisiert')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Settings sheet ───
  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Platform.isIOS
                    ? CupertinoIcons.pencil
                    : Icons.edit_outlined),
                title: const Text('Umbenennen'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog();
                },
              ),
              ListTile(
                leading: Icon(
                    _isPublic ? CupertinoIcons.globe : CupertinoIcons.lock),
                title: Text(_isPublic ? 'Öffentlich' : 'Privat'),
                subtitle: Text(_isPublic
                    ? 'Jeder kann diese Liste sehen'
                    : 'Nur du kannst diese Liste sehen'),
                onTap: () {
                  _toggleVisibility();
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(Platform.isIOS
                    ? CupertinoIcons.photo
                    : Icons.image_outlined),
                title: const Text('Cover-Bild ändern'),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadCustomCover();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Liste löschen',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteList();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Remove restaurant with undo ───
  void _removeRestaurant(Map<String, dynamic> rest, int index) {
    if (_userId == null) return;
    final restId = rest['id'] as String;

    setState(() => _restaurants.removeAt(index));
    _firestoreService.removeRestaurantFromList(_userId, widget.listId, restId);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${rest['name'] ?? 'Restaurant'} entfernt'),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () {
            _firestoreService.addRestaurantToList(
                _userId, widget.listId, restId);
            setState(() => _restaurants.insert(index, rest));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _isEditingName
            ? TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                style: theme.textTheme.titleLarge,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _saveInlineName(),
              )
            : GestureDetector(
                onTap: _startInlineRename,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(_listName,
                          style: theme.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 4),
                    Icon(CupertinoIcons.pencil,
                        size: 16,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ],
                ),
              ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(Platform.isIOS
                ? CupertinoIcons.ellipsis_circle
                : Icons.more_vert),
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _restaurants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border,
                          size: 56, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text("Noch keine Restaurants.",
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 120),
                  itemCount: _restaurants.length,
                  itemBuilder: (context, index) {
                    final rest = _restaurants[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Dismissible(
                        key: ValueKey(rest['id']),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _removeRestaurant(rest, index),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white, size: 28),
                        ),
                        child: _buildCard(rest),
                      ),
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
      onTap: () => RestaurantDetailSheet.show(context, rest),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 130,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rest['name'] ?? "Restaurant",
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${rest['cuisines'] ?? 'Essen'} • ${rest['priceLevel'] ?? '€€'}",
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
      ),
    );
  }
}
