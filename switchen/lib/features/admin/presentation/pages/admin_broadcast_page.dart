import 'package:flutter/material.dart';

class AdminBroadcastPage extends StatelessWidget {
  const AdminBroadcastPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Notifikasi')),
      body: const Center(
        child: Text(
          'Coming Soon',
          style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}
