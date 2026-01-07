import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';

class DailyCardPage extends ConsumerWidget {
  const DailyCardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // MVP: Simple placeholder for daily insights
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Insights'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Text(
                  'Daily insights feature coming soon!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
