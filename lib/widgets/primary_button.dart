import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final Future<void> Function() pressAction;
  final String buttonLabel;

  // ignore: use_super_parameters
  const PrimaryButton({
    Key? key,
    required this.pressAction,
    required this.buttonLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (!context.mounted) return;
        await pressAction();
      },
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(double.infinity,
            55), // Let it expand naturally but with fixed height
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white, // High contrast text on primary
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10), // Clean rounding, not too pill-shaped
        ),
      ),
      child: Text(
        buttonLabel,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
