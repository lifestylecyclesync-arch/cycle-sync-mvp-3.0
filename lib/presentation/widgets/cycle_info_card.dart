import 'package:flutter/material.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';

/// Cycle Info Card Component
/// Displays cycle information with phase color accent bar
class CycleInfoCard extends StatelessWidget {
  /// Card title (e.g., "Menstrual Phase")
  final String title;

  /// Card subtitle (e.g., "Day 1 of 5")
  final String? subtitle;

  /// Card description/body text
  final String description;

  /// Accent color (typically phase color)
  final Color accentColor;

  /// Optional icon
  final IconData? icon;

  /// Optional action button label
  final String? actionLabel;

  /// Optional action button callback
  final VoidCallback? onAction;

  const CycleInfoCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.description,
    required this.accentColor,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Accent bar (left side)
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMedium),
                bottomLeft: Radius.circular(AppSpacing.radiusMedium),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with optional icon
                  Row(
                    children: [
                      if (icon != null)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          child: Icon(
                            icon,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.subtitle1.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Subtitle if provided
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        subtitle!,
                        style: AppTypography.caption.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Description
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      description,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  // Action button if provided
                  if (actionLabel != null && onAction != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: onAction,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: accentColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSmall,
                              ),
                            ),
                          ),
                          child: Text(
                            actionLabel!,
                            style: AppTypography.buttonSmall.copyWith(
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
