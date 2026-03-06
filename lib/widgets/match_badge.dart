import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MatchBadge extends StatelessWidget {
  final int matchScore;
  final bool animate;

  const MatchBadge({
    super.key,
    required this.matchScore,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (matchScore <= 0) return const SizedBox.shrink();

    // Determine colors based on score
    final bool isHighMatch = matchScore >= 75;
    final Color badgeColor = isHighMatch 
        ? Colors.green.shade600 
        : Theme.of(context).colorScheme.primary;

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isHighMatch ? Icons.local_fire_department_rounded : Icons.star_rounded,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            "$matchScore% Match",
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );

    if (animate && isHighMatch) {
      badge = badge.animate().scale(
        duration: 300.ms, curve: Curves.easeOutBack,
      );
    }

    return badge;
  }
}
