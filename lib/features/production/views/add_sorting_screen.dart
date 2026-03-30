import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/production_model.dart';
import '../providers/production_provider.dart';
import '../../products/providers/product_provider.dart';

class AddSortingScreen extends StatefulWidget {
  const AddSortingScreen({super.key});

  @override
  State<AddSortingScreen> createState() => _AddSortingScreenState();
}

class _AddSortingScreenState extends State<AddSortingScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedSizeId;
  int _cartons = 0;
  int _units = 0;
  int _globalDamaged = 0;
  DateTime _selectedDate = DateTime.now();
  bool _showBrokenEggs = false;
  bool _isSaving = false;

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
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      if (mounted) {
        context.read<ProductionProvider>().fetchDailyData(
          date: DateFormat('yyyy-MM-dd').format(picked),
        );
      }
    }
  }

  Widget _balanceItem(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final productionProvider = context.watch<ProductionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Paso 2: Limpieza y Clasificación')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: productionProvider.pendingEggs > 0
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: productionProvider.pendingEggs > 0
                        ? Colors.orange.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          productionProvider.pendingEggs > 0
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          color: productionProvider.pendingEggs > 0
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Balance de Hoy",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _balanceItem(
                          "DE AYER",
                          productionProvider.pendingFromYesterday,
                          Colors.purple,
                        ),
                        _balanceItem(
                          "COSECHA HOY",
                          productionProvider.totalRawCount,
                          Colors.blue,
                        ),
                        _balanceItem(
                          "CLASIFICADOS",
                          productionProvider.totalSortedCount -
                              productionProvider.totalDailyDamaged,
                          Colors.green,
                        ),
                        _balanceItem(
                          "POR CLASIFICAR",
                          productionProvider.pendingEggs,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.green),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Fecha de Clasificación",
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
                      const Icon(Icons.edit, size: 16, color: Colors.green),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.red,
                title: const Text(
                  '¿Hay huevos quebrados?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                value: _showBrokenEggs,
                onChanged: (val) => setState(() => _showBrokenEggs = val),
              ),

              if (_showBrokenEggs)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nuevos Huevos Quebrados',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                          if (productionProvider.totalDailyDamaged > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Ya llevas: ${productionProvider.totalDailyDamaged}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'Ej: 5',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.heart_broken,
                            color: Colors.red,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => setState(
                          () => _globalDamaged = int.tryParse(val) ?? 0,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Clasificación por Talla (Buenos)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: '¿Qué tamaño estás guardando?',
                ),
                items: productProvider.sizes
                    .map(
                      (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedSizeId = val),
              ),
              if (_selectedSizeId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    () {
                      final alreadySorted = productionProvider
                          .dailySortedProductions
                          .where((p) => p.productSizeId == _selectedSizeId)
                          .fold(0, (sum, p) => sum + p.usefulQuantity);
                      final cartons = alreadySorted ~/ 30;
                      final units = alreadySorted % 30;
                      return "💡 Ya clasificaste: $cartons cartones y $units hoy.";
                    }(),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                        labelText: 'Sueltos',
                        helperText: 'Unidades',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _units = int.tryParse(val) ?? 0,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar Clasificación'),
              ),

              const SizedBox(height: 48),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Registros de Hoy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),

              if (productionProvider.dailySortedProductions.isEmpty)
                const Center(
                  child: Text(
                    'No has clasificado nada hoy.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: productionProvider.dailySortedProductions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final prod =
                        productionProvider.dailySortedProductions[index];
                    final isDamagedOnly = prod.productSizeId == null;

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isDamagedOnly
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        radius: 14,
                        child: Icon(
                          isDamagedOnly ? Icons.heart_broken : Icons.egg,
                          size: 14,
                          color: isDamagedOnly ? Colors.red : Colors.green,
                        ),
                      ),
                      title: Text(
                        isDamagedOnly
                            ? "Solo Quebrados"
                            : (prod.productSizeName ?? "Talla"),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isDamagedOnly
                            ? "${prod.damagedQuantity} unidades"
                            : "${prod.usefulQuantity ~/ 30} cartones y ${prod.usefulQuantity % 30} huevos",
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _confirmDelete(context, prod),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProductionModel prod,
  ) async {
    bool _isDeleting = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('¿Eliminar registro?'),
          content: const Text(
            'Esto restará los huevos de tu stock actual para corregir el inventario.',
          ),
          actions: [
            TextButton(
              onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isDeleting ? null : () async {
                setState(() => _isDeleting = true);
                final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                final success = await context
                    .read<ProductionProvider>()
                    .deleteSortedProduction(prod.id!, date: dateStr);
                if (context.mounted) {
                  if (success) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() => _isDeleting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${context.read<ProductionProvider>().errorMessage}')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: _isDeleting 
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro eliminado y stock revertido.'),
        ),
      );
    }
  }

  void _submit() async {
    if (_isSaving) return;

    final totalUseful = (_cartons * 30) + _units;

    if (totalUseful <= 0 && _globalDamaged <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes poner alguna cantidad (Buenos o Quebrados)'),
        ),
      );
      return;
    }

    if (totalUseful > 0 && _selectedSizeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el tamaño de los huevos buenos'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final List<ProductionModel> productionList = [];

    if (totalUseful > 0) {
      productionList.add(
        ProductionModel(
          productSizeId: _selectedSizeId,
          usefulQuantity: totalUseful,
          damagedQuantity: 0,
          date: _selectedDate,
        ),
      );
    }

    if (_showBrokenEggs && _globalDamaged > 0) {
      productionList.add(
        ProductionModel(
          productSizeId: null,
          usefulQuantity: 0,
          damagedQuantity: _globalDamaged,
          date: _selectedDate,
        ),
      );
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final success = await context
        .read<ProductionProvider>()
        .addMultipleSortedProductions(productionList, date: dateStr);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro guardado correctamente')),
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
