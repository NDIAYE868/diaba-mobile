import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProductSkeleton extends StatelessWidget {
  const ProductSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2D3240) : const Color(0xFFE8EAED),
      highlightColor: isDark ? const Color(0xFF3D4354) : const Color(0xFFF5F6F8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 10, width: 60, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 12, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(height: 12, width: double.infinity * 0.7, color: Colors.white),
                    const Spacer(),
                    Container(height: 14, width: 80, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 32, color: Colors.white, width: double.infinity),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
