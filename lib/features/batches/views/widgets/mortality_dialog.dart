import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/batch_provider.dart';

class MortalityDialog extends StatefulWidget {
  final int batchId;
  const MortalityDialog({super.key, required this.batchId});

  @override
  State<MortalityDialog> createState() => _MortalityDialogState();
}

class _MortalityDialogState extends State<MortalityDialog> {
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: const Text('Registrar Baja/Mortalidad'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Cantidad de aves muertas'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha'),
              subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              iconColor: Colors.orange,
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Registrar'),
        ),
      ],
    );
  }

  void _submit() async {
    if (_isSaving) return;
    
    final qty = int.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) return;

    setState(() => _isSaving = true);
    
    final success = await context.read<BatchProvider>().registerMortality(
      widget.batchId,
      qty,
      _selectedDate,
      _reasonController.text.isEmpty ? null : _reasonController.text,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() => _isSaving = false);
      }
    }
  }
}
