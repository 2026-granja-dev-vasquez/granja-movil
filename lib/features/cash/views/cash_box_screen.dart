import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cash_provider.dart';
import '../models/cash_model.dart';
import '../../auth/providers/auth_provider.dart';
import 'cash_history_screen.dart';

class CashBoxScreen extends StatefulWidget {
  const CashBoxScreen({super.key});

  @override
  State<CashBoxScreen> createState() => _CashBoxScreenState();
}

class _CashBoxScreenState extends State<CashBoxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSavingBox = false;

  // Filter state
  String _txFilter = 'all'; // 'all' | 'income' | 'expense'
  String? _rubroFilter; // null = todos

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashProvider>().fetchActiveBox();
      context.read<CashProvider>().fetchExpenseCategories();
      final now = DateTime.now();
      final monthName = DateFormat('MMMM yyyy', 'es_GT').format(now);
      _nameController.text =
          'Caja ${monthName.substring(0, 1).toUpperCase()}${monthName.substring(1)}';
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────── HELPERS ──────────────────────────────────────────────────

  Map<String, List<CashTransactionModel>> _groupTransactions(
      List<CashTransactionModel> transactions) {
    final Map<String, List<CashTransactionModel>> groups = {};
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    // Apply filters
    List<CashTransactionModel> filtered = transactions.where((tx) {
      if (_txFilter == 'income' && tx.type != 'income') return false;
      if (_txFilter == 'expense' && tx.type != 'expense') return false;
      if (_txFilter == 'expense' &&
          _rubroFilter != null &&
          tx.category != _rubroFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final dateStr =
            DateFormat('dd MMM', 'es_GT').format(tx.createdAt).toLowerCase();
        return tx.description?.toLowerCase().contains(q) == true ||
            tx.category.toLowerCase().contains(q) ||
            tx.amount.toString().contains(q) ||
            dateStr.contains(q);
      }
      return true;
    }).toList();

    for (var tx in filtered.reversed) {
      final dateKey = DateFormat('yyyy-MM-dd').format(tx.createdAt);
      String label;
      if (dateKey == todayStr) {
        label =
            'HOY - ${DateFormat('dd MMM').format(tx.createdAt).toUpperCase()}';
      } else if (dateKey == yesterdayStr) {
        label =
            'AYER - ${DateFormat('dd MMM').format(tx.createdAt).toUpperCase()}';
      } else {
        final dayName =
            DateFormat('EEEE, d MMM', 'es_GT').format(tx.createdAt);
        label =
            '${dayName.substring(0, 1).toUpperCase()}${dayName.substring(1).toUpperCase()}';
      }
      if (groups[label] == null) groups[label] = [];
      groups[label]!.add(tx);
    }
    return groups;
  }

  // ─────────────── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cashProvider = context.watch<CashProvider>();
    final activeBox = cashProvider.activeBox;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            activeBox != null
                ? (activeBox.name ?? 'Caja Activa')
                : 'Gestión de Caja',
          ),
          actions: [
            if (activeBox != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Renombrar Caja',
                onPressed: () => _showRenameDialog(activeBox),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: 'Caja Activa'),
              Tab(icon: Icon(Icons.history), text: 'Historial'),
              Tab(icon: Icon(Icons.label_outline), text: 'Rubros'),
            ],
          ),
        ),
        body: cashProvider.isLoading && activeBox == null && cashProvider.expenseCategories.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // ── TAB 1: Caja Activa ──────────────────────────────────
                  activeBox == null
                      ? _buildOpenBoxView()
                      : _buildActiveBoxView(activeBox),

                  // ── TAB 2: Historial ────────────────────────────────────
                  const CashHistoryScreen(isEmbedded: true),

                  // ── TAB 3: Rubros ─────────────────────────────────────
                  _buildRubrosTab(cashProvider),
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — CAJA ACTIVA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOpenBoxView() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 80, color: Colors.indigo),
              const SizedBox(height: 24),
              const Text('La caja está cerrada',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Se requiere abrir una sesión mensual para registrar movimientos.',
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
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSavingBox
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ABRIR CAJA MENSUAL'),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ingresa un nombre para la caja.')));
      return;
    }
    setState(() => _isSavingBox = true);
    try {
      await context.read<CashProvider>().openBox(name, amount);
      if (mounted) _amountController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSavingBox = false);
    }
  }

  Widget _buildActiveBoxView(CashBoxModel box) {
    final currencyFormat = NumberFormat.currency(symbol: 'Q');
    final groupedTransactions = _groupTransactions(box.transactions);
    final cashProvider = context.watch<CashProvider>();
    final categories = cashProvider.expenseCategories;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Balance Card ──────────────────────────────────────────────────
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
                const Text('SALDO ACTUAL',
                    style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                        fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(box.currentBalance),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Ingresos', box.totalIncome, Colors.greenAccent),
                    _buildSummaryItem('Egresos', box.totalExpense, Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Acciones Rápidas ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildActionButton('Ingreso', Icons.add_circle_outline,
                    Colors.green, () => _showTransactionDialog('income')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton('Egreso', Icons.remove_circle_outline,
                    Colors.red, () => _showTransactionDialog('expense')),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Cerrar Caja ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _showConfirmClose,
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('CERRAR CAJA Y CUADRAR',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Filtros Todos / Ingresos / Egresos ────────────────────────────
          _buildFilterChips(categories),

          const SizedBox(height: 16),

          // ── Buscador ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03), blurRadius: 10)
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

          // ── Ledger Agrupado ──────────────────────────────────────────────
          if (groupedTransactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No se encontraron movimientos',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...groupedTransactions.entries.map((entry) {
              final dailyTxs = entry.value;
              // Excluir anulados del cálculo del encabezado
              final activeTxs = dailyTxs.where((tx) => !tx.isVoided).toList();
              double dailyIncome = activeTxs
                  .where((tx) => tx.type == 'income')
                  .fold(0.0, (sum, tx) => sum + tx.amount);
              double dailyExpense = activeTxs
                  .where((tx) => tx.type == 'expense')
                  .fold(0.0, (sum, tx) => sum + tx.amount);

              return Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  title: Text(entry.key,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                          letterSpacing: 1.1)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dailyIncome > 0)
                        Text('+Q${dailyIncome.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      if (dailyIncome > 0 && dailyExpense > 0)
                        const SizedBox(width: 8),
                      if (dailyExpense > 0)
                        Text('-Q${dailyExpense.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 20, color: Colors.indigo),
                    ],
                  ),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                  childrenPadding: EdgeInsets.zero,
                  children: dailyTxs
                      .map((tx) => _buildTransactionTile(tx, currencyFormat))
                      .toList(),
                ),
              );
            }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<ExpenseCategoryModel> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nivel 1: Todos / Ingresos / Egresos
        Wrap(
          spacing: 8,
          children: [
            _filterChip('Todos', 'all', Colors.indigo),
            _filterChip('Ingresos', 'income', Colors.green),
            _filterChip('Egresos', 'expense', Colors.red),
          ],
        ),
        // Nivel 2: Sub-rubros (solo cuando filter == expense)
        if (_txFilter == 'expense' && categories.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              ChoiceChip(
                label: const Text('Todos los rubros',
                    style: TextStyle(fontSize: 11)),
                selected: _rubroFilter == null,
                selectedColor: Colors.red.shade100,
                onSelected: (_) => setState(() => _rubroFilter = null),
              ),
              ...categories.map((cat) => ChoiceChip(
                    label: Text(cat.name,
                        style: const TextStyle(fontSize: 11)),
                    selected: _rubroFilter == cat.name,
                    selectedColor: Colors.red.shade100,
                    onSelected: (_) => setState(() =>
                        _rubroFilter =
                            _rubroFilter == cat.name ? null : cat.name),
                  )),
            ],
          ),
        ],
      ],
    );
  }

  Widget _filterChip(String label, String value, Color color) {
    final selected = _txFilter == value;
    return FilterChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : color)),
      selected: selected,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.1),
      checkmarkColor: Colors.white,
      onSelected: (_) => setState(() {
        _txFilter = value;
        _rubroFilter = null;
      }),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text('Q${amount.toStringAsFixed(2)}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
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

  Widget _buildTransactionTile(
      CashTransactionModel tx, NumberFormat format) {
    final isIncome = tx.type == 'income';
    final isVoided = tx.isVoided;
    final day = DateFormat('dd').format(tx.createdAt);
    final month = DateFormat('MMM').format(tx.createdAt).toUpperCase();
    final isAdmin =
        context.read<AuthProvider>().user?.role == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isVoided ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isVoided ? Colors.grey.shade200 : Colors.grey.shade100),
      ),
      child: Opacity(
        opacity: isVoided ? 0.6 : 1.0,
        child: Column(
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isVoided
                          ? Colors.grey.shade200
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(day,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: isVoided
                                  ? Colors.grey.shade600
                                  : Colors.indigo,
                              height: 1.1,
                              decoration: isVoided
                                  ? TextDecoration.lineThrough
                                  : null,
                            )),
                        Text(month,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: isVoided
                        ? Colors.grey.shade200
                        : (isIncome
                            ? Colors.green.shade50
                            : Colors.red.shade50),
                    radius: 16,
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isVoided
                          ? Colors.grey
                          : (isIncome ? Colors.green : Colors.red),
                      size: 14,
                    ),
                  ),
                ],
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      tx.category.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isVoided
                            ? Colors.grey
                            : (isIncome
                                ? Colors.green.shade700
                                : Colors.red.shade700),
                        letterSpacing: 0.5,
                        decoration:
                            isVoided ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (isVoided)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('ANULADO',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  tx.description ?? 'Sin descripción',
                  style: TextStyle(
                    fontSize: 12,
                    color: isVoided ? Colors.grey : Colors.black87,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    decoration:
                        isVoided ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'} ${format.format(tx.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: isVoided
                          ? Colors.grey
                          : (isIncome
                              ? Colors.green.shade600
                              : Colors.red.shade600),
                      decoration:
                          isVoided ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (!isIncome && !isVoided) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_note,
                          size: 18, color: Colors.blueGrey),
                      onPressed: () => _showEditRubroDialog(tx),
                      tooltip: 'Cambiar rubro',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                  if (isAdmin && !isVoided) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined,
                          size: 20, color: Colors.redAccent),
                      onPressed: () => _showVoidDialog(tx),
                      tooltip: 'Anular',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
            ),
            if (isVoided && tx.voidReason != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16)),
                ),
                child: Text(
                  'Motivo de anulación: ${tx.voidReason}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────── DIALOGS ──────────────────────────────────────────────────

  void _showTransactionDialog(String type) {
    bool isSavingTx = false;
    final descController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final cashProvider = context.read<CashProvider>();
    final categories = cashProvider.expenseCategories;
    // Default category
    String? selectedCategory =
        type == 'income' ? 'Ingreso Manual' : (categories.isNotEmpty ? categories.first.name : null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                type == 'income' ? Icons.add_circle : Icons.remove_circle,
                color: type == 'income' ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              Text(type == 'income' ? 'Registrar Ingreso' : 'Registrar Egreso'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto (Q)',
                    prefixText: 'Q ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Descripción / Motivo',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Selector de Rubro (solo egresos) ────────────────────
                if (type == 'expense') ...[
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Rubro del Egreso',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: categories.map((cat) => DropdownMenuItem(
                      value: cat.name,
                      child: Text(cat.name),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                    hint: const Text('Seleccionar rubro'),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nuevo rubro'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _showCreateCategoryDialog();
                        if (mounted) _showTransactionDialog(type);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Fecha ───────────────────────────────────────────────
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, size: 20),
                  title: const Text('Fecha del movimiento',
                      style: TextStyle(fontSize: 12)),
                  subtitle:
                      Text(DateFormat('dd / MMM / yyyy').format(selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
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
          ),
          actions: [
            TextButton(
              onPressed: isSavingTx ? null : () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    type == 'income' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isSavingTx
                  ? null
                  : () async {
                      final amount =
                          double.tryParse(amountController.text) ?? 0.0;
                      if (amount > 0 && selectedCategory != null) {
                        setDialogState(() => isSavingTx = true);
                        await context.read<CashProvider>().addTransaction(
                              type,
                              amount,
                              selectedCategory!,
                              descController.text.isEmpty
                                  ? (type == 'income' ? 'Ingreso' : 'Egreso')
                                  : descController.text,
                              selectedDate,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } else if (amount > 0 && type == 'expense') {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                           const SnackBar(content: Text('Por favor selecciona un rubro'))
                        );
                      }
                    },
              child: isSavingTx
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('REGISTRAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRubroDialog(CashTransactionModel tx) {
    final cashProvider = context.read<CashProvider>();
    final categories = cashProvider.expenseCategories;
    String? selectedCategory = categories.any((c) => c.name == tx.category) ? tx.category : null;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cambiar Rubro',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Q${tx.amount.toStringAsFixed(2)} — ${tx.description ?? ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Nuevo rubro',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: categories.map((cat) => DropdownMenuItem(
                  value: cat.name,
                  child: Text(cat.name),
                )).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setS(() => selectedCategory = val);
                  }
                },
                hint: const Text('Seleccionar rubro'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCELAR',
                    style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (selectedCategory == null) return;
                      setS(() => isSaving = true);
                      final ok = await context
                          .read<CashProvider>()
                          .updateTransactionCategory(tx.id, selectedCategory!);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? '✅ Rubro actualizado'
                              : '❌ Error al actualizar'),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ));
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoidDialog(CashTransactionModel tx) {
    final reasonController = TextEditingController();
    bool isSaving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Anular Transacción',
              style: TextStyle(fontWeight: FontWeight.w900)),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Motivo de anulación',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCELAR')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (reasonController.text.trim().length < 3) return;
                      setS(() => isSaving = true);
                      try {
                        await context
                            .read<CashProvider>()
                            .voidTransaction(tx.id, reasonController.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())));
                          Navigator.pop(ctx);
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('ANULAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmClose() {
    bool isSavingClose = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('¿Cerrar Caja?'),
          content: const Text(
              'Se guardará el saldo final y no podrás agregar más movimientos hasta abrir una nueva caja.'),
          actions: [
            TextButton(
                onPressed: isSavingClose ? null : () => Navigator.pop(ctx),
                child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: isSavingClose
                  ? null
                  : () async {
                      setS(() => isSavingClose = true);
                      await context.read<CashProvider>().closeBox();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: isSavingClose
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('CERRAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(dynamic box) {
    final controller = TextEditingController(text: box.name);
    bool isSaving = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Renombrar Caja'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
                labelText: 'Nuevo nombre', border: OutlineInputBorder()),
            autofocus: true,
          ),
          actions: [
            TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final newName = controller.text.trim();
                      if (newName.isNotEmpty && newName != box.name) {
                        setS(() => isSaving = true);
                        await context
                            .read<CashProvider>()
                            .updateCashBoxName(box.id, newName);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } else if (newName == box.name) {
                        Navigator.pop(ctx);
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — RUBROS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRubrosTab(CashProvider prov) {
    final categories = prov.expenseCategories;

    return RefreshIndicator(
      onRefresh: () => prov.fetchExpenseCategories(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header informativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.indigo, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Los rubros eliminados se mantienen en el historial de transacciones anteriores.',
                    style: TextStyle(fontSize: 12, color: Colors.indigo),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botón agregar rubro
          OutlinedButton.icon(
            onPressed: _showCreateCategoryDialog,
            icon: const Icon(Icons.add),
            label: const Text('AGREGAR NUEVO RUBRO'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
              side: const BorderSide(color: Colors.indigo),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),

          const SizedBox(height: 20),

          const Text('RUBROS ACTIVOS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  letterSpacing: 1.1)),

          const SizedBox(height: 12),

          if (categories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No hay rubros activos.',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...categories.map((cat) => _buildCategoryTile(cat, prov)),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(ExpenseCategoryModel cat, CashProvider prov) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.label, color: Colors.red.shade300, size: 20),
        ),
        title: Text(cat.name,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Colors.indigo, size: 20),
              onPressed: () => _showRenameCategoryDialog(cat, prov),
              tooltip: 'Renombrar rubro',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDeleteCategory(cat, prov),
              tooltip: 'Eliminar rubro',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameCategoryDialog(ExpenseCategoryModel cat, CashProvider prov) async {
    final ctrl = TextEditingController(text: cat.name);
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Renombrar Rubro',
              style: TextStyle(fontWeight: FontWeight.w900)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nombre del rubro',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCELAR')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = ctrl.text.trim();
                      if (name.isEmpty || name == cat.name) return;
                      setS(() => isSaving = true);
                      final ok = await prov.renameExpenseCategory(cat.id, name);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? '✅ Rubro renombrado a "$name"'
                              : '❌ Error al renombrar rubro'),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ));
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateCategoryDialog() async {
    final ctrl = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nuevo Rubro de Egreso',
              style: TextStyle(fontWeight: FontWeight.w900)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nombre del rubro',
              hintText: 'Ej: Reparaciones',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCELAR')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = ctrl.text.trim();
                      if (name.isEmpty) return;
                      setS(() => isSaving = true);
                      final ok = await context
                          .read<CashProvider>()
                          .createExpenseCategory(name);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? '✅ Rubro "$name" creado'
                              : '❌ Error al crear rubro'),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ));
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(ExpenseCategoryModel cat, CashProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar Rubro?',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
            'El rubro "${cat.name}" se eliminará de la lista, pero las transacciones anteriores lo seguirán mostrando en el historial.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final ok = await prov.deleteExpenseCategory(cat.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? '✅ Rubro eliminado'
                      : '❌ No se pudo eliminar'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('SÍ, ELIMINAR'),
          ),
        ],
      ),
    );
  }
}
