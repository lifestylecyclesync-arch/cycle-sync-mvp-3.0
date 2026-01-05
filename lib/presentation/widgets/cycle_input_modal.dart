import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/user_profile_provider.dart';

class CycleInputModal extends ConsumerStatefulWidget {
  final int cycleLength;
  final int menstrualLength;
  final DateTime lastPeriodDate;
  final int lutealPhaseLength;

  const CycleInputModal({
    super.key,
    required this.cycleLength,
    required this.menstrualLength,
    required this.lastPeriodDate,
    required this.lutealPhaseLength,
  });

  @override
  ConsumerState<CycleInputModal> createState() => _CycleInputModalState();
}

class _CycleInputModalState extends ConsumerState<CycleInputModal> {
  late int _cycleLength;
  late int _menstrualLength;
  late DateTime _lastPeriodDate;
  late int _lutealPhaseLength;

  @override
  void initState() {
    super.initState();
    _cycleLength = widget.cycleLength;
    _menstrualLength = widget.menstrualLength;
    _lastPeriodDate = widget.lastPeriodDate;
    _lutealPhaseLength = widget.lutealPhaseLength;
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
      final prefs = await SharedPreferences.getInstance();
      
      // Save to SharedPreferences
      await prefs.setInt('cycleLength', _cycleLength);
      await prefs.setInt('menstrualLength', _menstrualLength);
      await prefs.setString('lastPeriodDate', _lastPeriodDate.toIso8601String());
      await prefs.setInt('lutealPhaseLength', _lutealPhaseLength);

      // Invalidate the userProfileProvider to trigger recalculation
      ref.invalidate(userProfileProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cycle inputs updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
              // Title
              Text(
                'Update cycle inputs',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Cycle Length
              _buildNumberField(
                label: 'Cycle length (days)',
                value: _cycleLength,
                minValue: 21,
                maxValue: 35,
                onChanged: (value) => setState(() => _cycleLength = value),
              ),
              const SizedBox(height: 16),

              // Menstrual Length
              _buildNumberField(
                label: 'Menstrual length (days)',
                value: _menstrualLength,
                minValue: 2,
                maxValue: 10,
                onChanged: (value) => setState(() => _menstrualLength = value),
              ),
              const SizedBox(height: 16),

              // Last Period Date
              _buildDateField(),
              const SizedBox(height: 16),

              // Luteal Phase Length
              _buildNumberField(
                label: 'Luteal phase length (days)',
                value: _lutealPhaseLength,
                minValue: 10,
                maxValue: 16,
                onChanged: (value) => setState(() => _lutealPhaseLength = value),
              ),
              const SizedBox(height: 32),

              // Action Buttons
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
                onPressed: value > minValue
                    ? () => onChanged(value - 1)
                    : null,
              ),
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: value < maxValue
                    ? () => onChanged(value + 1)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
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
