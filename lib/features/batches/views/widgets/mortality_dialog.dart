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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BatchProvider>();

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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: provider.isLoading ? null : _submit,
          child: provider.isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Registrar'),
        ),
      ],
    );
  }

  void _submit() async {
    final qty = int.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) return;

    final success = await context.read<BatchProvider>().registerMortality(
      widget.batchId,
      qty,
      _selectedDate,
      _reasonController.text.isEmpty ? null : _reasonController.text,
    );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}
