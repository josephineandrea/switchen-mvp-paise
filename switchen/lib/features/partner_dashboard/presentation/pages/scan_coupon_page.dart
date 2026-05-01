import 'package:flutter/material.dart';

class ScanCouponPage extends StatelessWidget {
  const ScanCouponPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Kupon')),
      body: const Center(
        child: Text(
          'Coming Soon',
          style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}
