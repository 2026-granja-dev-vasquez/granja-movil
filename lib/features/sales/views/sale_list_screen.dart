import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sale_provider.dart';
import '../providers/customer_provider.dart';
import '../models/sale_model.dart';
import 'sale_detail_screen.dart';

class SaleListScreen extends StatefulWidget {
  final int? customerId;
  final String? customerName;

  const SaleListScreen({super.key, this.customerId, this.customerName});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  int? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.customerId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
      context.read<CustomerProvider>().fetchCustomers();
    });
  }

  void _applyFilters() {
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
    context.read<SaleProvider>().fetchSales(
          customerId: _selectedCustomerId,
          startDate: startStr,
          endDate: endStr,
        );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'GT'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final saleProvider = context.watch<SaleProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    final DateFormat dayFormatter = DateFormat('EEEE, d MMMM yyyy', 'es_GT');

    // Agrupar por fecha (solo el día)
    final Map<String, List<SaleModel>> groupedSales = {};
    for (var sale in saleProvider.sales) {
      final dateStr = DateFormat('yyyy-MM-dd').format(sale.date);
      if (!groupedSales.containsKey(dateStr)) {
        groupedSales[dateStr] = [];
      }
      groupedSales[dateStr]!.add(sale);
    }

    final sortedDates = groupedSales.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Diario de Ventas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _applyFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // BARRA DE FILTROS
          _buildFilterBar(customerProvider),

          // LISTADO DE RESUMEN
          Expanded(
            child: saleProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sortedDates.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final dateKey = sortedDates[index];
                          final daySales = groupedSales[dateKey]!;
                          final date = DateTime.parse(dateKey);

                          return _buildDailySummaryCard(
                            date,
                            daySales,
                            dayFormatter,
                            formatter,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(CustomerProvider customerProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range, size: 20),
                  label: Text(
                    "${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedCustomerId,
                      isExpanded: true,
                      hint: const Text("Filtrar Cliente", style: TextStyle(fontSize: 12)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("Todos los Clientes", style: TextStyle(fontSize: 12))),
                        ...customerProvider.customers.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name, style: const TextStyle(fontSize: 12)),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedCustomerId = val);
                        _applyFilters();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedCustomerId != null || DateFormat('yyyy-MM-dd').format(_startDate) != DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 7))))
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCustomerId = null;
                    _startDate = DateTime.now().subtract(const Duration(days: 7));
                    _endDate = DateTime.now();
                  });
                  _applyFilters();
                },
                child: const Text("Limpiar filtros", style: TextStyle(color: Colors.blue, fontSize: 12, decoration: TextDecoration.underline)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard(DateTime date, List<SaleModel> daySales, DateFormat dayFormatter, DateFormat formatter) {
    // Calcular agregados por tamaño para el día
    final Map<String, int> aggregates = {};
    double totalDayMoney = 0;
    for (var sale in daySales) {
      totalDayMoney += sale.totalAmount;
      for (var item in sale.items) {
        final sizeName = item.productSize?.name ?? "Desconocido";
        aggregates[sizeName] = (aggregates[sizeName] ?? 0) + item.quantity;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
      child: Column(
        children: [
          // Header del día
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dayFormatter.format(date).toLowerCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Q${totalDayMoney.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Resumen de Cantidades
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("PRODUCTOS VENDIDOS:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: aggregates.length,
                  itemBuilder: (context, index) {
                    final entry = aggregates.entries.elementAt(index);
                    return _buildSizeSummaryItem(entry.key, entry.value);
                  },
                ),
              ],
            ),
          ),

          // Botón de expansión / detalles
          const Divider(height: 1),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text("Ver transacciones individuales", style: TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w500)),
              children: daySales.map((sale) => _buildMiniSaleTile(sale, formatter)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSummaryItem(String name, int units) {
    final cartons = units ~/ 30;
    final leftover = units % 30;
    
    String display = "";
    if (cartons > 0 && leftover > 0) {
      display = "$cartons c. y $leftover u.";
    } else if (cartons > 0) {
      display = "$cartons cartones";
    } else {
      display = "$units u.";
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
          Text(display, style: const TextStyle(fontSize: 11, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildMiniSaleTile(SaleModel sale, DateFormat formatter) {
    final bool isPaid = sale.status == SaleStatus.paid;
    
    // Crear un resumen corto de los productos comprados
    String itemsSummary = sale.items.map((i) {
      final size = i.productSize?.name ?? "?";
      final cartons = i.quantity ~/ 30;
      final units = i.quantity % 30;
      if (cartons > 0 && units > 0) return "$size ($cartons c. $units u.)";
      if (cartons > 0) return "$size ($cartons c.)";
      return "$size ($units u.)";
    }).join(", ");

    if (itemsSummary.length > 35) {
      itemsSummary = "${itemsSummary.substring(0, 32)}...";
    }

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        isPaid ? Icons.check_circle_outline : Icons.access_time, 
        size: 14, 
        color: isPaid ? Colors.green : Colors.orange
      ),
      title: Text(
        sale.customer?.name ?? "Consumidor Final", 
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)
      ),
      subtitle: Text(
        itemsSummary, 
        style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500)
      ),
      trailing: Text(
        "Q${sale.totalAmount.toStringAsFixed(2)}", 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SaleDetailScreen(sale: sale),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No hay ventas para los filtros seleccionados.", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
