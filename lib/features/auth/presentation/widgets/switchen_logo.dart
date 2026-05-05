import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SwitchenLogo extends StatelessWidget {
  final bool small;
  const SwitchenLogo({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final double logoHeight = small ? 72.0 : 160.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: logoHeight,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback: icon default jika gambar gagal load
            return Container(
              width: logoHeight,
              height: logoHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.recycling,
                size: logoHeight * 0.55,
                color: Colors.white,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'switchen',
          style: GoogleFonts.outfit(
            fontSize: small ? 18 : 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2E7D32),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}