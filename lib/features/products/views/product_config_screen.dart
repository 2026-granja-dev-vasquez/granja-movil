import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product_size_model.dart';

class ProductConfigScreen extends StatefulWidget {
  const ProductConfigScreen({super.key});

  @override
  State<ProductConfigScreen> createState() => _ProductConfigScreenState();
}

class _ProductConfigScreenState extends State<ProductConfigScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchSizes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de Precios')),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.sizes.isEmpty) {
            return const Center(child: Text('No hay productos configurados.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.sizes.length,
            itemBuilder: (context, index) {
              final item = provider.sizes[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueGrey),
                            onPressed: () => _editPrices(context, item),
                          ),
                        ],
                      ),
                      const Divider(),
                      _priceRow('Unidad', item.unitPrice),
                      _priceRow('Cartón (30 uds)', item.cartonPrice),
                      _priceRow('Caja (12 cartones)', item.boxPrice),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSize(context),
        child: const Icon(Icons.add),
        tooltip: 'Añadir tamaño',
      ),
    );
  }

  Widget _priceRow(String label, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text('Q${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _editPrices(BuildContext context, ProductSizeModel item) {
    final unitCol = TextEditingController(text: item.unitPrice.toString());
    final cartonCol = TextEditingController(text: item.cartonPrice.toString());
    final boxCol = TextEditingController(text: item.boxPrice.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Editar Precios - ${item.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _priceField('Precio por Unidad', unitCol, (_) {}),
                _priceField('Precio por Cartón (30 uds)', cartonCol, (_) {}),
                _priceField('Precio por Caja (12 cartones)', boxCol, (_) {}),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    final p = double.tryParse(cartonCol.text.replaceAll(',', '.')) ?? 0;
                    if (p > 0) {
                      setState(() {
                        unitCol.text = (p / 30).toStringAsFixed(2);
                        boxCol.text = (p * 12).toStringAsFixed(2);
                      });
                    }
                  },
                  icon: const Icon(Icons.calculate_outlined, size: 16),
                  label: const Text('Sugerir por proporcionalidad', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final u = double.tryParse(unitCol.text.replaceAll(',', '.')) ?? 0;
                final c = double.tryParse(cartonCol.text.replaceAll(',', '.')) ?? 0;
                final b = double.tryParse(boxCol.text.replaceAll(',', '.')) ?? 0;
                
                final success = await context.read<ProductProvider>().updatePrices(item.id, u, c, b);
                if (mounted) {
                  if (success) {
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${context.read<ProductProvider>().errorMessage}')),
                    );
                  }
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  void _addSize(BuildContext context) {
    final nameCol = TextEditingController();
    final unitCol = TextEditingController();
    final cartonCol = TextEditingController();
    final boxCol = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Añadir Tamaño de Huevo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCol, decoration: const InputDecoration(labelText: 'Nombre (ej: Jumbo)')),
                const SizedBox(height: 16),
                _priceField('Precio Unidad', unitCol, (_) {}),
                _priceField('Precio Cartón', cartonCol, (_) {}),
                _priceField('Precio Caja', boxCol, (_) {}),
                TextButton.icon(
                  onPressed: () {
                    final p = double.tryParse(cartonCol.text.replaceAll(',', '.')) ?? 0;
                    if (p > 0) {
                      setState(() {
                        unitCol.text = (p / 30).toStringAsFixed(2);
                        boxCol.text = (p * 12).toStringAsFixed(2);
                      });
                    }
                  },
                  icon: const Icon(Icons.calculate_outlined, size: 16),
                  label: const Text('Sugerir por proporcionalidad', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final u = double.tryParse(unitCol.text.replaceAll(',', '.')) ?? 0;
                final c = double.tryParse(cartonCol.text.replaceAll(',', '.')) ?? 0;
                final b = double.tryParse(boxCol.text.replaceAll(',', '.')) ?? 0;
                
                if (nameCol.text.isNotEmpty) {
                  final success = await context.read<ProductProvider>().addSize(nameCol.text, u, c, b);
                  if (mounted) {
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${context.read<ProductProvider>().errorMessage}')),
                      );
                    }
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceField(String label, TextEditingController controller, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'Q ',
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
      ),
    );
  }
}
