import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 48, this.showText = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'D',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.45,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'DIABA',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: size * 0.3,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ],
    );
  }
}
