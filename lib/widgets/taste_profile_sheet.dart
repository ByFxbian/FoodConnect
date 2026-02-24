import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:foodconnect/utils/snackbar_helper.dart';

/// A beautiful, editorial-style bottom sheet for setting up or editing the
/// user's taste profile: favourite cuisines, price range, and dietary preference.
class TasteProfileSheet extends StatefulWidget {
  /// If true, the sheet can be dismissed (edit mode). If false, it's mandatory (onboarding).
  final bool dismissible;

  const TasteProfileSheet({super.key, this.dismissible = true});

  /// Convenience method to show this sheet.
  static Future<void> show(BuildContext context, {bool dismissible = true}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: Colors.transparent,
      builder: (_) => TasteProfileSheet(dismissible: dismissible),
    );
  }

  @override
  State<TasteProfileSheet> createState() => _TasteProfileSheetState();
}

class _TasteProfileSheetState extends State<TasteProfileSheet> {
  // ─── Cuisine options ───
  static const List<_CuisineOption> _cuisines = [
    _CuisineOption('Italienisch', '🍕'),
    _CuisineOption('Asiatisch', '🍜'),
    _CuisineOption('Mexikanisch', '🌮'),
    _CuisineOption('Indisch', '🍛'),
    _CuisineOption('Amerikanisch', '🍔'),
    _CuisineOption('Türkisch', '🥙'),
    _CuisineOption('Japanisch', '🍣'),
    _CuisineOption('Mediterran', '🫒'),
  ];

  // ─── Price levels ───
  static const List<String> _priceLevels = ['€', '€€', '€€€', '€€€€'];

  // ─── Diet options ───
  static const List<String> _dietOptions = [
    'Allesesser',
    'Vegetarisch',
    'Vegan'
  ];

  final Set<String> _selectedCuisines = {};
  String _selectedPrice = '€€';
  String _selectedDiet = 'Allesesser';
  bool _isSaving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      final tp = doc.data()?['tasteProfile'] as Map<String, dynamic>?;
      if (tp != null) {
        setState(() {
          final cuisines = tp['favoriteCuisines'];
          if (cuisines is List) {
            _selectedCuisines.addAll(cuisines.cast<String>());
          }
          _selectedPrice = tp['priceRange'] ?? '€€';
          _selectedDiet = tp['dietType'] ?? 'Allesesser';
        });
      }
    } catch (_) {}
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'tasteProfile': {
          'favoriteCuisines': _selectedCuisines.toList(),
          'priceRange': _selectedPrice,
          'dietType': _selectedDiet,
        },
      }, SetOptions(merge: true));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppSnackBar.error(
            context, 'Fehler beim Speichern des Geschmacksprofils.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: !_loaded
            ? const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Text('Dein Geschmack',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      'Hilf uns, dir die besten Restaurants zu zeigen.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 28),

                    // ─── Cuisines ───
                    _sectionTitle(
                        theme, 'Lieblingsküchen', CupertinoIcons.flame),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _cuisines.map((c) {
                        final selected = _selectedCuisines.contains(c.name);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedCuisines.remove(c.name);
                              } else {
                                _selectedCuisines.add(c.name);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? theme.primaryColor
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: selected
                                    ? theme.primaryColor
                                    : theme.colorScheme.outline
                                        .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(c.emoji,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  c.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // ─── Price Range ───
                    _sectionTitle(
                        theme, 'Preisrange', CupertinoIcons.money_euro),
                    const SizedBox(height: 12),
                    Row(
                      children: _priceLevels.map((p) {
                        final selected = _selectedPrice == p;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPrice = p),
                            child: AnimatedContainer(
                              duration: 200.ms,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? theme.primaryColor
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? theme.primaryColor
                                      : theme.colorScheme.outline
                                          .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                p,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // ─── Diet ───
                    _sectionTitle(theme, 'Ernährung',
                        CupertinoIcons.leaf_arrow_circlepath),
                    const SizedBox(height: 12),
                    Row(
                      children: _dietOptions.map((d) {
                        final selected = _selectedDiet == d;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedDiet = d),
                            child: AnimatedContainer(
                              duration: 200.ms,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? theme.primaryColor
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? theme.primaryColor
                                      : theme.colorScheme.outline
                                          .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                d,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // ─── Save Button ───
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2.5))
                            : Text(
                                widget.dismissible ? 'Speichern' : 'Weiter',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.primaryColor),
        const SizedBox(width: 8),
        Text(title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _CuisineOption {
  final String name;
  final String emoji;
  const _CuisineOption(this.name, this.emoji);
}
