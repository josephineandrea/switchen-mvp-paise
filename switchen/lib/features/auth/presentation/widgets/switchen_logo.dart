import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class SwitchenLogo extends StatelessWidget {
  final bool small;
  const SwitchenLogo({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 40.0 : 64.0;
    final fontSize = small ? 20.0 : 28.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(small ? 12 : 18),
          ),
          child: Icon(
            Icons.swap_horiz_rounded,
            color: Colors.white,
            size: size * 0.6,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppStrings.appName,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ).createShader(const Rect.fromLTWH(0, 0, 140, 70)),
          ),
        ),
      ],
    );
  }
}
