import 'package:flutter/material.dart';
import 'package:foodconnect/widgets/star_rating.dart';

class RatingDialog extends StatefulWidget {
  final String restaurantId;
  final Function(double, String) onRatingSubmitted; // Hinzugefügter Callback

  // ignore: use_super_parameters
  const RatingDialog({Key? key, required this.restaurantId, required this.onRatingSubmitted}) : super(key: key); // Hinzugefügter Callback

  
  @override
  _RatingDialogState createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 0.0;
  String _reviewText = '';
  final TextEditingController _textController = TextEditingController();

  void _submitRating() {
    // Hier den Callback aufrufen
    widget.onRatingSubmitted(_rating, _reviewText);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Text('Restaurant bewerten', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StarRating(
            onRatingChanged: (rating) {
              setState(() {
                _rating = rating;
              });
            },
            size: 40,
          ),
          SizedBox(height: 20),
          TextField(
            controller: _textController,
            onChanged: (text) {
              setState(() {
                _reviewText = text;
              });
            },
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Optional: Schreibe eine Bewertung',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Abbrechen', style: TextStyle(color: Theme.of(context).colorScheme.onSurface),),
        ),
        ElevatedButton(
          onPressed: _submitRating,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Senden'),
        ),
      ],
    );
  }
}