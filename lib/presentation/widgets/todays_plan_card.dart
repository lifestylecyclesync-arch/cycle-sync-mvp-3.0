import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/repositories_provider.dart';

enum LifestyleType { fitness, diet, fasting }

typedef ItemCallback = Future<void> Function(String item);

/// Reusable Today's Plan display widget for Fitness, Diet, and Fasting screens
/// Displays selected items (workouts, recipes, fasting) for the selected date
/// Note: The mode/selection button is kept in the parent screen for flexibility with modals
class TodaysPlanCard extends ConsumerWidget {
  final DateTime selectedDate;
  final String lifestyleLabel; // "Fitness", "Diet", "Fasting"
  final String selectedItemsKey; // 'selected_workouts', 'selected_recipes', etc.
  final LifestyleType type;
  final String itemDisplayLabel; // "Tap 'Moderate' to add workouts", etc.
  final ItemCallback onEditItem;
  final ItemCallback onSwapItem;
  final ItemCallback onLogItem;
  final ItemCallback onRemoveItem;
  final Function(BuildContext, String itemName)? onSwapPressed; // Optional callback for swap modal

  const TodaysPlanCard({
    required this.selectedDate,
    required this.lifestyleLabel,
    required this.selectedItemsKey,
    required this.type,
    required this.itemDisplayLabel,
    required this.onEditItem,
    required this.onSwapItem,
    required this.onLogItem,
    required this.onRemoveItem,
    this.onSwapPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(dailySelectionsProvider(selectedDate)).when(
      data: (selections) {
        final selectedItemsJson = selections?[selectedItemsKey] as String?;
        List<String> selectedItems = [];

        if (selectedItemsJson != null && selectedItemsJson.isNotEmpty) {
          try {
            selectedItems = List<String>.from(jsonDecode(selectedItemsJson) as List);
          } catch (e) {
            print('[Error] Failed to parse items: $e');
          }
        }

        if (selectedItems.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Text(
                        itemDisplayLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Plan:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: AppConstants.spacingSm),
            ...selectedItems.map((item) => Padding(
              padding: EdgeInsets.only(
                bottom: AppConstants.spacingSm,
                left: AppConstants.spacingMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingSm),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit button
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () async {
                          await onEditItem(item);
                        },
                        tooltip: 'Edit ${lifestyleLabel.toLowerCase()}',
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      // Swap button
                      IconButton(
                        icon: Icon(
                          Icons.swap_horiz,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () async {
                          await onSwapItem(item);
                        },
                        tooltip: 'Swap ${lifestyleLabel.toLowerCase()}',
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      // Log button
                      IconButton(
                        icon: Icon(
                          Icons.check_circle_outline,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await onLogItem(item);
                        },
                        tooltip: 'Log ${lifestyleLabel.toLowerCase()}',
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      // Delete button
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await onRemoveItem(item);
                        },
                        tooltip: 'Remove ${lifestyleLabel.toLowerCase()}',
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ],
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
        child: SizedBox(
          height: 40,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
            ),
          ),
        ),
      ),
      error: (_, __) => Padding(
        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
        child: Text(
          'Error loading ${lifestyleLabel.toLowerCase()}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.red.shade400,
          ),
        ),
      ),
    );
  }
}

