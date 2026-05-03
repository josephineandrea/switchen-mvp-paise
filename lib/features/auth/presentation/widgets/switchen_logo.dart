import 'package:flutter/material.dart';

class SwitchenLogo extends StatelessWidget {
  final bool small;
  const SwitchenLogo({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final double logoHeight = small ? 80.0 : 180.0;

    return Image.asset(
      'assets/images/logo.png',
      height: logoHeight,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.fastfood, size: 50, color: Colors.grey);
      },
    );
  }
}