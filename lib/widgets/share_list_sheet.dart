import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:foodconnect/utils/snackbar_helper.dart';

/// Bottom sheet for sharing a list with mutuals.
class ShareListSheet extends StatefulWidget {
  final String listId;
  final String listName;

  const ShareListSheet({
    super.key,
    required this.listId,
    required this.listName,
  });

  static void show(BuildContext context, String listId, String listName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareListSheet(listId: listId, listName: listName),
    );
  }

  @override
  State<ShareListSheet> createState() => _ShareListSheetState();
}

class _ShareListSheetState extends State<ShareListSheet> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  bool _isLoading = true;
  List<Map<String, dynamic>> _mutuals = [];
  Set<String> _alreadySharedWith = {};
  Set<String> _selectedUserIds = {};
  Map<String, bool> _canEditMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_userId == null) return;
    final mutuals = await _firestoreService.getMutuals(_userId);
    final alreadyShared =
        await _firestoreService.getSharedUsers(_userId, widget.listId);

    if (mounted) {
      setState(() {
        _mutuals = mutuals;
        _alreadySharedWith = alreadyShared.toSet();
        _isLoading = false;
      });
    }
  }

  Future<void> _shareWithSelected() async {
    if (_userId == null || _selectedUserIds.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    for (final targetUid in _selectedUserIds) {
      await _firestoreService.shareListWithUser(
        ownerUserId: _userId,
        listId: widget.listId,
        targetUserId: targetUid,
        listName: widget.listName,
        canEdit: _canEditMap[targetUid] ?? false,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      AppSnackBar.success(context,
          'Liste mit ${_selectedUserIds.length} ${_selectedUserIds.length == 1 ? "Person" : "Personen"} geteilt');
    }
  }

  Future<void> _unshareFrom(String targetUid) async {
    if (_userId == null) return;
    await _firestoreService.unshareListFromUser(
      ownerUserId: _userId,
      listId: widget.listId,
      targetUserId: targetUid,
    );
    setState(() => _alreadySharedWith.remove(targetUid));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Liste teilen',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_selectedUserIds.isNotEmpty)
                  FilledButton.icon(
                    onPressed: _shareWithSelected,
                    icon: Icon(Platform.isIOS
                        ? CupertinoIcons.paperplane_fill
                        : Icons.send),
                    label: Text('Teilen (${_selectedUserIds.length})'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Teile „${widget.listName}" mit deinen Mutuals',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
          ),
          const SizedBox(height: 16),

          // Body
          Flexible(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : _mutuals.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline,
                                size: 48, color: theme.colorScheme.outline),
                            const SizedBox(height: 12),
                            Text('Keine Mutuals',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Du kannst Listen nur mit Mutuals teilen (Nutzer, denen du folgst und die dir folgen).',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 32),
                        itemCount: _mutuals.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 72,
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        itemBuilder: (context, index) {
                          final mutual = _mutuals[index];
                          final uid = mutual['uid'] as String;
                          final isAlreadyShared =
                              _alreadySharedWith.contains(uid);
                          final isSelected = _selectedUserIds.contains(uid);

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundImage: mutual['photoUrl'] != null &&
                                      mutual['photoUrl'].toString().isNotEmpty
                                  ? NetworkImage(mutual['photoUrl'])
                                  : null,
                              child: mutual['photoUrl'] == null ||
                                      mutual['photoUrl'].toString().isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(mutual['name'] ?? 'Nutzer',
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: mutual['username'] != null &&
                                    mutual['username'].toString().isNotEmpty
                                ? Text('@${mutual['username']}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.outline))
                                : null,
                            trailing: isAlreadyShared
                                ? TextButton(
                                    onPressed: () => _unshareFrom(uid),
                                    child: Text('Entfernen',
                                        style: TextStyle(
                                            color: theme.colorScheme.error)),
                                  )
                                : Checkbox.adaptive(
                                    value: isSelected,
                                    onChanged: (val) {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        if (val == true) {
                                          _selectedUserIds.add(uid);
                                        } else {
                                          _selectedUserIds.remove(uid);
                                        }
                                      });
                                    },
                                  ),
                            onTap: isAlreadyShared
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      if (isSelected) {
                                        _selectedUserIds.remove(uid);
                                      } else {
                                        _selectedUserIds.add(uid);
                                      }
                                    });
                                  },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
