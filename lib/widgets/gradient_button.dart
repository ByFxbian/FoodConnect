import 'package:flutter/material.dart';
import 'package:foodconnect/utils/Palette.dart';

class GradientButton extends StatelessWidget {
  final Future<void> Function() pressAction;
  final String buttonLabel;

  // ignore: use_super_parameters
  const GradientButton({
    Key? key,
    required this.pressAction,
    required this.buttonLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Palette.gradient1,
            Palette.gradient2,
            Palette.gradient3
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: ElevatedButton(
        onPressed: () async {
          await pressAction();
        },
        style: ElevatedButton.styleFrom(
          fixedSize: const Size(395, 55),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          buttonLabel,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.white
          ),
        ),
      ),
    );
  }
}