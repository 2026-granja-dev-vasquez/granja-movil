import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/sale_model.dart';
import '../providers/sale_provider.dart';

class SaleDetailScreen extends StatelessWidget {
  final SaleModel sale;

  const SaleDetailScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    final bool isPaid = sale.status == SaleStatus.paid;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Venta')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Resumen de la Venta
            Container(
              color: Colors.blue.shade50,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    isPaid ? Icons.check_circle : Icons.pending_actions,
                    size: 64,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "TOTAL: Q${sale.totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPaid ? "PAGADO" : "PENDIENTE DE PAGO",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Información del Cliente
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(icon: Icons.person_outline, label: "Cliente"),
                      const SizedBox(height: 8),
                      Text(
                        sale.customer?.name ?? "Consumidor Final (Mostrador)",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      const _SectionHeader(icon: Icons.calendar_today_outlined, label: "Fecha y Hora"),
                      const SizedBox(height: 8),
                      Text(
                        formatter.format(sale.date),
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const _SectionHeader(icon: Icons.notes, label: "Notas"),
                        const SizedBox(height: 8),
                        Text(
                          sale.notes!,
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _SectionHeader(icon: Icons.list_alt, label: "Productos"),
            ),

            // Listado de Productos
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sale.items.length,
              itemBuilder: (context, index) {
                final item = sale.items[index];
                
                String quantityDisplay = "";
                if (item.quantity >= 360 && item.quantity % 360 == 0) {
                  quantityDisplay = "${item.quantity ~/ 360} caja(s)";
                } else if (item.quantity >= 30 && item.quantity % 30 == 0) {
                  quantityDisplay = "${item.quantity ~/ 30} cartón(es)";
                } else {
                  quantityDisplay = "${item.quantity} huevos";
                }

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade100),
                  ),
                  child: ListTile(
                    title: Text(
                      item.productSize?.name ?? "Cargando...",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "$quantityDisplay (${item.quantity} huevos)",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Q${item.subtotal.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                        Text(
                          "Q${item.unitPrice.toStringAsFixed(2)} c/u",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Botón de Acción si está pendiente
            if (!isPaid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<SaleProvider>(
                  builder: (context, provider, _) {
                    return ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: provider.isLoading ? null : () => _confirmPayment(context),
                      icon: provider.isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.payments_outlined),
                      label: const Text("REGISTRAR PAGO COMPLETO", style: TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPayment(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Pago"),
        content: Text("¿Deseas marcar esta venta de Q${sale.totalAmount.toStringAsFixed(2)} como totalmente PAGADA?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sí, Pagado")),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<SaleProvider>().updateSaleStatus(sale.id!, {
        'status': 'paid',
        'paid_amount': sale.totalAmount,
      });

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Venta actualizada a PAGADA! 🎉"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Regresar al historial
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }
}
