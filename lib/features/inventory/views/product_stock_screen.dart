import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';

class ProductStockScreen extends StatefulWidget {
  const ProductStockScreen({super.key});

  @override
  State<ProductStockScreen> createState() => _ProductStockScreenState();
}

class _ProductStockScreenState extends State<ProductStockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Existencias de Producto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => inventoryProvider.fetchInventory(),
          ),
        ],
      ),
      body: inventoryProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : inventoryProvider.errorMessage != null
              ? _buildErrorState(inventoryProvider.errorMessage!)
              : inventoryProvider.inventory.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () => inventoryProvider.fetchInventory(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: inventoryProvider.inventory.length,
                        itemBuilder: (context, index) {
                          final item = inventoryProvider.inventory[index];
                          return _buildStockCard(item);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGlobalAdjustmentDialog(),
        icon: const Icon(Icons.add),
        label: const Text('INGRESAR STOCK'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStockCard(dynamic item) {
    final bool hasStock = item.totalUnits > 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icono / Visual representativo
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: hasStock ? Colors.orange.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.egg_outlined,
                size: 32,
                color: hasStock ? Colors.orange : Colors.grey,
              ),
            ),
            const SizedBox(width: 20),
            // Información del producto
            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.1,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.formatted.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: hasStock ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "TOTAL: ${item.totalUnits} HUEVOS",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasStock ? Colors.blue.shade700 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Botones de Ajuste
            Column(
              children: [
                IconButton(
                  onPressed: () => _showAdjustmentDialog(item, 'in'),
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  tooltip: 'Ingreso Extra',
                ),
                IconButton(
                  onPressed: () => _showAdjustmentDialog(item, 'out'),
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  tooltip: 'Egreso / Ajuste',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustmentDialog(dynamic item, String type) {
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    bool isSaving = false;
    bool inCartons = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                type == 'in' ? Icons.add_business : Icons.inventory_2,
                color: type == 'in' ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(type == 'in' ? 'Registrar Ingreso' : 'Registrar Egreso'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ajustando stock para: ${item.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: inCartons ? 'Cartones (30u)' : 'Huevos Sueltos',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(inCartons ? Icons.grid_view : Icons.egg),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      const Text('Modo', style: TextStyle(fontSize: 10)),
                      Switch(
                        value: inCartons,
                        onChanged: (val) => setDialogState(() => inCartons = val),
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motivo / Nota (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                final qty = int.tryParse(quantityController.text);
                if (qty == null || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor ingresa una cantidad válida')),
                  );
                  return;
                }

                setDialogState(() => isSaving = true);
                
                final totalUnits = inCartons ? qty * 30 : qty;
                final success = await context.read<InventoryProvider>().adjustStock(
                  item.productSizeId,
                  type,
                  totalUnits,
                  reasonController.text.isEmpty ? null : reasonController.text,
                );

                if (context.mounted) {
                  if (success) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ajuste realizado con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    setDialogState(() => isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.read<InventoryProvider>().errorMessage ?? 'Error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: type == 'in' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('GUARDAR AJUSTE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGlobalAdjustmentDialog() {
    final inventoryProvider = context.read<InventoryProvider>();
    final availableSizes = inventoryProvider.inventory;
    
    if (availableSizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay tamaños de producto configurados')),
      );
      return;
    }

    dynamic selectedItem = availableSizes.first;
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    bool isSaving = false;
    bool inCartons = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_business, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Ingresar Stock Inicial'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<dynamic>(
                  value: selectedItem,
                  decoration: const InputDecoration(
                    labelText: 'Tamaño de Huevo',
                    border: OutlineInputBorder(),
                  ),
                  items: availableSizes.map((item) {
                    return DropdownMenuItem<dynamic>(
                      value: item,
                      child: Text(item.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedItem = val);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: inCartons ? 'Cartones (30u)' : 'Huevos Sueltos',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        const Text('Modo', style: TextStyle(fontSize: 10)),
                        Switch(
                          value: inCartons,
                          onChanged: (val) => setDialogState(() => inCartons = val),
                          activeThumbColor: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                final qty = int.tryParse(quantityController.text);
                if (qty == null || qty <= 0) return;

                setDialogState(() => isSaving = true);
                
                final totalUnits = inCartons ? qty * 30 : qty;
                final success = await inventoryProvider.adjustStock(
                  selectedItem.productSizeId,
                  'in',
                  totalUnits,
                  reasonController.text.isEmpty ? null : reasonController.text,
                );

                if (context.mounted) {
                  if (success) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Stock inicial guardado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    setDialogState(() => isSaving = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<InventoryProvider>().fetchInventory(),
            child: const Text("Reintentar"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No hay registros de inventario aún.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
