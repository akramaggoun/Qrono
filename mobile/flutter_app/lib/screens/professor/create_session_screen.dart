import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/session_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import 'show_qr_screen.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionProvider>(context, listen: false).fetchLabsAndGroups();
    });
  }

  String? _selectedLabId;
  String? _selectedGroupId;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 2);
  bool _isRecurring = false;
  final Map<String, bool> _days = {
    'Mon': false, 'Tue': false, 'Wed': false,
    'Thu': false, 'Fri': false, 'Sat': false,
  };

  // IHM : progression en étapes pour réduire la charge cognitive
  int _currentStep = 0;

  @override
  void dispose() {
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLabId == null || _selectedGroupId == null) {
        _showError('Please select a laboratory and a group.');
        return;
      }
      
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      final startFull = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
      final endFull   = DateTime(_endDate.year,   _endDate.month,   _endDate.day,   _endTime.hour,   _endTime.minute);
      final selectedDays = _days.entries.where((e) => e.value).map((e) => e.key).toList();

      final sessionData = {
        'course_name': _courseController.text,
        'labId': _selectedLabId!,
        'groupId': _selectedGroupId!,
        'start_time': startFull.toIso8601String(),
        'end_time': endFull.toIso8601String(),
        'is_recurring': _isRecurring,
        if (_isRecurring) 'recurrence': {'days': selectedDays},
      };

      final session = await sessionProvider.createSession(sessionData); // UML Steps 3-5

      if (session != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ShowQrScreen(session: session)));
      } else if (mounted) {
        _showError(sessionProvider.errorMessage ?? 'Error creating session.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.info_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Session', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Fill in the details below', style: TextStyle(fontSize: 11, color: AppColors.grayText)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (step) => setState(() => _currentStep = step),
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _submitForm();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: Provider.of<SessionProvider>(context).isLoading ? null : details.onStepContinue,
                      child: Provider.of<SessionProvider>(context).isLoading 
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_currentStep == 2 ? '🚀 GENERATE QR CODE' : 'Next →',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            // ─── ÉTAPE 1: Lieu & Groupe ───
            Step(
              title: const Text('Location & Group', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Lab and group involved'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Consumer<SessionProvider>(
                builder: (context, sessionProvider, child) {
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedLabId,
                        decoration: const InputDecoration(
                          labelText: 'Laboratory',
                          prefixIcon: Icon(Icons.science_outlined, color: AppColors.primaryTeal),
                        ),
                        items: sessionProvider.laboratories.map((lab) =>
                            DropdownMenuItem(value: lab.id, child: Text(lab.name))).toList(),
                        onChanged: (val) => setState(() => _selectedLabId = val),
                        validator: (val) => val == null ? 'Please select a laboratory' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGroupId,
                        decoration: const InputDecoration(
                          labelText: 'Group / Specialty',
                          prefixIcon: Icon(Icons.groups_outlined, color: AppColors.primaryTeal),
                        ),
                        items: sessionProvider.groups.map((g) =>
                            DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                        onChanged: (val) => setState(() => _selectedGroupId = val),
                        validator: (val) => val == null ? 'Please select a group' : null,
                      ),
                    ],
                  );
                },
              ),
            ),

            // ─── ÉTAPE 2: Subject & Schedule ───
            Step(
              title: const Text('Subject & Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Course name and time slot'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _courseController,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name',
                      hintText: 'Ex: Algorithms 2',
                      prefixIcon: Icon(Icons.book_outlined, color: AppColors.primaryTeal),
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter the course name' : null,
                  ),
                  const SizedBox(height: 20),
                  // IHM: Groupement visuel début/fin dans des blocs distincts
                  _buildTimeBlock('Session Start', _startDate, _startTime, true),
                  const SizedBox(height: 14),
                  _buildTimeBlock('Session End', _endDate, _endTime, false),
                ],
              ),
            ),

            // ─── ÉTAPE 3: Recurrence ───
            Step(
              title: const Text('Recurrence', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Single or repeating session'),
              isActive: _currentStep >= 2,
              state: StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IHM : SwitchListTile avec description — compréhension sans effort
                  SwitchListTile(
                    value: _isRecurring,
                    onChanged: (val) => setState(() => _isRecurring = val),
                    activeColor: AppColors.primaryTeal,
                    title: const Text('Recurring Session', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Repeat automatically every week'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 14),
                    const Text('Repeat on:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                    const SizedBox(height: 10),
                    // IHM: chips compactes et visuellement distinctes
                    Wrap(
                      spacing: 8,
                      children: _days.keys.map((day) => FilterChip(
                        label: Text(day, style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _days[day]! ? Colors.white : Colors.black54,
                        )),
                        selected: _days[day]!,
                        selectedColor: AppColors.primaryTeal,
                        checkmarkColor: Colors.white,
                        backgroundColor: AppColors.cardColor,
                        side: BorderSide(color: _days[day]! ? AppColors.primaryTeal : AppColors.borderColor),
                        onSelected: (v) => setState(() => _days[day] = v),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBlock(String label, DateTime date, TimeOfDay time, bool isStart) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(fontSize: 13)),
                  onPressed: () => _selectDate(isStart),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(time.format(context), style: const TextStyle(fontSize: 13)),
                  onPressed: () => _selectTime(isStart),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
