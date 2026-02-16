import 'package:flutter/material.dart';

class UnauthorizedPage extends StatelessWidget {
  const UnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "🚫 Unauthorized Access",
          style: TextStyle(fontSize: 22, color: Colors.red),
        ),
      ),
    );
  }
}
