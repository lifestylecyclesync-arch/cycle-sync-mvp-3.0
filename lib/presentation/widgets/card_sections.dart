import 'package:flutter/material.dart';

/// Base reusable Card wrapper for planner sections
/// 
/// Encapsulates Material Design Card styling with consistent elevation,
/// border radius, and padding. Use this for consistent section styling
/// throughout the app without deep nesting.
/// 
/// Example:
/// ```dart
/// PlannerCard(
///   child: Column(
///     children: [/* content */],
///   ),
/// )
/// ```
class PlannerCard extends StatelessWidget {
  final Widget child;
  final double elevation;
  final double borderRadius;
  final EdgeInsets padding;

  const PlannerCard({
    Key? key,
    required this.child,
    this.elevation = 2,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Reusable Card wrapper for Diet section
/// 
/// Specialized card for diet tracking with identical styling to PlannerCard.
/// Kept separate for potential future customizations specific to diet content.
class DietCard extends StatelessWidget {
  final Widget child;
  final double elevation;
  final double borderRadius;
  final EdgeInsets padding;

  const DietCard({
    Key? key,
    required this.child,
    this.elevation = 2,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Reusable Card wrapper for Fasting section
/// 
/// Specialized card for fasting tracking with identical styling to PlannerCard.
/// Kept separate for potential future customizations specific to fasting content.
class FastingCard extends StatelessWidget {
  final Widget child;
  final double elevation;
  final double borderRadius;
  final EdgeInsets padding;

  const FastingCard({
    Key? key,
    required this.child,
    this.elevation = 2,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
