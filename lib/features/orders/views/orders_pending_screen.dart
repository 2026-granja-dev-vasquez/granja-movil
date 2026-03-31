import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../cash/providers/cash_provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import 'add_order_screen.dart';
import 'orders_history_screen.dart';

class OrdersPendingScreen extends StatefulWidget {
  const OrdersPendingScreen({super.key});

  @override
  State<OrdersPendingScreen> createState() => _OrdersPendingScreenState();
}

class _OrdersPendingScreenState extends State<OrdersPendingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchPendingOrders();
    });
  }

  Widget _buildDateAccordion(DateTime date, List<OrderModel> orders, DateTime today, DateTime tomorrow) {
    if (orders.isEmpty) return const SizedBox.shrink();

    // 1. Calculate Totals for this specific day
    final totalsBySize = <int, int>{};
    final sizeNames = <int, String>{};

    for (var order in orders) {
      for (var item in order.items) {
        final sid = item.productSizeId;
        totalsBySize[sid] = (totalsBySize[sid] ?? 0) + item.quantity;
        sizeNames[sid] = item.productSize?.name ?? '...';
      }
    }

    String title;
    bool isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    bool isTomorrow = date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;

    if (isToday) {
      title = "HOY";
    } else if (isTomorrow) {
      title = "MAÑANA";
    } else {
      title = DateFormat('EEEE dd/MM', 'es').format(date).toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isToday ? Colors.amber.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday ? Colors.amber.shade200 : Colors.grey.shade200,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false, // Siempre cerrado por defecto
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isToday ? Colors.amber : Colors.indigo.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isToday ? Icons.today : Icons.calendar_today,
              color: isToday ? Colors.white : Colors.indigo,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: isToday ? Colors.brown : Colors.indigo.shade900,
              letterSpacing: 1.1,
            ),
          ),
          subtitle: totalsBySize.isEmpty 
            ? null 
            : Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: totalsBySize.entries.map((e) {
                    final q = e.value;
                    final c = q ~/ 30;
                    final u = q % 30;
                    String d = "";
                    if (c > 0) d += "$c cart.";
                    if (u > 0) d += "${d.isEmpty ? '' : ' '}$u uni.";
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Icon(Icons.egg, size: 14, color: isToday ? Colors.amber.shade700 : Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            "$d ${sizeNames[e.key]}",
                            style: TextStyle(
                              fontSize: 14, // Aumentado para mejor legibilidad
                              color: isToday ? Colors.brown.shade700 : Colors.grey.shade800,
                              fontWeight: FontWeight.w900, // Más grueso para resaltar
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          children: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: orders.map((order) => _buildOrderCard(order)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final isOverdue = order.isOverdue;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOverdue ? Colors.red.shade300 : Colors.grey.shade100,
          width: isOverdue ? 1.5 : 1,
        ),
      ),
      color: isOverdue ? Colors.red.shade50.withOpacity(0.3) : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.customer?.name ?? 'Cliente Desconocido',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                    child: const Text("ATRASADO", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: isOverdue ? Colors.red : Colors.grey),
                const SizedBox(width: 6),
                Text(
                  DateFormat('hh:mm a').format(order.deliveryDate),
                  style: TextStyle(fontSize: 13, color: isOverdue ? Colors.red : Colors.black87, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: order.items.map((it) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.shade50),
                ),
                child: Text(
                  "${it.formattedQuantity} ${it.productSize?.name ?? ''}",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              )).toList(),
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey.shade900,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  label: 'Entregar',
                  onTap: () => _confirmDelivery(order),
                ),
                _ActionButton(
                  icon: Icons.update,
                  color: Colors.orange,
                  label: 'Posponer',
                  onTap: () => _showPostponeDialog(order),
                ),
                _ActionButton(
                  icon: Icons.edit,
                  color: Colors.blue,
                  label: 'Modificar',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddOrderScreen(order: order)),
                    );
                  },
                ),
                _ActionButton(
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  label: 'Anular',
                  onTap: () => _showCancelDialog(order),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPostponeDialog(OrderModel order) {
    bool isSaving = false;
    DateTime newDate = order.deliveryDate;
    TimeOfDay newTime = TimeOfDay.fromDateTime(order.deliveryDate);
    final notesController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Posponer Pedido'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Nueva Fecha'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(newDate)),
                  trailing: const Icon(Icons.calendar_today, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: newDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => newDate = picked);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Nueva Hora'),
                  subtitle: Text(newTime.format(context)),
                  trailing: const Icon(Icons.access_time, size: 20),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: newTime,
                    );
                    if (picked != null) {
                      setDialogState(() => newTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
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
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                setDialogState(() => isSaving = true);
                final finalDateTime = DateTime(
                  newDate.year, newDate.month, newDate.day,
                  newTime.hour, newTime.minute,
                );
                final success = await context.read<OrderProvider>().updateOrderStatus(
                  order.id, 
                  'postponed', 
                  newDate: finalDateTime,
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                );
                if (context.mounted) {
                  if (success) {
                    Navigator.pop(context);
                  } else {
                    setDialogState(() => isSaving = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('POSPONER'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(OrderModel order) {
    bool isSaving = false;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cancelar Pedido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Estás seguro de que este pedido ya no se entregará?', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la cancelación',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('VOLVER'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (notesController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor ingresa un motivo')));
                  return;
                }
                setDialogState(() => isSaving = true);
                final success = await context.read<OrderProvider>().updateOrderStatus(
                  order.id, 
                  'cancelled', 
                  notes: notesController.text,
                );
                if (context.mounted) {
                  if (success) {
                    Navigator.pop(context);
                  } else {
                    setDialogState(() => isSaving = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('CANCELAR PEDIDO'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelivery(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Entrega'),
        content: const Text('¿Cómo deseas procesar esta entrega?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _processSimpleDelivery(order);
            },
            child: const Text('SOLO ENTREGAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSaleProcessingDialog(order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('ENTREGAR Y VENDER'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog({required bool isSale}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(isSale ? "¡Venta y Entrega Exitosa!" : "¡Entrega Registrada!", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          isSale 
            ? "La venta se ha guardado, el inventario se descontó y el pedido pasó al historial."
            : "El pedido se ha marcado como entregado y el inventario se descontó correctamente.",
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
              onPressed: () => Navigator.pop(context),
              child: const Text("ENTERADO", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _processSimpleDelivery(OrderModel order) async {
    // Generar resumen en cartones para la nota
    String itemNote = "Entregado sin cobrar: ";
    final List<String> parts = [];
    for (var it in order.items) {
      final int c = it.quantity ~/ 30;
      final int u = it.quantity % 30;
      String d = "";
      if (c > 0) d += "$c cart.";
      if (u > 0) d += "${d.isEmpty ? '' : ' '}$u uni.";
      parts.add("$d ${it.productSize?.name ?? 'Huevo'}");
    }
    itemNote += parts.join(", ");

    // Preparar saleData con montos en 0
    final saleItems = order.items.map((it) => {
      'product_size_id': it.productSizeId,
      'quantity': it.quantity,
      'unit_price': 0.0,
    }).toList();

    final saleData = {
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'paid_amount': 0.0,
      'items': saleItems,
      'notes': itemNote,
    };

    final success = await context.read<OrderProvider>().updateOrderStatus(
      order.id, 
      'delivered',
      createSale: true,
      saleData: saleData,
    );
    
    if (success && mounted) {
      _showSuccessDialog(isSale: false);
    }
  }

  void _showSaleProcessingDialog(OrderModel order) {
    // Verificar caja abierta primero
    final hasBox = context.read<CashProvider>().activeBox != null;
    if (!hasBox) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Caja Cerrada'),
          content: const Text('Debes tener una caja abierta para procesar ventas con pago.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ENTENDIDO')),
          ],
        ),
      );
      return;
    }

    // Inicializar controladores con precios sugeridos basados en la cantidad
    final controllers = <int, TextEditingController>{};
    final isCartonMode = <int, bool>{};

    for (var item in order.items) {
      final bool isMultipleOf30 = item.quantity >= 30 && item.quantity % 30 == 0;
      isCartonMode[item.id!] = isMultipleOf30;
      
      final defaultPrice = isMultipleOf30 
          ? (item.productSize?.cartonPrice ?? 0.0)
          : (item.productSize?.unitPrice ?? 0.0);
          
      controllers[item.id!] = TextEditingController(text: defaultPrice.toStringAsFixed(2));
    }

    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double total = 0;
          for (var item in order.items) {
            final price = double.tryParse(controllers[item.id]!.text) ?? 0.0;
            if (isCartonMode[item.id] == true) {
              total += ((item.quantity / 30) * price);
            } else {
              total += (item.quantity * price);
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.indigo),
                const SizedBox(width: 10),
                Expanded(child: Text('Cuenta de ${order.customer?.name ?? "Varios"}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(),
                    ...order.items.map((item) {
                      final isCarton = isCartonMode[item.id] == true;
                      final double subtotal = (isCarton ? (item.quantity / 30) : item.quantity) * (double.tryParse(controllers[item.id]!.text) ?? 0.0);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.formattedQuantity} ${item.productSize?.name ?? "Huevo"}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: controllers[item.id],
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: isCarton ? 'Q cada Cartón' : 'Q cada Unidad',
                                      prefixText: 'Q ',
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Subtotal', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text('Q ${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade900,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          const Text('TOTAL A PAGAR', style: TextStyle(color: Colors.indigoAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          const SizedBox(height: 4),
                          Text(
                            'Q ${total.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  setDialogState(() => isSaving = true);
                  
                  final saleItems = order.items.map((it) {
                    final price = double.tryParse(controllers[it.id]!.text) ?? 0.0;
                    final isCarton = isCartonMode[it.id] == true;
                    
                    // Backend siempre espera unit_price (por huevo)
                    final unitPriceForBackend = isCarton ? (price / 30) : price;

                    return {
                      'product_size_id': it.productSizeId,
                      'quantity': it.quantity,
                      'unit_price': unitPriceForBackend,
                    };
                  }).toList();

                  final success = await context.read<OrderProvider>().updateOrderStatus(
                    order.id, 
                    'delivered',
                    createSale: true,
                    saleData: {
                      'date': DateTime.now().toIso8601String().split('T')[0], // Enviar fecha local YYYY-MM-DD
                      'paid_amount': total, // El pago es el total calculado
                      'items': saleItems,
                    }
                  );

                  if (context.mounted) {
                    if (success) {
                      Navigator.pop(context); // Cerrar diálogo de procesamiento
                      _showSuccessDialog(isSale: true);
                    } else {
                      setDialogState(() => isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<OrderProvider>().errorMessage ?? 'Error al procesar')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: isSaving 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('PROCESAR VENTA'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Pedidos Programados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.blueGrey),
            tooltip: 'Historial',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersHistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<OrderProvider>().fetchPendingOrders(),
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.pendingOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.pendingOrders.isEmpty) {
            return Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)));
          }

          if (provider.pendingOrders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay pedidos pendientes', style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final tomorrow = today.add(const Duration(days: 1));

          // Grouping logic
          final ordersByDate = <DateTime, List<OrderModel>>{};
          for (var order in provider.pendingOrders) {
            final date = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
            ordersByDate.putIfAbsent(date, () => []).add(order);
          }

          // Ensure Today and Tomorrow are represented if requested or if relative
          final sortedDates = ordersByDate.keys.toList()..sort();
          
          bool hasToday = ordersByDate.containsKey(today);
          if (!hasToday && provider.pendingOrders.isNotEmpty) {
            // We only show "Today: No orders" if there are *some* pending orders in the future
            // or if we want to be explicit. Let's be explicit as requested.
            sortedDates.insert(0, today);
          }

          // UI Builders
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final orders = ordersByDate[date] ?? [];
              return _buildDateAccordion(date, orders, today, tomorrow);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddOrderScreen())),
        label: const Text('Nuevo Pedido'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
