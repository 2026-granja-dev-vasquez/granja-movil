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
    final TextEditingController cartonsController = TextEditingController(text: '0');
    final TextEditingController unitsController = TextEditingController(text: '0');
    final TextEditingController reasonController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final int cartons = int.tryParse(cartonsController.text) ?? 0;
          final int units = int.tryParse(unitsController.text) ?? 0;
          final int totalToAdjust = (cartons * 30) + units;
          
          final int currentStock = item.totalUnits;
          final int finalStock = type == 'in' 
              ? currentStock + totalToAdjust 
              : currentStock - totalToAdjust;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  type == 'in' ? Icons.add_circle : Icons.remove_circle,
                  color: type == 'in' ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(type == 'in' ? 'Registrar Ingreso' : 'Registrar Egreso'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Producto: ${item.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const Divider(height: 24),
                  
                  const Text("CANTIDAD EN CARTONES (30u)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: cartonsController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grid_view),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text("HUEVOS SUELTOS (UNIDADES)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: unitsController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.egg_outlined),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Resumen en tiempo real
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: type == 'in' ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: type == 'in' ? Colors.green.shade200 : Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total a ajustar:", style: TextStyle(fontSize: 13)),
                            Text("$totalToAdjust huevos", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Stock Resultante:", style: TextStyle(fontSize: 13)),
                            Builder(
                              builder: (context) {
                                if (finalStock < 0) {
                                  return Text("$finalStock huevos", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red));
                                }
                                final c = finalStock ~/ 30;
                                final u = finalStock % 30;
                                String text = "";
                                if (c > 0 && u > 0) text = "$c cartones y $u huevos";
                                else if (c > 0) text = "$c cartón${c > 1 ? 'es' : ''}";
                                else text = "$u huevos";
                                
                                return Text(text, style: const TextStyle(fontWeight: FontWeight.bold));
                              }
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
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
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: (isSaving || totalToAdjust <= 0) ? null : () async {
                  setDialogState(() => isSaving = true);
                  
                  final success = await context.read<InventoryProvider>().adjustStock(
                    item.productSizeId,
                    type,
                    totalToAdjust,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('GUARDAR AJUSTE'),
              ),
            ],
          );
        },
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
    final TextEditingController cartonsController = TextEditingController(text: '0');
    final TextEditingController unitsController = TextEditingController(text: '0');
    final TextEditingController reasonController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final int cartons = int.tryParse(cartonsController.text) ?? 0;
          final int units = int.tryParse(unitsController.text) ?? 0;
          final int totalToAdjust = (cartons * 30) + units;
          
          final int currentStock = selectedItem.totalUnits;
          final int finalStock = currentStock + totalToAdjust;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.add_business, color: Colors.indigo),
                const SizedBox(width: 8),
                Text('Ingresar Stock Inicial'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 20),
                  
                  const Text("CANTIDAD EN CARTONES (30u)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: cartonsController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grid_view),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text("HUEVOS SUELTOS (UNIDADES)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: unitsController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.egg_outlined),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Resumen en tiempo real
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total a ingresar:", style: TextStyle(fontSize: 13)),
                            Text("$totalToAdjust huevos", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Stock Resultante:", style: TextStyle(fontSize: 13)),
                            Builder(
                              builder: (context) {
                                final c = finalStock ~/ 30;
                                final u = finalStock % 30;
                                String text = "";
                                if (c > 0 && u > 0) text = "$c cartones y $u huevos";
                                else if (c > 0) text = "$c carton${c > 1 ? 'es' : ''}";
                                else text = "$u huevos";
                                
                                return Text(text, style: const TextStyle(fontWeight: FontWeight.bold));
                              }
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Motivo / Nota (Opcional)',
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
                onPressed: (isSaving || totalToAdjust <= 0) ? null : () async {
                  setDialogState(() => isSaving = true);
                  
                  final success = await inventoryProvider.adjustStock(
                    selectedItem.productSizeId,
                    'in',
                    totalToAdjust,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('GUARDAR INGRESO'),
              ),
            ],
          );
        },
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
