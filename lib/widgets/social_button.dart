import 'package:flutter/material.dart';

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
        colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurface, BlendMode.srcIn),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 17,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
            vertical: 20,
            horizontal:
                horizontalPadding), // Slightly reduced vertical padding for tighter look
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1, // Reduced width
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
