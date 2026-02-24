import 'package:flutter/material.dart';

class LoginField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  // ignore: use_super_parameters
  const LoginField({
    Key? key,
    required this.hintText,
    required this.controller,
  }) : super(key: key);

  bool isFieldPassword(String text) {
    if (text == "Passwort") {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400,
      ),
      child: TextFormField(
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        cursorColor: Theme.of(context).primaryColor,
        controller: controller,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(27),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 1, // Reduced width for cleaner look
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          hintText: hintText,
          hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5)),
        ),
        obscureText: isFieldPassword(hintText),
      ),
    );
  }
}
