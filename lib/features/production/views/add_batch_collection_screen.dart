import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/production_model.dart';
import '../providers/production_provider.dart';
import '../../batches/providers/batch_provider.dart';

class AddBatchCollectionScreen extends StatefulWidget {
  const AddBatchCollectionScreen({super.key});

  @override
  State<AddBatchCollectionScreen> createState() =>
      _AddBatchCollectionScreenState();
}

class _AddBatchCollectionScreenState extends State<AddBatchCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedBatchId;
  int _cartons = 0;
  int _units = 0;
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.input,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchProvider = context.watch<BatchProvider>();
    final productionProvider = context.watch<ProductionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Paso 1: Recoger por lotes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AlertBanner(
                message:
                    "Anota cuántos huevos estás trayendo del lote (galera) antes de limpiarlos.",
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              // Selector de Fecha
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Fecha de Recolecta",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            DateFormat('dd / MM / yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, size: 16, color: Colors.blue),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: '¿De qué lote son?',
                ),
                items: batchProvider.activeBatches
                    .map(
                      (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedBatchId = val),
                validator: (val) => val == null ? 'Selecciona un lote' : null,
              ),
              const SizedBox(height: 32),
              const Text(
                '¿Cuántos huevos traes?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Cartones',
                        helperText: 'De 30 huevos',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _cartons = int.tryParse(val) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Huevos Sueltos',
                        helperText: 'Unidades',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _units = int.tryParse(val) ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: productionProvider.isLoading ? null : _submit,
                child: productionProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar lo Traído'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final totalRaw = (_cartons * 30) + _units;
    if (totalRaw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes poner aunque sea un huevo')),
      );
      return;
    }

    final model = BatchCollectionModel(
      batchId: _selectedBatchId!,
      quantity: totalRaw,
      date: _selectedDate,
    );

    final success = await context.read<ProductionProvider>().addBatchCollection(
      model,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recolecta guardada correctamente')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${context.read<ProductionProvider>().errorMessage}',
          ),
        ),
      );
    }
  }
}

class AlertBanner extends StatelessWidget {
  final String message;
  final Color color;
  const AlertBanner({super.key, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
