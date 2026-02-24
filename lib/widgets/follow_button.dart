import 'package:flutter/material.dart';
import 'package:foodconnect/services/firestore_service.dart';

class FollowButton extends StatefulWidget {
  final String targetUserId;
  final VoidCallback? onToggled;

  const FollowButton({
    required this.targetUserId,
    this.onToggled,
    super.key,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool isFollowing = false;
  bool isLoading = true;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _checkFollowingStatus();
  }

  Future<void> _checkFollowingStatus() async {
    bool following =
        await _firestoreService.isFollowingUser(widget.targetUserId);
    if (mounted) {
      setState(() {
        isFollowing = following;
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => isLoading = true);
    try {
      if (isFollowing) {
        await _firestoreService.unfollowUser(widget.targetUserId);
      } else {
        await _firestoreService.followUser(widget.targetUserId);
      }
      if (mounted) {
        setState(() {
          isFollowing = !isFollowing;
          isLoading = false;
        });
        widget.onToggled?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 40,
      constraints: const BoxConstraints(minWidth: 110),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color:
            isFollowing ? theme.colorScheme.surface : theme.colorScheme.primary,
        border: Border.all(
          color: isFollowing
              ? theme.colorScheme.outline.withValues(alpha: 0.4)
              : theme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isLoading ? null : _toggleFollow,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isFollowing ? "Entfolgen" : "Folgen",
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isFollowing
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
