import 'package:flutter/material.dart';
import 'package:foodconnect/utils/Palette.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final double horizontalPadding;
  final Future<void> Function() onTap;
  // ignore: use_super_parameters
  const SocialButton({
    Key? key,
    required this.iconPath,
    required this.label,
    required this.onTap,
    this.horizontalPadding = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: SvgPicture.asset(
        iconPath,
        width: 25,
        // ignore: deprecated_member_use
        color: Palette.darkIconColor,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Palette.darkTextColor,
          fontSize: 17,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: horizontalPadding),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: Palette.darkBorderColor,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}