import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final Future<void> Function() pressAction;
  final String buttonLabel;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.pressAction,
    required this.buttonLabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: isLoading
            ? null
            : () async {
                if (!context.mounted) return;
                await pressAction();
              },
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          disabledBackgroundColor:
              Theme.of(context).primaryColor.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  letterSpacing: 0.1,
                ),
              ),
      ),
    );
  }
}
