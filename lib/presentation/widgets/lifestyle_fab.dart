import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable Floating Action Button for lifestyle screens (Hormonal, Fitness, Diet, Fasting)
/// All have the same appearance but different colors and functionality
class LifestyleFAB extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;
  final double bottom;
  final double right;

  const LifestyleFAB({
    required this.color,
    required this.onPressed,
    this.bottom = 20,
    this.right = 16,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      right: right,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
