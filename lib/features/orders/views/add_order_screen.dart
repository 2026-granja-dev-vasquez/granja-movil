import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../../sales/providers/customer_provider.dart';
import '../../sales/models/customer_model.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../../shared/widgets/loading_button.dart';
import '../models/order_model.dart' as order_model;

class AddOrderScreen extends StatefulWidget {
  final order_model.OrderModel? order;
  const AddOrderScreen({super.key, this.order});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  CustomerModel? _selectedCustomer;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  // Items logic
  final List<Map<String, dynamic>> _items = []; // {product_size_id, name, qty_units, formatted_qty}

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _selectedCustomer = widget.order!.customer;
      _selectedDate = widget.order!.deliveryDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.order!.deliveryDate);
      _notesController.text = widget.order!.notes ?? "";
      
      for (var item in widget.order!.items) {
        final int c = item.quantity ~/ 30;
        final int u = item.quantity % 30;
        String f = "";
        if (c > 0) f += "$c ct";
        if (u > 0) f += "${f.isEmpty ? '' : ' '}$u u";
        
        _items.add({
          'product_size_id': item.productSizeId,
          'name': item.productSize?.name ?? '...',
          'quantity': item.quantity,
          'formatted_qty': f,
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
      context.read<InventoryProvider>().fetchInventory();
    });
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCustomer == null || _selectedCustomer!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un cliente')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Validate that the scheduled time is in the future (solo si es nuevo o cambió fecha)
    if (widget.order == null && finalDateTime.isBefore(DateTime.now())) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora de entrega debe ser en el futuro')),
      );
      return;
    }

    if (_items.isEmpty) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto al pedido')),
      );
      return;
    }

    final bool success;
    if (widget.order != null) {
      success = await context.read<OrderProvider>().updateOrder(
        widget.order!.id,
        _selectedCustomer!.id!,
        finalDateTime,
        _items,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    } else {
      success = await context.read<OrderProvider>().createOrder(
        _selectedCustomer!.id!,
        finalDateTime,
        _items,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.order != null ? 'Pedido actualizado con éxito' : 'Pedido programado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isSaving = false);
        final error =
            context.read<OrderProvider>().errorMessage ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order != null ? 'Editar Pedido' : 'Nuevo Pedido'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Programar Entregas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona un cliente y la fecha/hora en la que entregarás el producto. Recibirás una alarma 1 hora antes.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Selector de Clientes
            Consumer<CustomerProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.activeCustomers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(),
                  );
                }
                return DropdownButtonFormField<CustomerModel>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCustomer,
                  items: provider.activeCustomers.map((customer) {
                    return DropdownMenuItem(
                      value: customer,
                      child: Text(customer.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCustomer = val),
                  validator: (val) => val == null ? 'Selecciona un cliente válido' : null,
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Selector de Fecha (Simulado con TextFormField)
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: DateFormat('EEEE d, MMMM yyyy', 'es_GT').format(_selectedDate)),
              decoration: const InputDecoration(
                labelText: 'Fecha de Entrega',
                prefixIcon: Icon(Icons.calendar_month, color: Colors.indigo),
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),

            const SizedBox(height: 20),

            // Selector de Hora (Simulado con TextFormField)
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: _selectedTime.format(context)),
              decoration: const InputDecoration(
                labelText: 'Hora Programada',
                prefixIcon: Icon(Icons.access_time_filled, color: Colors.orange),
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null) {
                  setState(() => _selectedTime = picked);
                }
              },
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Detalle de Productos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 12),
            
            // Lista de items ya agregados
            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Text('Aún no has agregado productos', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              )
            else
              ..._items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Cantidad: ${item['formatted_qty']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() => _items.removeAt(idx)),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 16),
            
            // Botón para abrir diálogo de agregar item
            OutlinedButton.icon(
              onPressed: () => _showAddItemDialog(),
              icon: const Icon(Icons.add),
              label: const Text('AGREGAR PRODUCTO AL PEDIDO'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.indigo,
              ),
            ),

            const SizedBox(height: 24),
            TextField(
              controller: _notesController,
              maxLines: 4,
              minLines: 2,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Notas Adicionales (Opcional)',
                hintText: 'Ej: Entregar por la puerta trasera...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_alt_outlined),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 48),
            LoadingButton(
              text: 'PROGRAMAR ALARMA DE PEDIDO',
              isLoading: _isSaving,
              onPressed: _submit,
            ),
          ]
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    final invProvider = context.read<InventoryProvider>();
    if (invProvider.inventory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay tamaños de huevo cargados en inventario')),
      );
      return;
    }

    dynamic selectedSize = invProvider.inventory.first;
    final TextEditingController qtyController = TextEditingController();
    bool inCartons = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Agregar a Entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<dynamic>(
                value: selectedSize,
                decoration: const InputDecoration(labelText: 'Tamaño'),
                items: invProvider.inventory.map((size) {
                  return DropdownMenuItem(value: size, child: Text(size.name));
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedSize = val),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: inCartons ? 'Cartones' : 'Huevos',
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
                        activeThumbColor: Colors.indigo,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(qtyController.text);
                if (qty == null || qty <= 0) return;

                final totalUnits = inCartons ? qty * 30 : qty;
                final formatted = inCartons ? '$qty ct' : '$qty u';

                setState(() {
                  _items.add({
                    'product_size_id': selectedSize.productSizeId,
                    'name': selectedSize.name,
                    'quantity': totalUnits,
                    'formatted_qty': formatted,
                  });
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text('AGREGAR'),
            ),
          ],
        ),
      ),
    );
  }
}
