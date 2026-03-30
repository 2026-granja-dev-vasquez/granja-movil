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
              const SizedBox(height: 8),
              Text('Nota: ${order.notes}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
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

