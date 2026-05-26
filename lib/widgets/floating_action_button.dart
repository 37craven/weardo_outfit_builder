import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFloatingActionButton extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final VoidCallback? onPressed;

  const AppFloatingActionButton({
    super.key,
    this.icon,
    this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.black, width: 1),
          bottom: BorderSide(color: Colors.black, width: 1),
          left: BorderSide(color: Colors.black, width: 1),
          right: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: IconButton(
        icon: text != null
            ? Text(
                text!,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
