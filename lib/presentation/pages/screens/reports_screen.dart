import 'package:flutter/material.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';

/// Reports Screen
/// View analytics and insights about your cycle and health
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen title
          Text(
            'Reports',
            style: AppTypography.header1,
          ),
          SizedBox(height: AppSpacing.xl),

          // Placeholder content
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: AppColors.mint.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: AppColors.mint,
                ),
                SizedBox(height: AppSpacing.xl),
                Text(
                  'Reports Screen',
                  style: AppTypography.header2,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'View analytics and insights about your cycle',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
