import 'package:flutter/material.dart';

class PartnerSalesPage extends StatelessWidget {
  const PartnerSalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Penjualan')),
      body: const Center(
        child: Text(
          'Coming Soon',
          style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}
