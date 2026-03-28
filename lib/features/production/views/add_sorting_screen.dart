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
  int _globalDamaged = 0; // Registro global de quebrados
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
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      // Recargar datos para la nueva fecha para ver el balance correcto
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
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(
            value.toString(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  bool _showBrokenEggs = false;

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
              // BANNER DE BALANCE MEJORADO (CON QUEBRADOS ACUMULADOS)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: productionProvider.pendingEggs > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: productionProvider.pendingEggs > 0 ? Colors.orange.shade200 : Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          productionProvider.pendingEggs > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                          color: productionProvider.pendingEggs > 0 ? Colors.orange.shade700 : Colors.green.shade700,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Balance de Hoy",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _balanceItem("TRAÍDO", productionProvider.totalRawCount, Colors.blue),
                        _balanceItem("BUENOS", productionProvider.totalSortedCount - productionProvider.totalDailyDamaged, Colors.green),
                        _balanceItem("QUEBRADOS", productionProvider.totalDailyDamaged, Colors.red),
                        _balanceItem("PENDIENTE", productionProvider.pendingEggs, Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Selector de Fecha
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
                          const Text("Fecha de Clasificación", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            DateFormat('dd / MM / yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

              // PREGUNTA DINÁMICA DE QUEBRADOS
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.red,
                title: const Text(
                  '¿Hay huevos quebrados?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                value: _showBrokenEggs,
                onChanged: (val) => setState(() => _showBrokenEggs = val),
              ),
              
              // REGISTRO GLOBAL DE QUEBRADOS (DINÁMICO)
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
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                          ),
                          if (productionProvider.totalDailyDamaged > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                "Ya llevas: ${productionProvider.totalDailyDamaged}",
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                          prefixIcon: Icon(Icons.heart_broken, color: Colors.red),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => setState(() => _globalDamaged = int.tryParse(val) ?? 0),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Si encontraste más quebrados en esta recolecta, anótalos aquí.",
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Clasificación por Talla (Buenos)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: '¿Qué tamaño estás guardando?'),
                items: productProvider.sizes.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (val) => setState(() => _selectedSizeId = val),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Cartones', helperText: 'De 30 huevos'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _cartons = int.tryParse(val) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Sueltos', helperText: 'Unidades'),
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
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: productionProvider.isLoading ? null : _submit,
                child: productionProvider.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Guardar Producción del Día'),
              ),
              const SizedBox(height: 80), // Padding extra para que el botón no quede pegado al fondo
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    final totalUseful = (_cartons * 30) + _units;
    
    if (totalUseful <= 0 && _globalDamaged <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes poner alguna cantidad (Buenos o Quebrados)')));
      return;
    }

    if (totalUseful > 0 && _selectedSizeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona el tamaño de los huevos buenos')));
      return;
    }

    final List<ProductionModel> productionList = [];

    // 1. Agregar los buenos por tamaño (si hay)
    if (totalUseful > 0) {
      productionList.add(ProductionModel(
        productSizeId: _selectedSizeId,
        usefulQuantity: totalUseful,
        damagedQuantity: 0,
        date: _selectedDate,
      ));
    }

    // 2. Agregar los quebrados globales (si hay y el toggle está activo)
    if (_showBrokenEggs && _globalDamaged > 0) {
      productionList.add(ProductionModel(
        productSizeId: null, // Global
        usefulQuantity: 0,
        damagedQuantity: _globalDamaged,
        date: _selectedDate,
      ));
    }

    final success = await context.read<ProductionProvider>().addMultipleSortedProductions(productionList);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro guardado correctamente')));
      Navigator.pop(context);
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${context.read<ProductionProvider>().errorMessage}')));
    }
  }
}
