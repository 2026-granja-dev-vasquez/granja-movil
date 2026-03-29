import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
    bool isSaving = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Marcar Entregado'),
          content: const Text('¿Confirmas que este pedido ha sido entregado exitosamente?'),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                setDialogState(() => isSaving = true);
                final success = await context.read<OrderProvider>().updateOrderStatus(order.id, 'delivered');
                if (context.mounted) {
                  if (success) {
                    Navigator.pop(context);
                  } else {
                    setDialogState(() => isSaving = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('SÍ, ENTREGADO'),
            ),
          ],
        ),
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

          // Flatten for ListView
          final listItems = <dynamic>[];
          for (var date in sortedDates) {
            listItems.add(date); // Header
            final orders = ordersByDate[date] ?? [];
            if (orders.isEmpty && date == today) {
              listItems.add("No hay entregas para hoy");
            } else {
              listItems.addAll(orders);
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
            itemCount: listItems.length,
            itemBuilder: (context, index) {
              final item = listItems[index];

              if (item is DateTime) {
                String title;
                if (item == today) {
                  title = "HOY";
                } else if (item == tomorrow) {
                  title = "MAÑANA";
                } else {
                  title = DateFormat('EEEE dd/MM', 'es').format(item).toUpperCase();
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.grey.shade700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                );
              }

              if (item is String) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      item,
                      style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
                );
              }

              final order = item as OrderModel;
              final isOverdue = order.isOverdue;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isOverdue ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
                ),
                elevation: 2,
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                          ),
                          if (isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                              child: const Text("ATRASADO", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          else if (order.isPostponed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                              child: const Text("POSPUESTO", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_filled, size: 16, color: isOverdue ? Colors.red : Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('hh:mm a').format(order.deliveryDate),
                            style: TextStyle(fontSize: 14, color: isOverdue ? Colors.red : Colors.black87, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (order.items.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "CARGAR PARA ENTREGA:",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: order.items.map((it) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.indigo.shade100),
                                  ),
                                  child: Text(
                                    "${it.formattedQuantity} ${it.productSize?.name ?? ''}",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo),
                                  ),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (order.notes != null && order.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Nota: ${order.notes}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () => _confirmDelivery(order),
                            icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                            label: const Text('Entregar', style: TextStyle(color: Colors.green)),
                          ),
                          TextButton.icon(
                            onPressed: () => _showPostponeDialog(order),
                            icon: const Icon(Icons.update, color: Colors.orange, size: 20),
                            label: const Text('Posponer', style: TextStyle(color: Colors.orange)),
                          ),
                          IconButton(
                            onPressed: () => _showCancelDialog(order),
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                            tooltip: 'Anular Pedido',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
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
