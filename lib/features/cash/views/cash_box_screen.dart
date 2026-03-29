import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cash_provider.dart';
import 'cash_history_screen.dart';

class CashBoxScreen extends StatefulWidget {
  const CashBoxScreen({super.key});

  @override
  State<CashBoxScreen> createState() => _CashBoxScreenState();
}

class _CashBoxScreenState extends State<CashBoxScreen> {
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSavingBox = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashProvider>().fetchActiveBox();

      // Sugerir nombre del mes actual
      final now = DateTime.now();
      final monthName = DateFormat('MMMM yyyy', 'es_GT').format(now);
      _nameController.text =
          "Caja ${monthName.substring(0, 1).toUpperCase()}${monthName.substring(1)}";
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<dynamic>> _groupTransactions(List<dynamic> transactions) {
    final Map<String, List<dynamic>> groups = {};
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));

    // Filter first
    final filtered = transactions.where((tx) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final dateStr = DateFormat(
        'dd MMM',
        'es_GT',
      ).format(tx.createdAt).toLowerCase();
      return tx.description?.toLowerCase().contains(query) == true ||
          tx.category.toLowerCase().contains(query) ||
          tx.amount.toString().contains(query) ||
          dateStr.contains(query);
    }).toList();

    // Grouping
    for (var tx in filtered.reversed) {
      final dateKey = DateFormat('yyyy-MM-dd').format(tx.createdAt);
      String label;
      if (dateKey == todayStr) {
        label =
            "HOY - ${DateFormat('dd MMM').format(tx.createdAt).toUpperCase()}";
      } else if (dateKey == yesterdayStr) {
        label =
            "AYER - ${DateFormat('dd MMM').format(tx.createdAt).toUpperCase()}";
      } else {
        final dayName = DateFormat('EEEE, d MMM', 'es_GT').format(tx.createdAt);
        label =
            "${dayName.substring(0, 1).toUpperCase()}${dayName.substring(1).toUpperCase()}";
      }

      if (groups[label] == null) groups[label] = [];
      groups[label]!.add(tx);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final cashProvider = context.watch<CashProvider>();
    final activeBox = cashProvider.activeBox;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          activeBox != null
              ? (activeBox.name ?? 'Caja Activa')
              : 'Gestión de Caja',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CashHistoryScreen()),
            ),
          ),
        ],
      ),
      body: cashProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeBox == null
          ? _buildOpenBoxView()
          : _buildActiveBoxView(activeBox),
    );
  }

  Widget _buildOpenBoxView() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: Colors.indigo,
              ),
              const SizedBox(height: 24),
              const Text(
                "La caja está cerrada",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Se requiere abrir una sesión mensual para registrar movimientos.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Sesión',
                  hintText: 'Ej: Caja Marzo 2026',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saldo Inicial (Q)',
                  border: OutlineInputBorder(),
                  prefixText: 'Q ',
                  prefixIcon: Icon(Icons.money),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSavingBox ? null : _handleOpenBox,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSavingBox 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("ABRIR CAJA MENSUAL"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleOpenBox() async {
    if (_isSavingBox) return;
    
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa un nombre para la caja.")),
      );
      return;
    }

    setState(() => _isSavingBox = true);

    try {
      await context.read<CashProvider>().openBox(name, amount);
      if (mounted) _amountController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSavingBox = false);
    }
  }

  Widget _buildActiveBoxView(dynamic box) {
    final currencyFormat = NumberFormat.currency(symbol: 'Q');
    final groupedTransactions = _groupTransactions(box.transactions);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de Balance
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade800, Colors.indigo.shade500],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "SALDO ACTUAL",
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(box.currentBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      "Ingresos",
                      box.totalIncome,
                      Colors.greenAccent,
                    ),
                    _buildSummaryItem(
                      "Egresos",
                      box.totalExpense,
                      Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Acciones Rápidas
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  "Ingreso",
                  Icons.add_circle_outline,
                  Colors.green,
                  () => _showTransactionDialog('income'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  "Egreso",
                  Icons.remove_circle_outline,
                  Colors.red,
                  () => _showTransactionDialog('expense'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botón Cerrar Caja REUBICADO
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _showConfirmClose,
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text(
                "CERRAR CAJA Y CUADRAR",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Buscador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por fecha o descripción...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                border: InputBorder.none,
                icon: Icon(Icons.search, size: 20, color: Colors.grey),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          const SizedBox(height: 24),

          // Ledger Dinámico Grouped con Acordeones
          if (groupedTransactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  "No se encontraron movimientos",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...groupedTransactions.entries.map((entry) {
              final dailyTxs = entry.value;
              double dailyIncome = dailyTxs
                  .where((tx) => tx.type == 'income')
                  .fold(0.0, (sum, tx) => sum + tx.amount);
              double dailyExpense = dailyTxs
                  .where((tx) => tx.type == 'expense')
                  .fold(0.0, (sum, tx) => sum + tx.amount);

              return Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  title: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      letterSpacing: 1.1,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dailyIncome > 0)
                        Text(
                          "+Q${dailyIncome.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (dailyIncome > 0 && dailyExpense > 0)
                        const SizedBox(width: 8),
                      if (dailyExpense > 0)
                        Text(
                          "-Q${dailyExpense.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                  childrenPadding: EdgeInsets.zero,
                  children: dailyTxs
                      .map((tx) => _buildTransactionTile(tx, currencyFormat))
                      .toList(),
                ),
              );
            }).toList(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          "Q${amount.toStringAsFixed(2)}",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withOpacity(0.2)),
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildTransactionTile(dynamic tx, NumberFormat format) {
    final isIncome = tx.type == 'income';
    final day = DateFormat('dd').format(tx.createdAt);
    final month = DateFormat('MMM').format(tx.createdAt).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge de Fecha
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.indigo,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    month,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: isIncome
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              radius: 16,
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green : Colors.red,
                size: 14,
              ),
            ),
          ],
        ),
        title: Text(
          tx.category.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            tx.description ?? "Sin descripción",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
        trailing: Text(
          "${isIncome ? '+' : '-'} ${format.format(tx.amount)}",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: isIncome ? Colors.green.shade600 : Colors.red.shade600,
          ),
        ),
      ),
    );
  }

  void _showTransactionDialog(String type) {
    bool _isSavingTx = false;
    final descController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String category = type == 'income' ? 'Ingreso Manual' : 'Gasto General';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            type == 'income' ? 'Registrar Ingreso' : 'Registrar Egreso',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto (Q)',
                  prefixText: 'Q ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Motivo',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, size: 20),
                title: const Text(
                  "Fecha del movimiento",
                  style: TextStyle(fontSize: 12),
                ),
                subtitle: Text(
                  DateFormat('dd / MMM / yyyy').format(selectedDate),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2025),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isSavingTx ? null : () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              onPressed: _isSavingTx ? null : () async {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount > 0) {
                  setDialogState(() => _isSavingTx = true);
                  await context.read<CashProvider>().addTransaction(
                    type,
                    amount,
                    category,
                    descController.text.isEmpty
                        ? (type == 'income' ? 'Ingreso' : 'Egreso')
                        : descController.text,
                    selectedDate,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: _isSavingTx 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("REGISTRAR"),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmClose() {
    bool _isSavingClose = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("¿Cerrar Caja?"),
          content: const Text(
            "Se guardará el saldo final y no podrás agregar más movimientos hasta abrir una nueva caja.",
          ),
          actions: [
            TextButton(
              onPressed: _isSavingClose ? null : () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              onPressed: _isSavingClose ? null : () async {
                setState(() => _isSavingClose = true);
                await context.read<CashProvider>().closeBox();
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: _isSavingClose 
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("CERRAR"),
            ),
          ],
        ),
      ),
    );
  }
}
