import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/onboarding_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingsSection(
                    context: context,
                    title: 'App',
                    items: [
                      _SettingsItem(
                        icon: Icons.notifications,
                        label: 'Notifications',
                        onTap: () => _showComingSoonSnackBar(context),
                      ),
                      _SettingsItem(
                        icon: Icons.language,
                        label: 'Language',
                        onTap: () => _showComingSoonSnackBar(context),
                      ),
                      _SettingsItem(
                        icon: Icons.play_circle,
                        label: 'Video tutorial',
                        onTap: () => _showComingSoonSnackBar(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSettingsSection(
                    context: context,
                    title: 'Support',
                    items: [
                      _SettingsItem(
                        icon: Icons.help,
                        label: 'Help & FAQ',
                        onTap: () => _showComingSoonSnackBar(context),
                      ),
                      _SettingsItem(
                        icon: Icons.shopping_cart,
                        label: 'Remove ads',
                        onTap: () => _showComingSoonSnackBar(context),
                      ),
                      _SettingsItem(
                        icon: Icons.lightbulb,
                        label: 'Request a new feature',
                        onTap: () => _showComingSoonSnackBar(context),
                      ),
                      _SettingsItem(
                        icon: Icons.star,
                        label: 'Rate us',
                        onTap: () => _showComingSoonSnackBar(context),
                      ),
                      _SettingsItem(
                        icon: Icons.share,
                        label: 'Share with friends',
                        onTap: () => _showComingSoonSnackBar(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSettingsSection(
                    context: context,
                    title: 'Legal',
                    items: [
                      _SettingsItem(
                        icon: Icons.privacy_tip,
                        label: 'Privacy & data (GDPR)',
                        onTap: () => _showComingSoonSnackBar(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Destructive action
                  _buildSettingsSection(
                    context: context,
                    title: 'Danger Zone',
                    items: [
                      _SettingsItem(
                        icon: Icons.delete,
                        label: 'Delete all data',
                        onTap: () => _showDeleteDataConfirmation(context, ref),
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required BuildContext context,
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Column(
            children: List.generate(
              items.length,
              (index) {
                final item = items[index];
                return Column(
                  children: [
                    GestureDetector(
                      onTap: item.onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMd,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: item.isDestructive
                                  ? Colors.red
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  color: item.isDestructive
                                      ? Colors.red
                                      : Colors.black,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index < items.length - 1)
                      Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showComingSoonSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteDataConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'This will permanently delete all your cycle data, settings, and preferences. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteAllData(context, ref),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all keys
      await prefs.clear();

      // Invalidate onboarding provider to force re-check
      ref.invalidate(hasCompletedOnboardingProvider);

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Close settings page

        // Navigate to onboarding
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/onboarding',
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting data: $e')),
        );
      }
    }
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

