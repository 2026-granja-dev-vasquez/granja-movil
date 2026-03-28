import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reminder_provider.dart';
import '../../../shared/widgets/loading_button.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _intervalController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _frequency = 'once';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.indigo),
        ),
        child: child!,
      ),
    );
    if (d != null) {
      final TimeOfDay? t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (t != null) {
        setState(() {
          _selectedDate = d;
          _selectedTime = t;
        });
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes seleccionar fecha y hora inicial.')));
      return;
    }

    if (_frequency == 'custom_days') {
      final num = int.tryParse(_intervalController.text);
      if (num == null || num <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un número de días válido.')));
        return;
      }
    }

    setState(() => _isLoading = true);

    final finalDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedTime!.hour, _selectedTime!.minute,
    );

    final data = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'remind_at': finalDateTime.toIso8601String(),
      'frequency': _frequency,
      'interval_days': _frequency == 'custom_days' ? int.parse(_intervalController.text) : null,
    };

    try {
      await context.read<ReminderProvider>().addReminder(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Programar Tarea'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'TÍTULO DE LA TAREA (ej: Vacunación Lote 2)', prefixIcon: Icon(Icons.assignment_turned_in_outlined)),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción / Notas (Opcional)', prefixIcon: Icon(Icons.description_outlined)),
                maxLines: 2,
              ),
              
              const SizedBox(height: 32),
              const Text("FECHA Y HORA DE AVISO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.indigo, size: 30),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDate == null ? 'Elegir Fecha' : DateFormat('EEEE dd MMMM, yyyy').format(_selectedDate!),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            _selectedTime == null ? 'Elegir Hora' : _selectedTime!.format(context),
                            style: const TextStyle(color: Colors.indigo, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Text("REPETICIÓN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 1.2)),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.autorenew),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'once', child: Text('Una Sola Vez')),
                  DropdownMenuItem(value: 'custom_days', child: Text('Cada X Días (Ej: Vacunas)')),
                  DropdownMenuItem(value: 'monthly', child: Text('Mensual (Mismo día del mes)')),
                ],
                onChanged: (val) => setState(() => _frequency = val!),
              ),

              if (_frequency == 'custom_days') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _intervalController,
                  decoration: InputDecoration(
                    labelText: 'Número de días (ej: 45)',
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (_frequency == 'custom_days' && (val == null || val.isEmpty)) return 'Requerido';
                    return null;
                  },
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, left: 4),
                  child: Text('Al marcar la tarea como Hecho, se programará la siguiente automáticamente sumando estos días.', style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                ),
              ],

              const SizedBox(height: 48),
              LoadingButton(
                text: 'PROGRAMAR TAREA',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
