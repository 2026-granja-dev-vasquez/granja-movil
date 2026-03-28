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
                    "${item.totalUnits} HUEVOS TOTALES",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: hasStock ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Formateado detallado (Cartones/Huevos)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasStock ? Colors.blue.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.formatted,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasStock ? Colors.blue.shade700 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
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
