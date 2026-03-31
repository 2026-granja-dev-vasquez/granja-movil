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
  final TextEditingController _cartonsController = TextEditingController(text: '0');
  final TextEditingController _unitsController = TextEditingController(text: '0');
  int _cartons = 0;
  int _units = 0;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _cartonsController.dispose();
    _unitsController.dispose();
    super.dispose();
  }



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
      if (mounted) {
        context.read<ProductionProvider>().fetchSpecificDate(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchProvider = context.watch<BatchProvider>();

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
                onChanged: (val) {
                  setState(() => _selectedBatchId = val);
                },
                validator: (val) => val == null ? 'Selecciona un lote' : null,
              ),
              if (_selectedBatchId != null)
                CollectionDashboard(
                  batchId: _selectedBatchId!,
                  date: _selectedDate,
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
                      controller: _cartonsController,
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
                      controller: _unitsController,
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
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
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
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final totalRaw = (_cartons * 30) + _units;
    if (totalRaw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes poner aunque sea un huevo')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final model = BatchCollectionModel(
      batchId: _selectedBatchId!,
      quantity: totalRaw,
      date: _selectedDate,
    );

    final success = await context.read<ProductionProvider>().addBatchCollection(
      model,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recolecta guardada correctamente')),
      );
      Navigator.pop(context);
    } else {
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

class CollectionDashboard extends StatelessWidget {
  final int batchId;
  final DateTime date;

  const CollectionDashboard({
    super.key,
    required this.batchId,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Sincronizando datos...",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Filtrar colecciones por lote y fecha
        final collections = provider.batchCollections
            .where((c) =>
                c.batchId == batchId &&
                DateFormat('yyyy-MM-dd').format(c.date) ==
                    DateFormat('yyyy-MM-dd').format(date))
            .toList();

        // Ordenar por hora (ascendente: del más viejo al más nuevo)
        collections.sort((a, b) => a.date.compareTo(b.date));

        if (collections.isEmpty) return const SizedBox.shrink();

        final totalUnits =
            collections.fold(0, (sum, c) => sum + c.quantity);
        final totalCartons = totalUnits ~/ 30;
        final leftovers = totalUnits % 30;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.indigo.shade100),
          ),
          color: Colors.indigo.shade50.withOpacity(0.3),
          margin: const EdgeInsets.only(top: 16),
          child: ExpansionTile(
            shape: const Border(), // Quita la línea de expansión por defecto
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade100,
              child: const Icon(Icons.egg, color: Colors.indigo, size: 20),
            ),
            title: const Text(
              "Resumen de Recolección",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.indigo,
              ),
            ),
            subtitle: Text(
              "$totalCartons cartones y $leftovers huevos hoy",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            children: [
              const Divider(height: 1),
              ...collections.map((item) {
                final c = item.quantity ~/ 30;
                final u = item.quantity % 30;
                final timeStr = DateFormat('hh:mm a').format(item.date);
                
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.history, size: 16, color: Colors.grey),
                  title: Text(
                    "$c cartones y $u huevos",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text("Hora: $timeStr"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _confirmDelete(context, provider, item),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProductionProvider provider, BatchCollectionModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar registro?'),
        content: const Text('Esta acción quitará estos huevos del total recolectado en este lote.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final success = await provider.deleteBatchCollection(item.id!, date: dateStr);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Registro eliminado' : 'Error al eliminar')),
        );
      }
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
