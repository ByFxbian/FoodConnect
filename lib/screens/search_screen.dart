import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/user_profile_screen.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _query = query.trim();
    if (_query.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    _searchUsers(_query);
  }

  Future<void> _searchUsers(String query) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('lowercaseName', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('lowercaseName',
            isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
        .limit(20)
        .get();

    if (!mounted) return;
    setState(() {
      _results = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      _isLoading = false;
    });
  }

  void _navigateToUserProfile(String userId) {
    if (userId == FirebaseAuth.instance.currentUser?.uid) {
      Navigator.pop(context);
      context.go('/profile');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: userId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back,
              color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Nutzer suchen',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ─── Search Bar ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Name eingeben…',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                prefixIcon: Icon(CupertinoIcons.search,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close,
                            size: 20,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5)),
                        onPressed: () {
                          _controller.clear();
                          _onSearchChanged('');
                          _focusNode.requestFocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Content ───
          Expanded(child: _buildContent(theme)),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    // Empty state
    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_2,
                size: 56,
                color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Suche nach Nutzern',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gib einen Namen ein um loszulegen.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      );
    }

    // Loading
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    // No results
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.search,
                size: 48,
                color: theme.colorScheme.outline.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'Keine Nutzer gefunden.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Results list
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 76,
        color: theme.colorScheme.outline.withValues(alpha: 0.12),
      ),
      itemBuilder: (context, index) {
        final user = _results[index];
        final String name = user['name'] ?? 'Unbekannt';
        final String? photoUrl = user['photoUrl'];
        final String userId = user['id'] ?? '';

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : const AssetImage('assets/icons/default_avatar.png')
                        as ImageProvider,
              ),
            ),
          ),
          title: Text(
            name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          onTap: () => _navigateToUserProfile(userId),
        );
      },
    );
  }
}
