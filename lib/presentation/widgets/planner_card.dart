import 'package:flutter/material.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';

/// Generic Planner Card Component
/// Used for fitness, diet, fasting plan sections
class PlannerCard extends StatelessWidget {
  /// Card header/title
  final String title;

  /// Optional subtitle
  final String? subtitle;

  /// Card header icon
  final IconData? headerIcon;

  /// Card accent color (tab color)
  final Color accentColor;

  /// Body content widget(s)
  final Widget body;

  /// Optional footer text
  final String? footerText;

  /// Optional footer action label
  final String? footerActionLabel;

  /// Optional footer action callback
  final VoidCallback? onFooterAction;

  /// Whether to show empty state
  final bool isEmpty;

  /// Empty state message
  final String? emptyMessage;

  const PlannerCard({
    super.key,
    required this.title,
    this.subtitle,
    this.headerIcon,
    required this.accentColor,
    required this.body,
    this.footerText,
    this.footerActionLabel,
    this.onFooterAction,
    this.isEmpty = false,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            color: accentColor.withValues(alpha: AppColors.opacityLight),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                if (headerIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: Icon(
                      headerIcon,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.subtitle1.copyWith(
                          color: accentColor,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            subtitle!,
                            style: AppTypography.caption.copyWith(
                              color: accentColor.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox,
                    size: 48,
                    color: accentColor.withValues(alpha: 0.3),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    emptyMessage ?? 'No entries yet',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: body,
            ),

          // Footer (if provided)
          if (footerText != null || footerActionLabel != null)
            Container(
              color: AppColors.backgroundPrimary.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (footerText != null)
                    Expanded(
                      child: Text(
                        footerText!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  if (footerActionLabel != null && onFooterAction != null)
                    TextButton(
                      onPressed: onFooterAction,
                      child: Text(
                        footerActionLabel!,
                        style: AppTypography.buttonSmall.copyWith(
                          color: accentColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
