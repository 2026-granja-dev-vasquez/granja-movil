import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sale_model.dart';
import '../providers/sale_provider.dart';
import '../providers/customer_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/models/product_size_model.dart';
import '../../production/providers/production_provider.dart';
import '../../cash/providers/cash_provider.dart';
import '../../cash/views/cash_box_screen.dart';

class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  int? _selectedCustomerId;
  final List<SaleItemModel> _items = [];
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  SaleStatus _status = SaleStatus.paid;
  bool _isSaving = false;

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
      context.read<ProductProvider>().fetchSizes();
      context.read<ProductionProvider>().fetchDailyData();
      context.read<CashProvider>().fetchActiveBox();
    });
  }

  void _addItem() async {
    final productProvider = context.read<ProductProvider>();
    final productionProvider = context.read<ProductionProvider>();

    ProductSizeModel? selectedProduct;
    String selectedUom = 'carton'; // default to carton
    int quantity = 1;
    final priceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Seleccionar Tamaño
                const Text(
                  "1. Selecciona el tamaño",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ProductSizeModel>(
                  value: selectedProduct,
                  decoration: InputDecoration(
                    hintText: 'Seleccionar...',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: productProvider.sizes
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedProduct = val;
                      if (val != null) {
                        // Pre-llenar precio según UOM actual
                        if (selectedUom == 'unit')
                          priceController.text = val.unitPrice.toString();
                        if (selectedUom == 'carton')
                          priceController.text = val.cartonPrice.toString();
                        if (selectedUom == 'box')
                          priceController.text = val.boxPrice.toString();
                      }
                    });
                  },
                ),

                if (selectedProduct != null) ...[
                  const SizedBox(height: 20),
                  // 2. Seleccionar Tipo (UoM)
                  // 2. Seleccionar Tipo (UoM)
                  const Text(
                    "2. ¿Cómo lo vendes?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Slightly larger
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Lista Vertical de Opciones
                  ...[{
                    'id': 'unit',
                    'name': 'Por Unidad',
                    'icon': Icons.egg_outlined,
                    'desc': 'Venta individual'
                  }, {
                    'id': 'carton',
                    'name': 'Por Cartón',
                    'icon': Icons.grid_on,
                    'desc': '30 huevos'
                  }, {
                    'id': 'box',
                    'name': 'Por Caja',
                    'icon': Icons.inventory_2,
                    'desc': '12 cartones / 360 huevos'
                  }].map((opt) {
                    final isSelected = selectedUom == opt['id'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedUom = opt['id'] as String;
                            if (selectedUom == 'unit')
                              priceController.text = selectedProduct!.unitPrice.toString();
                            if (selectedUom == 'carton')
                              priceController.text = selectedProduct!.cartonPrice.toString();
                            if (selectedUom == 'box')
                              priceController.text = selectedProduct!.boxPrice.toString();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                opt['icon'] as IconData,
                                color: isSelected ? Colors.blue : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opt['name'] as String,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isSelected ? Colors.blue.shade900 : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      opt['desc'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected ? Colors.blue.shade700 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),
                  // 3. Cantidad y Precio
                  const Text(
                    "3. Cantidad y Precio",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: '1',
                          decoration: InputDecoration(
                            labelText: 'Cantidad',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => quantity = int.tryParse(val) ?? 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: priceController,
                          decoration: InputDecoration(
                            labelText: 'Precio (Q)',
                            prefixText: 'Q ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  // Info de Stock
                  Builder(
                    builder: (context) {
                      final stock = productionProvider.inventoryStatus
                          .firstWhere(
                            (s) => s.productSizeId == selectedProduct!.id,
                            orElse: () => throw Exception('No stock found'),
                          );
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Stock: ${stock.formatted}",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (selectedProduct == null || quantity <= 0) return;

                // Conversión a unidades (huevos)
                int factor = 1;
                if (selectedUom == 'carton') factor = 30;
                if (selectedUom == 'box') factor = 360; // 12 cartones

                final totalUnits = quantity * factor;
                final totalPriceEntered =
                    double.tryParse(priceController.text) ?? 0;
                final subtotal = quantity * totalPriceEntered;

                // Calculamos el precio por huevo para el backend (subtotal / totalUnits)
                final unitPriceForBackend = subtotal / totalUnits;

                setState(() {
                  _items.add(
                    SaleItemModel(
                      productSizeId: selectedProduct!.id,
                      quantity: totalUnits,
                      unitPrice: unitPriceForBackend,
                      subtotal: subtotal,
                      productSize: selectedProduct,
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Agregar al Carrito'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_isSaving) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final sale = SaleModel(
      customerId: _selectedCustomerId,
      totalAmount: _totalAmount,
      paidAmount: _status == SaleStatus.paid ? _totalAmount : 0,
      status: _status,
      date: _selectedDate,
      notes: _notesController.text,
      items: _items,
    );

    final success = await context.read<SaleProvider>().createSale(sale);
    if (!mounted) return;
    setState(() => _isSaving = false);
    
    if (success) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 64),
              SizedBox(height: 16),
              Text("¡Venta Exitosa!", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "La venta ha sido registrada correctamente en el sistema y el inventario ha sido actualizado.",
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                },
                child: const Text("ENTERADO", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
      if (mounted) Navigator.pop(context); // Regresar al dashboard
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${context.read<SaleProvider>().errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().activeCustomers;
    final cashProvider = context.watch<CashProvider>();
    final hasActiveBox = cashProvider.activeBox != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Venta')),
      body: Column(
        children: [
          // BANNER DE AVISO CAJA CERRADA
          if (!hasActiveBox && _status != SaleStatus.pending)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CAJA CERRADA",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown),
                        ),
                        const Text(
                          "Debes abrir una caja para registrar pagos.",
                          style: TextStyle(fontSize: 11, color: Colors.brown),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashBoxScreen())),
                    child: const Text("ABRIR AQUÍ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            
          // CABECERA DE VENTA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 0,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<int?>(
                      value: _selectedCustomerId,
                      decoration: const InputDecoration(
                        labelText: 'Cliente',
                        prefixIcon: Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("Consumidor Final"),
                        ),
                        ...customers.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedCustomerId = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<SaleStatus>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Estado',
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: SaleStatus.paid,
                                child: Text("Pagado"),
                              ),
                              DropdownMenuItem(
                                value: SaleStatus.pending,
                                child: Text("Pendiente (Crédito)"),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _status = val!);
                              // Si no hay caja, y eligen pagado, avisar
                              if (!hasActiveBox && val == SaleStatus.paid) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Abre la caja primero para ventas al contado."))
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(
                            Icons.calendar_today,
                            color: Colors.blue,
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null)
                              setState(() => _selectedDate = picked);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_basket_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
                SizedBox(width: 8),
                Text(
                  "Detalle de Productos",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // LISTA DE ITEMS (CARRITO)
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Text(
                      "El carrito está vacío",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      String quantityDisplay = "";
                      if (item.quantity >= 360 && item.quantity % 360 == 0) {
                        quantityDisplay = "${item.quantity ~/ 360} caja(s)";
                      } else if (item.quantity >= 30 &&
                          item.quantity % 30 == 0) {
                        quantityDisplay = "${item.quantity ~/ 30} cartón(es)";
                      } else {
                        quantityDisplay = "${item.quantity} unidades";
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(Icons.egg, color: Colors.blue),
                          ),
                          title: Text(
                            item.productSize?.name ?? "Producto",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "$quantityDisplay (${item.quantity} huevos)\nSubtotal: Q${item.subtotal.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Q${item.subtotal.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    setState(() => _items.removeAt(index)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // RESUMEN Y BOTÓN
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total a Cobrar:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Q${_totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'PROCESAR VENTA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton.extended(
          onPressed: _addItem,
          label: const Text("Agregar Producto"),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.blue.shade800,
        ),
      ),
    );
  }
}
