import 'package:flutter/material.dart';
import 'dart:math' as math;

class SwitchenAnimatedLogo extends StatefulWidget {
  final double size;
  final bool isTransition;
  final bool isStatic;

  const SwitchenAnimatedLogo({
    super.key,
    this.size = 180,
    this.isTransition = false,
    this.isStatic = false,
  });

  @override
  State<SwitchenAnimatedLogo> createState() => _SwitchenAnimatedLogoState();
}

class _SwitchenAnimatedLogoState extends State<SwitchenAnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    if (!widget.isStatic) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: SwitchenLogoPainter(
            animation: _controller,
            isTransition: widget.isTransition ? 1.0 : 0.0,
          ),
        );
      },
    );
  }
}

class SwitchenLogoPainter extends CustomPainter {
  final Animation<double> animation;
  final double isTransition;

  SwitchenLogoPainter({required this.animation, required this.isTransition});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Premium Colors based on Switchen Brand
    final primaryGreen = const Color(0xFF00615F); // Dark Teal/Green from Splash
    final accentGreen = const Color(0xFF4CAF50);
    
    // 1. Draw Outer Triangle (Recycling Loop)
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Use a gradient for the triangle
    paint.shader = SweepGradient(
      colors: [
        primaryGreen,
        accentGreen,
        primaryGreen.withOpacity(0.8),
        primaryGreen,
      ],
      transform: GradientRotation(animation.value * 2 * math.pi),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final path = Path();
    final angle = 2 * math.pi / 3;
    
    // Draw rounded triangle
    for (int i = 0; i < 3; i++) {
      final currentAngle = i * angle - math.pi / 2;
      final x = center.dx + radius * math.cos(currentAngle);
      final y = center.dy + radius * math.sin(currentAngle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // 2. Draw Rotating Utensils
    final progress = animation.value;
    final utensils = ['🥄', '🍴', '🥗']; // Spoon, Fork, Salad (Food)
    
    for (int i = 0; i < 3; i++) {
      final itemProgress = (progress + i / 3) % 1.0;
      // Start position at the corners of the triangle or along the edges
      final itemAngle = itemProgress * 2 * math.pi - math.pi / 2;

      final dist = radius * (0.6 + 0.1 * math.sin(progress * 2 * math.pi));
      final x = center.dx + dist * math.cos(itemAngle);
      final y = center.dy + dist * math.sin(itemAngle);

      final scale = 1.0 - isTransition;
      if (scale <= 0) continue;

      final textPainter = TextPainter(
        text: TextSpan(
          text: utensils[i],
          style: TextStyle(
            fontSize: (size.width * 0.25) * scale,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Rotate the utensil based on its position
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(itemAngle + math.pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // 3. Draw Breathing Center Core
    final breath = 1.0 + 0.1 * math.sin(progress * 2 * math.pi * 2);
    final corePaint = Paint()
      ..color = Colors.white
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * breath);
    
    canvas.drawCircle(center, (size.width * 0.1) * breath, corePaint);
    canvas.drawCircle(center, (size.width * 0.08) * breath, Paint()..color = primaryGreen.withOpacity(0.2));
  }

  @override
  bool shouldRepaint(covariant SwitchenLogoPainter oldDelegate) => true;
}
