import 'package:flutter/material.dart';
import 'package:foodconnect/utils/Palette.dart';

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
        style: TextStyle(color: Colors.white),
        cursorColor: Colors.deepPurple,
        controller: controller,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(27),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Palette.darkBorderColor,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Palette.gradient2,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          hintText: hintText,
        ),
        obscureText: isFieldPassword(hintText),
      ),
    );
  }
}