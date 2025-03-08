import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

class StarRating extends StatefulWidget {
  final double rating;
  final ValueChanged<double>? onRatingChanged;
  final double size;

  StarRating({this.rating = 0.0, this.onRatingChanged, this.size = 30.0});

  @override
  _StarRatingState createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  Widget _buildStar(BuildContext context, int index) {
    Icon icon;
    if (index >= _currentRating) {
      icon = Icon(
        Platform.isIOS ? CupertinoIcons.star : Icons.star_border,
        color: Theme.of(context).colorScheme.primary,
        size: widget.size,
      );
    } else if (index > _currentRating - 1 && index < _currentRating) {
      icon = Icon(
        Platform.isIOS ? CupertinoIcons.star_lefthalf_fill : Icons.star_half,
        color: Theme.of(context).colorScheme.primary,
        size: widget.size,
      );
    } else {
      icon = Icon(
        Platform.isIOS ? CupertinoIcons.star_fill : Icons.star,
        color: Theme.of(context).colorScheme.primary,
        size: widget.size,
      );
    }
    return GestureDetector(
      onTap: () {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localOffset = box.globalToLocal(Offset(box.size.width / 10, box.size.height/2));
        double starWidth = box.size.width / 5;
        double newRating = (localOffset.dx + (index*starWidth)) / starWidth;

        newRating = (newRating * 2).round() / 2;
        setState(() {
            _currentRating = newRating.clamp(index.toDouble(), index + 1.0);
            widget.onRatingChanged?.call(_currentRating);
        });
      },
      onHorizontalDragUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localOffset = box.globalToLocal(details.globalPosition);
        double starWidth = box.size.width / 5;
        double newRating = localOffset.dx / starWidth;
        newRating = newRating.clamp(0.0, 5.0);
        newRating = (newRating * 2).round() / 2;
        setState(() {
          _currentRating = newRating;
          widget.onRatingChanged?.call(_currentRating);
        });
      },
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) => _buildStar(context, index)),
    );
  }
}