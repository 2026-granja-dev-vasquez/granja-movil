import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sale_provider.dart';
import '../models/sale_model.dart';
import 'sale_detail_screen.dart';

class AccountsReceivableScreen extends StatefulWidget {
  const AccountsReceivableScreen({super.key});

  @override
  State<AccountsReceivableScreen> createState() => _AccountsReceivableScreenState();
}

class _AccountsReceivableScreenState extends State<AccountsReceivableScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().fetchSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final saleProvider = context.watch<SaleProvider>();
    
    // Filtrar solo las ventas pendientes o parciales
    final pendingSales = saleProvider.sales.where((s) => s.status != SaleStatus.paid).toList();

    // Agrupar deuda por cliente
    final Map<int?, List<SaleModel>> customerDebts = {};
    for (var sale in pendingSales) {
      if (!customerDebts.containsKey(sale.customerId)) {
        customerDebts[sale.customerId] = [];
      }
      customerDebts[sale.customerId]!.add(sale);
    }

    final sortedCustomerIds = customerDebts.keys.toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Cobros y Cuentas por Cobrar"),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: saleProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingSales.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedCustomerIds.length,
                  itemBuilder: (context, index) {
                    final customerId = sortedCustomerIds[index];
                    final invoices = customerDebts[customerId]!;
                    final customerName = invoices.first.customer?.name ?? "Consumidor Final (Sin nombre)";
                    final totalDebt = invoices.fold<double>(0, (sum, item) => sum + (item.totalAmount - item.paidAmount));

                    return _buildCustomerDebtCard(customerName, totalDebt, invoices);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_very_satisfied, size: 64, color: Colors.green.shade200),
          const SizedBox(height: 16),
          const Text(
            "¡No hay cuentas pendientes!",
            style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text("Todos tus clientes están al día.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCustomerDebtCard(String name, double total, List<SaleModel> invoices) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade100),
      ),
      child: ExpansionTile(
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade50,
          child: const Icon(Icons.person, color: Colors.red),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Deuda Total: Q${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        children: invoices.map((sale) => _buildInvoiceItem(sale)).toList(),
      ),
    );
  }

  Widget _buildInvoiceItem(SaleModel sale) {
    return ListTile(
      dense: true,
      title: Text("Venta del ${DateFormat('dd/MM/yyyy').format(sale.date)}"),
      subtitle: Text("Saldo: Q${(sale.totalAmount - sale.paidAmount).toStringAsFixed(2)}"),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: () => _markAsPaid(sale),
        child: const Text("COBRAR", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SaleDetailScreen(sale: sale)),
        );
      },
    );
  }

  Future<void> _markAsPaid(SaleModel sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirmar Cobro"),
        content: Text("¿Deseas marcar la venta de Q${sale.totalAmount.toStringAsFixed(2)} como totalmente PAGADA?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Sí, Cobrar")),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<SaleProvider>().updateSaleStatus(sale.id!, {
        'status': 'paid',
        'paid_amount': sale.totalAmount,
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Venta cobrada con éxito! 🎉"), backgroundColor: Colors.green),
        );
      }
    }
  }
}
