import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title:
            Text("Meine Listen", style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: user == null
          ? const Center(child: Text("Nicht eingeloggt"))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.streamUserLists(user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          "Ein Fehler ist aufgetreten: ${snapshot.error}"));
                }

                final userLists = snapshot.data ?? [];

                if (userLists.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildListsGrid(userLists);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            "Keine Listen vorhanden",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            "Speichere Restaurants, um sie hier zu finden.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }

  // ─── Long-press context menu ───
  void _showListContextMenu(Offset position, Map<String, dynamic> listData) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
          position & const Size(40, 40), Offset.zero & overlay.size),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          child: ListTile(
            dense: true,
            leading: Icon(
                Platform.isIOS ? CupertinoIcons.pencil : Icons.edit_outlined),
            title: const Text('Umbenennen'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => _showRenameDialog(listData),
        ),
        PopupMenuItem(
          child: ListTile(
            dense: true,
            leading: Icon((listData['isPublic'] ?? false)
                ? CupertinoIcons.lock
                : CupertinoIcons.globe),
            title: Text((listData['isPublic'] ?? false)
                ? 'Auf Privat setzen'
                : 'Auf Öffentlich setzen'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => _toggleVisibility(listData),
        ),
        PopupMenuItem(
          child: const ListTile(
            dense: true,
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Löschen', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => _confirmDelete(listData),
        ),
      ],
    );
  }

  void _showRenameDialog(Map<String, dynamic> listData) {
    final controller = TextEditingController(text: listData['name'] ?? 'Liste');
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
              if (newName.isNotEmpty && user != null) {
                await _firestoreService.renameList(
                    user!.uid, listData['id'], newName);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleVisibility(Map<String, dynamic> listData) async {
    if (user == null) return;
    final newVal = !(listData['isPublic'] ?? false);
    await _firestoreService.toggleListVisibility(
        user!.uid, listData['id'], newVal);
  }

  void _confirmDelete(Map<String, dynamic> listData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liste löschen?'),
        content:
            const Text('Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (user != null) {
                await _firestoreService.deleteList(user!.uid, listData['id']);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Widget _buildListsGrid(List<Map<String, dynamic>> userLists) {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: userLists.length,
      itemBuilder: (context, index) {
        final listData = userLists[index];
        final itemCount = (listData['restaurantIds'] as List?)?.length ?? 0;
        final isPublic = listData['isPublic'] ?? false;
        final coverUrl = listData['coverUrl'] as String?;
        final restaurantIds =
            (listData['restaurantIds'] as List?)?.cast<String>() ?? [];

        return GestureDetector(
          onTap: () {
            context.push('/lists/${listData['id']}', extra: listData);
          },
          onLongPressStart: (details) {
            _showListContextMenu(details.globalPosition, listData);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Spotify-style cover ───
                Expanded(
                  child: _buildCoverArt(
                      coverUrl, restaurantIds, Theme.of(context)),
                ),
                // ─── Footer ───
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listData['name'] ?? 'Unbenannte Liste',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$itemCount Orte",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isPublic ? CupertinoIcons.globe : CupertinoIcons.lock,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
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

  /// Spotify-style mosaic cover: custom image > 4-grid > 1 image > fallback icon
  Widget _buildCoverArt(
      String? coverUrl, List<String> restaurantIds, ThemeData theme) {
    // Custom cover takes priority
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) =>
            Container(color: theme.colorScheme.surfaceContainerHighest),
        errorWidget: (_, __, ___) => _buildFallbackIcon(theme),
      );
    }

    // 4+ restaurants → 2×2 grid
    if (restaurantIds.length >= 4) {
      return FutureBuilder<List<String>>(
        future: _fetchPhotoUrls(restaurantIds.take(4).toList()),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.isEmpty) {
            return _buildFallbackIcon(theme);
          }
          final urls = snap.data!;
          if (urls.length < 4) {
            return _buildSingleCover(urls.first, theme);
          }
          return ClipRRect(
            child: GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              children: urls
                  .map((url) => CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: theme.colorScheme.surfaceContainerHighest),
                        errorWidget: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.restaurant, size: 18)),
                      ))
                  .toList(),
            ),
          );
        },
      );
    }

    // 1-3 restaurants → single cover
    if (restaurantIds.isNotEmpty) {
      return FutureBuilder<List<String>>(
        future: _fetchPhotoUrls([restaurantIds.first]),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.isEmpty) {
            return _buildFallbackIcon(theme);
          }
          return _buildSingleCover(snap.data!.first, theme);
        },
      );
    }

    return _buildFallbackIcon(theme);
  }

  Widget _buildSingleCover(String url, ThemeData theme) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) =>
          Container(color: theme.colorScheme.surfaceContainerHighest),
      errorWidget: (_, __, ___) => _buildFallbackIcon(theme),
    );
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.bookmark,
          size: 32,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// Fetches photo URLs for given restaurant IDs
  Future<List<String>> _fetchPhotoUrls(List<String> ids) async {
    List<String> urls = [];
    for (final id in ids) {
      try {
        final details = await _firestoreService.fetchRestaurantDetails(id);
        if (details != null && details['photoUrl'] != null) {
          final url = details['photoUrl'].toString();
          if (url.isNotEmpty) urls.add(url);
        }
      } catch (_) {}
    }
    return urls;
  }
}
