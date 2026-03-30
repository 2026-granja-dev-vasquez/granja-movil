import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cash_provider.dart';
import '../models/cash_model.dart';

class CashHistoryScreen extends StatefulWidget {
  const CashHistoryScreen({super.key});

  @override
  State<CashHistoryScreen> createState() => _CashHistoryScreenState();
}

class _CashHistoryScreenState extends State<CashHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashProvider>().fetchHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<CashTransactionModel>> _groupTransactions(List<CashTransactionModel> transactions) {
    final Map<String, List<CashTransactionModel>> groups = {};
    
    // Convert to list for sorting (history transactions are typically ordered)
    final sorted = List<CashTransactionModel>.from(transactions)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (var tx in sorted) {
      final dayName = DateFormat('EEEE, d MMM', 'es_GT').format(tx.createdAt);
      final label = "${dayName.substring(0, 1).toUpperCase()}${dayName.substring(1).toUpperCase()}";

      if (groups[label] == null) groups[label] = [];
      groups[label]!.add(tx);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final cashProvider = context.watch<CashProvider>();
    final currencyFormat = NumberFormat.currency(symbol: 'Q');

    final filteredHistory = cashProvider.history.where((session) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final name = (session.name ?? "Caja #${session.id}").toLowerCase();
      final date = DateFormat('dd MMM yyyy').format(session.openedAt).toLowerCase();
      return name.contains(query) || date.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Historial de Cajas'),
      ),
      body: Column(
        children: [
          // Buscador en Historial
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Filtrar por nombre o fecha...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, size: 20, color: Colors.grey),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          ),
          
          Expanded(
            child: cashProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHistory.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          final session = filteredHistory[index];
                          return _buildSessionCard(session, currencyFormat);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(CashBoxModel session, NumberFormat format) {
    final isClosed = session.status == 'closed';
    final balance = session.closingBalance ?? session.currentBalance;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: (expanded) {
          if (expanded && session.transactions.isEmpty) {
            context.read<CashProvider>().fetchBoxDetails(session.id);
          }
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                session.name ?? "Caja #${session.id}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.indigo),
              onPressed: () => _showRenameDialog(session),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(isClosed),
          ],
        ),
        subtitle: Text(
          "Inició: ${DateFormat('dd MMM yyyy').format(session.openedAt)}",
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        leading: CircleAvatar(
          backgroundColor: isClosed ? Colors.grey.shade100 : Colors.green.shade50,
          radius: 20,
          child: Icon(
            isClosed ? Icons.lock_outline : Icons.lock_open_outlined,
            color: isClosed ? Colors.grey : Colors.green,
            size: 20,
          ),
        ),
        trailing: Text(
          format.format(balance),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _buildSummaryRow("Saldo Inicial", format.format(session.openingBalance)),
                _buildSummaryRow("Total Ingresos", "+ ${format.format(session.totalIncome)}", color: Colors.green),
                _buildSummaryRow("Total Egresos", "- ${format.format(session.totalExpense)}", color: Colors.red),
                if (isClosed)
                  _buildSummaryRow("Saldo Final", format.format(session.closingBalance!), color: Colors.indigo, isBold: true),
                
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    "DETALLE DE MOVIMIENTOS POR DÍA", 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.1)
                  ),
                ),
                const SizedBox(height: 12),

                // Transactions Logic (Accordion Level 2)
                if (session.transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  _buildDailyAccordions(session.transactions, format),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAccordions(List<CashTransactionModel> transactions, NumberFormat format) {
    final grouped = _groupTransactions(transactions);
    
    return Column(
      children: grouped.entries.map((entry) {
        final dailyTxs = entry.value;
        double dailyIncome = dailyTxs.where((tx) => tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
        double dailyExpense = dailyTxs.where((tx) => !tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            dense: true,
            title: Text(
              entry.key,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dailyIncome > 0)
                  Text("+Q${dailyIncome.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                if (dailyIncome > 0 && dailyExpense > 0) const SizedBox(width: 8),
                if (dailyExpense > 0)
                  Text("-Q${dailyExpense.toStringAsFixed(0)}", style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.indigo),
              ],
            ),
            children: dailyTxs.map((tx) => _buildTransactionItem(tx, format)).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionItem(CashTransactionModel tx, NumberFormat format) {
    final isIncome = tx.isIncome;
    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: isIncome ? Colors.green.shade100 : Colors.red.shade100, width: 3)),
      ),
      child: ListTile(
        dense: true,
        title: Text(
          tx.category.toUpperCase(), 
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: isIncome ? Colors.green.shade700 : Colors.red.shade700)
        ),
        subtitle: Text(
          tx.description ?? "Sin descripción", 
          style: const TextStyle(fontSize: 11, color: Colors.black87)
        ),
        trailing: Text(
          "${isIncome ? '+' : '-'} ${format.format(tx.amount)}",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isIncome ? Colors.green : Colors.red),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isClosed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isClosed ? Colors.grey.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isClosed ? "CERRADA" : "ACTIVA",
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: isClosed ? Colors.grey.shade700 : Colors.green.shade700,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
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
          Icon(Icons.history_toggle_off_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No hay historial de cajas registrado.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
  void _showRenameDialog(CashBoxModel session) {
    final controller = TextEditingController(text: session.name);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Renombrar Caja Histórica"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Nuevo nombre",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != session.name) {
                  setState(() => isSaving = true);
                  await context.read<CashProvider>().updateCashBoxName(session.id, newName);
                  if (context.mounted) Navigator.pop(context);
                } else if (newName == session.name) {
                  Navigator.pop(context);
                }
              },
              child: isSaving 
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("GUARDAR"),
            ),
          ],
        ),
      ),
    );
  }
}
