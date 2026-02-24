import 'package:flutter/material.dart';

class LoginField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;

  const LoginField({
    super.key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Auto-detect: if hintText contains "Passwort" → obscure by default
    final shouldObscure = obscureText ||
        (hintText.toLowerCase().contains('passwort') && suffixIcon == null);

    return TextFormField(
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 16,
      ),
      cursorColor: theme.primaryColor,
      controller: controller,
      obscureText: shouldObscure,
      keyboardType: keyboardType ??
          (hintText.toLowerCase().contains('mail')
              ? TextInputType.emailAddress
              : TextInputType.text),
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        filled: true,
        fillColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.primaryColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
