import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/domain/entities/user_profile.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/user_profile_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/repositories_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/settings_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late TextEditingController _nameController;
  // Local state to track optimistic UI updates for lifestyle areas
  Map<String, bool> _optimisticLifestyleState = {};
  // Track pending changes for debouncing - maps area name to new state (true=add, false=remove)
  Map<String, bool> _pendingLifestyleChanges = {};
  // Debounce timer for batching multiple rapid changes
  Timer? _debounceTimer;
  // Track confirmed areas that have been successfully saved to server
  // This is the source of truth for computing the next batch
  late Set<String> _confirmedAreas;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _confirmedAreas = {};
  }

  @override
  void dispose() {
    _nameController.dispose();
    // Cancel debounce timer to prevent memory leaks
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _editName(BuildContext context, String currentName) {
    _nameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Name is saved via Supabase
              ref.invalidate(userProfileProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final lifestyleAreasAsync = ref.watch(lifestyleAreasProvider);
    // Watch cached provider for instant data
    final cachedLifestyleAreas = ref.watch(cachedLifestyleAreasProvider);

    return Scaffold(
      body: userProfileAsync.when(
        data: (profile) {
          return lifestyleAreasAsync.when(
            data: (lifestyleAreas) {
              // Initialize confirmed areas from the latest data
              _confirmedAreas = lifestyleAreas.toSet();
              // Use async data, but show cached data first
              return _buildProfileUI(context, profile, lifestyleAreas);
            },
            loading: () {
              // Show cached data while loading
              if (cachedLifestyleAreas.isNotEmpty) {
                // Initialize from cached data if we have it
                _confirmedAreas = cachedLifestyleAreas.toSet();
                return _buildProfileUI(context, userProfileAsync.value, cachedLifestyleAreas);
              }
              return const Center(child: CircularProgressIndicator());
            },
            error: (error, stack) => _buildErrorUI(error),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorUI(error),
      ),
    );
  }

  Widget _buildErrorUI(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $error'),
          const SizedBox(height: AppConstants.spacingMd),
          ElevatedButton(
            onPressed: () => ref.invalidate(userProfileProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileUI(
    BuildContext context, 
    UserProfile? profile,
    List<String> lifestyleAreas,
  ) {
    if (profile == null) {
      return _buildErrorUI('Profile not found');
    }

    return CustomScrollView(
      slivers: [
        // AppBar with Settings Icon
        SliverAppBar(
          title: const Text('Profile'),
          floating: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture & Name Section
                _buildIdentitySection(context, profile),
                const SizedBox(height: 32),

                // My Cycle Section
                _buildCycleSection(context, profile),
                const SizedBox(height: 32),

                // My Lifestyle Sync Section
                _buildLifestyleSection(context, profile, lifestyleAreas),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentitySection(BuildContext context, UserProfile profile) {
    return Column(
      children: [
        // Avatar - Placeholder circle or user image
        GestureDetector(
          onTap: () => _showImagePickerOptions(context),
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade300,
                ),
                child: FutureBuilder<String?>(
                  future: _getAvatarPath(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final imagePath = snapshot.data!;
                      // Check if it's a base64 string or file path
                      if (imagePath.startsWith('data:image') || imagePath.contains(',')) {
                        // It's base64
                        final base64String = imagePath.split(',').last;
                        return ClipOval(
                          child: Image.memory(
                            base64Decode(base64String),
                            fit: BoxFit.cover,
                          ),
                        );
                      } else {
                        // It's a file path
                        return ClipOval(
                          child: Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                    }
                    return const Icon(Icons.person, size: 50);
                  },
                ),
              ),
              // Edit indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Name
        GestureDetector(
          onTap: () => _editName(context, profile.name),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit, size: 18, color: Colors.grey.shade600),
            ],
          ),
        ),
      ],
    );
  }

  // Avatar is now managed through Supabase userProfileProvider
  Future<String?> _getAvatarPath() async {
    // TODO: Avatars will be stored in Supabase storage when implemented
    return null;
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Read file and convert to base64
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64String = base64Encode(bytes);
        
        // Save to Supabase via provider
        await ref.read(updateAvatarProvider(base64String).future);
        
        // Refresh UI
        setState(() {});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildCycleSection(BuildContext context, UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Cycle',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildCycleInfoRow(
          label: 'Cycle length',
          value: '${profile.cycleLength} days',
        ),
        const SizedBox(height: 12),
        _buildCycleInfoRow(
          label: 'Menstrual length',
          value: '${profile.menstrualLength} days',
        ),
        const SizedBox(height: 12),
        _buildCycleInfoRow(
          label: 'Last period start',
          value: '${profile.lastPeriodDate.day}/${profile.lastPeriodDate.month}/${profile.lastPeriodDate.year}',
        ),
        const SizedBox(height: 12),
        _buildCycleInfoRow(
          label: 'Luteal phase length',
          value: '${profile.lutealPhaseLength} days',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showEditCycleModal(context, profile),
            icon: const Icon(Icons.edit),
            label: const Text('Edit cycle inputs'),
          ),
        ),
      ],
    );
  }

  Widget _buildLifestyleSection(BuildContext context, UserProfile profile, List<String> lifestyleAreas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Lifestyle Sync',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Nutrition
        _buildLifestyleChip(
          context,
          label: 'Nutrition',
          isSelected: _optimisticLifestyleState['Nutrition'] ?? lifestyleAreas.contains('Nutrition'),
          onTap: () => _toggleLifestyleArea(profile, 'Nutrition'),
        ),
        const SizedBox(height: 12),

        // Fitness
        _buildLifestyleChip(
          context,
          label: 'Fitness',
          isSelected: _optimisticLifestyleState['Fitness'] ?? lifestyleAreas.contains('Fitness'),
          onTap: () => _toggleLifestyleArea(profile, 'Fitness'),
        ),
        const SizedBox(height: 12),

        // Fasting with preference
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLifestyleChip(
              context,
              label: 'Fasting',
              isSelected: _optimisticLifestyleState['Fasting'] ?? lifestyleAreas.contains('Fasting'),
              onTap: () => _toggleLifestyleArea(profile, 'Fasting'),
            ),
            if ((_optimisticLifestyleState['Fasting'] ?? lifestyleAreas.contains('Fasting'))) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Preference: ${profile.fastingPreference}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showFastingPreferenceModal(context, profile),
                      child: Text(
                        'Change',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCycleInfoRow({
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLifestyleChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLifestyleArea(UserProfile profile, String area) {
    // Get current state - use _confirmedAreas as source of truth (updated after each successful batch save)
    // Fall back to optimistic/pending state if area is being edited now
    final wasSelected = _optimisticLifestyleState[area] 
        ?? _pendingLifestyleChanges[area]
        ?? _confirmedAreas.contains(area);
    
    final newState = !wasSelected;
    print('[ProfilePage] Toggle area: $area from $wasSelected to $newState (confirmed: $_confirmedAreas)');
    
    // Update optimistic UI immediately (checkbox shows checked/unchecked right away)
    setState(() {
      _optimisticLifestyleState[area] = newState;
      // Track this change as pending for batch processing
      _pendingLifestyleChanges[area] = newState;
      print('[ProfilePage] Optimistic state updated, pending changes: $_pendingLifestyleChanges');
    });
    
    // Cancel existing debounce timer to reset the countdown
    _debounceTimer?.cancel();
    
    // Start new debounce timer - batch save all pending changes after 500ms of no new changes
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _batchSaveLifestyleAreas();
    });
  }

  Future<void> _batchSaveLifestyleAreas() async {
    if (_pendingLifestyleChanges.isEmpty) {
      print('[ProfilePage] No pending changes to save');
      return;
    }
    
    // Snapshot the pending changes that we're about to save
    // Any new toggles that arrive while we're saving will create new pending changes
    final pendingSnapshot = Map<String, bool>.from(_pendingLifestyleChanges);
    
    print('[ProfilePage] Batch saving pending changes: $pendingSnapshot');
    print('[ProfilePage] Current confirmed areas: $_confirmedAreas');
    
    // Get the final list of areas that should be selected based on pending changes
    // Use _confirmedAreas as the base (source of truth for what's been saved)
    final newAreas = <String>{..._confirmedAreas};
    
    // Apply all pending changes
    pendingSnapshot.forEach((area, shouldBeSelected) {
      if (shouldBeSelected) {
        newAreas.add(area);
      } else {
        newAreas.remove(area);
      }
    });
    
    try {
      // Batch save all changes in one request
      print('[ProfilePage] Sending batch update: $newAreas');
      await ref.read(updateLifestyleAreasProvider(newAreas.toList()).future);
      print('[ProfilePage] Batch save completed');
      
      // After successful save, refresh providers to get fresh data from cache
      print('[ProfilePage] Refreshing providers after batch save...');
      final refreshedAreas = await ref.refresh(lifestyleAreasProvider.future);
      unawaited(ref.refresh(userProfileProvider.future));
      print('[ProfilePage] Providers refreshed, new areas: $refreshedAreas');
      
      // Transaction complete: clear optimistic state and update confirmed areas
      if (mounted) {
        setState(() {
          // Update confirmed areas with the newly saved state
          _confirmedAreas = newAreas;
          // Only remove the pending changes that we actually processed in this batch
          // Any new toggles that arrived during the save will remain in _pendingLifestyleChanges
          pendingSnapshot.forEach((area, _) {
            _pendingLifestyleChanges.remove(area);
            _optimisticLifestyleState.remove(area);
          });
          print('[ProfilePage] Batch completed. Confirmed areas: $_confirmedAreas, remaining pending: $_pendingLifestyleChanges');
          
          // If there are still pending changes (from new toggles during the save),
          // start a new debounce timer to process them
          if (_pendingLifestyleChanges.isNotEmpty) {
            print('[ProfilePage] New pending changes detected, starting new debounce...');
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 500), () {
              _batchSaveLifestyleAreas();
            });
          }
        });
      }
    } catch (e) {
      print('[ProfilePage] Error saving batch changes: $e');
      // Revert optimistic state for the snapshot we tried to save
      if (mounted) {
        setState(() {
          // Only revert the optimistic state for changes we tried to save
          // Keep any new pending changes that arrived during the failed save
          pendingSnapshot.forEach((area, _) {
            _optimisticLifestyleState.remove(area);
            _pendingLifestyleChanges.remove(area);
          });
          print('[ProfilePage] Optimistic state reverted for failed batch: $pendingSnapshot');
        });
        
        // Show error recovery dialog with retry option
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Failed to Save Changes'),
            content: Text('Could not save ${pendingSnapshot.length} area changes: $e\n\nTry again?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  // Retry the batch save
                  _retryBatchSave(pendingSnapshot);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _retryBatchSave(Map<String, bool> pendingChanges) async {
    // Restore pending changes and retry
    setState(() {
      _pendingLifestyleChanges = pendingChanges;
      for (var entry in pendingChanges.entries) {
        _optimisticLifestyleState[entry.key] = entry.value;
      }
    });
    await _batchSaveLifestyleAreas();
  }

  void _showEditCycleModal(BuildContext context, UserProfile profile) {
    // Uses the same modal from the FAB
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _CycleEditForm(profile: profile, onSaved: () {
          ref.invalidate(userProfileProvider);
          Navigator.pop(context);
        });
      },
    );
  }

  void _showFastingPreferenceModal(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fasting preference'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Beginner'),
              trailing: profile.fastingPreference == 'Beginner'
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () => _saveFastingPreference('Beginner'),
            ),
            ListTile(
              title: const Text('Advanced'),
              trailing: profile.fastingPreference == 'Advanced'
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () => _saveFastingPreference('Advanced'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveFastingPreference(String preference) async {
    // Fasting preference is saved via Supabase
    ref.invalidate(userProfileProvider);
    if (mounted) Navigator.pop(context);
  }
}

class _CycleEditForm extends ConsumerStatefulWidget {
  final UserProfile profile;
  final VoidCallback onSaved;

  const _CycleEditForm({
    required this.profile,
    required this.onSaved,
  });

  @override
  ConsumerState<_CycleEditForm> createState() => _CycleEditFormState();
}

class _CycleEditFormState extends ConsumerState<_CycleEditForm> {
  late int _cycleLength;
  late int _menstrualLength;
  late DateTime _lastPeriodDate;
  late int _lutealPhaseLength;

  @override
  void initState() {
    super.initState();
    _cycleLength = widget.profile.cycleLength;
    _menstrualLength = widget.profile.menstrualLength;
    _lastPeriodDate = widget.profile.lastPeriodDate;
    _lutealPhaseLength = widget.profile.lutealPhaseLength;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _lastPeriodDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    try {
      // Save cycle settings via Supabase
      await ref.read(saveUserProfileProvider(
        (
          name: '',
          cycleLength: _cycleLength,
          menstrualLength: _menstrualLength,
          lutealPhaseLength: _lutealPhaseLength,
          lastPeriodDate: _lastPeriodDate,
          avatarBase64: null,
          fastingPreference: null,
        )
      ).future);

      ref.invalidate(userProfileProvider);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving changes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update cycle inputs',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              _buildNumberField(
                label: 'Cycle length (days)',
                value: _cycleLength,
                minValue: 21,
                maxValue: 35,
                onChanged: (value) => setState(() => _cycleLength = value),
              ),
              const SizedBox(height: 16),

              _buildNumberField(
                label: 'Menstrual length (days)',
                value: _menstrualLength,
                minValue: 2,
                maxValue: 10,
                onChanged: (value) => setState(() => _menstrualLength = value),
              ),
              const SizedBox(height: 16),

              _buildDateField(context),
              const SizedBox(height: 16),

              _buildNumberField(
                label: 'Luteal phase length (days)',
                value: _lutealPhaseLength,
                minValue: 10,
                maxValue: 16,
                onChanged: (value) => setState(() => _lutealPhaseLength = value),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required int minValue,
    required int maxValue,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: value > minValue ? () => onChanged(value - 1) : null,
              ),
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: value < maxValue ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'First date of last period',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_lastPeriodDate.day}/${_lastPeriodDate.month}/${_lastPeriodDate.year}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Icon(Icons.calendar_today, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
