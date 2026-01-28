import 'package:flutter/material.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';

/// Reusable day names header for calendar
class DayNamesHeader extends StatelessWidget {
  const DayNamesHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.5,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 7,
        itemBuilder: (context, index) {
          return Center(
            child: Text(
              dayNames[index],
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          );
        },
      ),
    );
  }
}
