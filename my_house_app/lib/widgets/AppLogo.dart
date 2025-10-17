import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App title
        const Text(
          'Gethouse',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2.0,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 6,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Subtitle
        const Text(
          'Find Your Dream Home',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        // Decorative line (makes it feel logo-like)
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white70,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}
