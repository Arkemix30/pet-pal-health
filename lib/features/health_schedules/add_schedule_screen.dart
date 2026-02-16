import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/local/isar_models.dart';
import 'schedule_provider.dart';

class AddScheduleScreen extends ConsumerStatefulWidget {
  final String petSupabaseId;
  final String? initialType;
  const AddScheduleScreen({
    super.key,
    required this.petSupabaseId,
    this.initialType,
  });

  @override
  ConsumerState<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends ConsumerState<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late String _selectedType;
  String _selectedFrequency = 'one-time';
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 09, minute: 00);

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'vaccine';
  }

  final List<Map<String, dynamic>> _types = [
    {'id': 'vaccine', 'label': 'Vaccine', 'icon': Icons.vaccines},
    {'id': 'medication', 'label': 'Medication', 'icon': Icons.medication},
    {'id': 'deworming', 'label': 'Deworming', 'icon': Icons.bug_report},
    {'id': 'appointment', 'label': 'Vet Visit', 'icon': Icons.local_hospital},
  ];

  final List<String> _frequencies = [
    'one-time',
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final fullDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final schedule = HealthSchedule()
      ..petSupabaseId = widget.petSupabaseId
      ..title = _titleController.text.trim()
      ..type = _selectedType
      ..startDate = fullDateTime
      ..frequency = _selectedFrequency
      ..notes = _notesController.text.trim()
      ..createdAt = DateTime.now();

    await ref.read(scheduleManagementProvider).saveSchedule(schedule);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Schedule Action', style: GoogleFonts.outfit()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What are we scheduling?',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _types.map((type) {
                  final isSelected = _selectedType == type['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type['id']),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            type['icon'],
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type['label'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 32),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration(
                  'Action Title (e.g., Rabies Shot)',
                  Icons.title,
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: _inputDecoration(
                          'Date',
                          Icons.calendar_today,
                        ),
                        child: Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: _inputDecoration('Time', Icons.access_time),
                        child: Text(_startTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                decoration: _inputDecoration('Frequency', Icons.repeat),
                items: _frequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedFrequency = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: _inputDecoration('Notes (Optional)', Icons.notes),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Confirm Schedule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ).animate().scale(delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
    );
  }
}
