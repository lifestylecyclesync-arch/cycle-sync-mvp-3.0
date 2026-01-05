import 'package:flutter/material.dart';

class CycleDataInputScreen extends StatefulWidget {
  const CycleDataInputScreen({super.key});

  @override
  State<CycleDataInputScreen> createState() => _CycleDataInputScreenState();
}

class _CycleDataInputScreenState extends State<CycleDataInputScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _cycleLengthController;
  late TextEditingController _menstrualLengthController;

  // State
  DateTime? _selectedDate;
  bool _showMenstrualWarning = false;

  @override
  void initState() {
    super.initState();
    _cycleLengthController = TextEditingController(text: '28');
    _menstrualLengthController = TextEditingController(text: '5');
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _cycleLengthController.dispose();
    _menstrualLengthController.dispose();
    super.dispose();
  }

  void _onMenstrualLengthChanged(String value) {
    if (value.isNotEmpty) {
      final length = int.tryParse(value) ?? 0;
      setState(() {
        _showMenstrualWarning = length > 10;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  String? _validateCycleLength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Cycle length is required';
    }
    final length = int.tryParse(value);
    if (length == null) {
      return 'Please enter a valid number';
    }
    if (length < 21 || length > 35) {
      return 'Cycle length must be between 21 and 35 days';
    }
    return null;
  }

  String? _validateMenstrualLength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Menstrual length is required';
    }
    final length = int.tryParse(value);
    if (length == null) {
      return 'Please enter a valid number';
    }
    if (length < 2 || length > 35) {
      return 'Menstrual length must be between 2 and 35 days';
    }
    return null;
  }

  void _handleSave() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      // TODO: Save to UserProfile
      // The data is ready to be saved:
      // - cycleLength: _cycleLengthController.text
      // - menstrualLength: _menstrualLengthController.text
      // - lastPeriodDate: _selectedDate

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cycle data saved successfully!')),
      );
      // Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cycle Information'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade50,
        foregroundColor: Colors.deepPurple.shade800,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Introduction text
                Text(
                  'Tell us about your cycle',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.deepPurple.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This information helps us provide personalized insights.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.deepPurple.shade600,
                      ),
                ),
                const SizedBox(height: 32),

                // Cycle Length Field
                Text(
                  'Cycle Length (days)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.deepPurple.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cycleLengthController,
                  keyboardType: TextInputType.number,
                  validator: _validateCycleLength,
                  decoration: InputDecoration(
                    hintText: '28',
                    helperText: 'Typical range: 21–35 days',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.deepPurple.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.deepPurple.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.deepPurple,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 24),

                // Menstrual Length Field
                Text(
                  'Menstrual Length (days)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.deepPurple.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _menstrualLengthController,
                  keyboardType: TextInputType.number,
                  onChanged: _onMenstrualLengthChanged,
                  validator: _validateMenstrualLength,
                  decoration: InputDecoration(
                    hintText: '5',
                    helperText: 'Typical range: 2–10 days',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.deepPurple.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.deepPurple.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.deepPurple,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),

                // Warning for menstrual length > 10
                if (_showMenstrualWarning) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Most cycles range between 2–10 days. If your period is consistently longer, please consult a healthcare provider.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.shade700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Last Period Date Field
                Text(
                  'First Date of Last Period',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.deepPurple.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.deepPurple.shade300,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: Colors.deepPurple.shade400,
                      ),
                    ),
                    child: Text(
                      _selectedDate != null
                          ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                          : 'Select a date',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _selectedDate != null
                                ? Colors.deepPurple.shade800
                                : Colors.grey.shade600,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save & Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
