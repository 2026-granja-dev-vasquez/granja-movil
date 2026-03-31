import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/production_provider.dart';
import '../../batches/providers/batch_provider.dart';
import '../../products/providers/product_provider.dart';
import 'add_batch_collection_screen.dart';
import 'add_sorting_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class DailyProductionScreen extends StatefulWidget {
  const DailyProductionScreen({super.key});

  @override
  State<DailyProductionScreen> createState() => _DailyProductionScreenState();
}

class _DailyProductionScreenState extends State<DailyProductionScreen> {
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductionProvider>().fetchDailyData();
      context.read<BatchProvider>().fetchBatches();
      context.read<ProductProvider>().fetchSizes();
    });
  }

  Future<void> _selectSearchRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
      locale: const Locale('es', 'GT'),
      initialEntryMode:
          DatePickerEntryMode.calendar, // VISTA DE CALENDARIO DIRECTA
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedRange = picked);
      if (mounted) {
        context.read<ProductionProvider>().fetchSummaryReport(
          picked.start,
          picked.end,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Producción Diaria'),
          actions: [
            if (_selectedRange != null)
              IconButton(
                icon: const Icon(Icons.history_toggle_off),
                tooltip: 'Regresar a Vista Diaria',
                onPressed: () {
                  setState(() => _selectedRange = null);
                  context.read<ProductionProvider>().fetchDailyData();
                },
              ),
            IconButton(
              icon: const Icon(Icons.date_range),
              tooltip: 'Buscar Rango de Fechas',
              onPressed: _selectSearchRange,
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.assessment), text: 'Resumen Diario'),
              Tab(icon: Icon(Icons.shopping_basket), text: 'Totales por Lote'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Estadísticas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const DailyProductionComparisonTab(),
            RawCollectionsTab(isFiltered: _selectedRange != null),
            const ProductionStatisticsTab(),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'btn1',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddBatchCollectionScreen(),
                ),
              ).then((_) {
                if (mounted) context.read<ProductionProvider>().fetchDailyData();
              }),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Paso 1: Recoger Huevos'),
              backgroundColor: Colors.blue,
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'btn2',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSortingScreen()),
              ).then((_) {
                if (mounted) context.read<ProductionProvider>().fetchDailyData();
              }),
              icon: const Icon(Icons.grading),
              label: const Text('Paso 2: Limpieza y Clas.'),
              backgroundColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class DailyProductionComparisonTab extends StatelessWidget {
  const DailyProductionComparisonTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                "Error al cargar datos:\n${provider.errorMessage}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              ElevatedButton(
                onPressed: () => provider.fetchDailyData(),
                child: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.dailyReports.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.fetchDailyData(),
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(
              child: Text(
                "Sin producción registrada en este periodo.\n(Mostrando últimos 3 días)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchDailyData(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount:
            provider.dailyReports.length + 1, // +1 para el Header de Stock
        itemBuilder: (context, index) {
          if (index == 0) {
            return const CurrentStockHeader();
          }

          final dayReport = provider.dailyReports[index - 1];
          final dateStr = DateFormat(
            "EEEE d 'de' MMMM",
            'es',
          ).format(dayReport.date);
          final fullDateStr = dateStr[0].toUpperCase() + dateStr.substring(1);

          final bool isEmpty = dayReport.report.isEmpty;

          return Card(
            margin: const EdgeInsets.only(bottom: 24),
            elevation: isEmpty ? 1 : 4,
            color: isEmpty ? Colors.grey.shade50 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isEmpty
                  ? BorderSide(color: Colors.grey.shade300)
                  : BorderSide.none,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera de la Tarjeta Diaria
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isEmpty 
                        ? [Colors.grey.shade400, Colors.grey.shade500] 
                        : [Colors.indigo.shade700, Colors.indigo.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          fullDateStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Total: ${dayReport.report.fold(0, (sum, i) => sum + i.totalUnits)} huevos",
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.egg_outlined,
                            color: Colors.grey,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Sin producción registrada :(",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Resumen de Quebrados
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Quebrados: ${dayReport.totalDamaged}",
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (dayReport.totalPending > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.hourglass_empty,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Pendientes al cierre: ${dayReport.totalPending}",
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Detalle por Tamaños
                  ...dayReport.report.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.egg, color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.productSize,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            item.formatted,
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class RawCollectionsTab extends StatelessWidget {
  final bool isFiltered;
  const RawCollectionsTab({super.key, required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.batchSummaries.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.fetchDailyData(),
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(
              child: Text(
                "No hay registros de recolecta en este periodo.\n(Mostrando últimos 3 días)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchDailyData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.batchSummaries.length,
        itemBuilder: (context, index) {
          final dayReport = provider.batchSummaries[index];
          final dateStr = DateFormat(
            "EEEE d 'de' MMMM",
            'es',
          ).format(dayReport.date);
          final fullDateStr = dateStr[0].toUpperCase() + dateStr.substring(1);

          final bool isEmpty = dayReport.report.isEmpty;

          return Card(
            margin: const EdgeInsets.only(bottom: 24),
            elevation: isEmpty ? 1 : 4,
            color: isEmpty ? Colors.grey.shade50 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isEmpty
                  ? BorderSide(color: Colors.grey.shade300)
                  : BorderSide.none,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera de la Tarjeta (Tema Verde para Galeras)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isEmpty 
                        ? [Colors.grey.shade400, Colors.grey.shade500] 
                        : [Colors.teal.shade700, Colors.teal.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          fullDateStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Total: ${dayReport.report.fold(0, (sum, i) => sum + i.totalUnits)} huevos",
                            style: TextStyle(
                              color: Colors.teal.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.house_siding_rounded,
                            color: Colors.grey,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Sin recolecta registrada de galeras :(",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  const SizedBox(height: 8),
                  // Detalle por Lote
                  ...dayReport.report.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.teal,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.batchName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            item.formatted,
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}



class CurrentStockHeader extends StatelessWidget {
  const CurrentStockHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final stock = provider.inventoryStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade900, Colors.black87],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "STOCK DISPONIBLE ( CARTONES )",
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.inventory_2_outlined, color: Colors.amber, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stock.map((item) {
              final cartons = item.cartons;
              final units = item.leftoverUnits;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$cartons",
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "cart.",
                          style: TextStyle(color: Colors.amber, fontSize: 10),
                        ),
                        if (units > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            "+$units",
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class ProductionStatisticsTab extends StatelessWidget {
  const ProductionStatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final data = provider.adaptiveChartData;

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: () => provider.fetchDailyData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SELECTORES DE FILTRO ---
            _buildFilters(provider),
            const SizedBox(height: 20),

            // --- SELECTOR DE COMPARATIVA PERSONALIZADA ---
            if (provider.selectedStatRange == StatRange.comparative)
              _buildMonthVsSelector(context, provider),

            const SizedBox(height: 20),

            // --- GRÁFICA ADAPTATIVA ---
            if (data.isEmpty)
              _buildEmptyState()
            else ...[
              _buildMainChart(provider, data),
              const SizedBox(height: 24),
              
              // --- ANÁLISIS DE TENDENCIA (PROFESIONAL) ---
              _buildTrendAnalysis(provider),
              const SizedBox(height: 24),

              // --- DESGLOSE POR CATEGORÍAS ---
              _buildCategoryBreakdown(provider),
              const SizedBox(height: 24),

              // --- COMPARATIVA MENSUAL ---
              if (provider.selectedStatRange == StatRange.comparative || provider.selectedStatRange == StatRange.month)
                _buildMonthlyComparison(provider),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthVsSelector(BuildContext context, ProductionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        children: [
          const Text(
            "COMPARA DOS PERIODOS",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _monthPickerButton(
                context, 
                provider.compareDate1, 
                (date) => provider.setCompareDates(date, provider.compareDate2)
              ),
              const Icon(Icons.compare_arrows_rounded, color: Colors.orange),
              _monthPickerButton(
                context, 
                provider.compareDate2, 
                (date) => provider.setCompareDates(provider.compareDate1, date)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthPickerButton(BuildContext context, DateTime date, Function(DateTime) onSelected) {
    return InkWell(
      onTap: () => _showMonthYearPicker(context, date, onSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
        ),
        child: Column(
          children: [
            Text(
              DateFormat('MMMM', 'es').format(date).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
            ),
            Text(
              "${date.year}",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context, DateTime initialDate, Function(DateTime) onSelected) {
    int selectedYear = initialDate.year;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Seleccionar Mes y Año", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selector de Año
                    DropdownButton<int>(
                      value: selectedYear,
                      isExpanded: true,
                      items: List.generate(10, (index) => DateTime.now().year - index)
                          .map((year) => DropdownMenuItem(value: year, child: Text("$year")))
                          .toList(),
                      onChanged: (val) => setState(() => selectedYear = val!),
                    ),
                    const SizedBox(height: 16),
                    // Grid de Meses
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (index) {
                        final monthDate = DateTime(selectedYear, index + 1);
                        final monthStr = DateFormat('MMM', 'es').format(monthDate);
                        return InkWell(
                          onTap: () {
                            onSelected(DateTime(selectedYear, index + 1, 1));
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(monthStr.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilters(ProductionProvider provider) {
    return Column(
      children: [
        // Rango de Tiempo
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(
                label: "7 Días",
                isSelected: provider.selectedStatRange == StatRange.week,
                onSelected: (_) => provider.setStatRange(StatRange.week),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: "Este Mes",
                isSelected: provider.selectedStatRange == StatRange.month,
                onSelected: (_) => provider.setStatRange(StatRange.month),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: "Comparativa",
                isSelected: provider.selectedStatRange == StatRange.comparative,
                onSelected: (_) => provider.setStatRange(StatRange.comparative),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tipo de Dato
        Row(
          children: [
            Expanded(
              child: _typeButton(
                label: "Por Lotes",
                icon: Icons.house_siding_rounded,
                isSelected: provider.selectedStatType == StatType.batch,
                onTap: () => provider.setStatType(StatType.batch),
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _typeButton(
                label: "Producción",
                icon: Icons.inventory_2_rounded,
                isSelected: provider.selectedStatType == StatType.production,
                onTap: () => provider.setStatType(StatType.production),
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _filterChip({required String label, required bool isSelected, required Function(bool) onSelected}) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: Colors.orange.shade100,
      labelStyle: TextStyle(color: isSelected ? Colors.orange.shade900 : Colors.grey.shade700),
    );
  }

  Widget _typeButton({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap, required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainChart(ProductionProvider provider, List<Map<String, dynamic>> data) {
    final categories = provider.activeCategories;
    final colors = [Colors.teal, Colors.indigo, Colors.orange, Colors.purple, Colors.blue, Colors.green, Colors.pink, Colors.brown];

    return Column(
      children: [
        _buildStatCard(
          title: "HISTOGRAMA DE RENDIMIENTO",
          subtitle: provider.selectedStatRange == StatRange.month ? "Vista agrupada por semanas" : "Detalle diario",
          child: SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          if (provider.selectedStatRange == StatRange.month) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(data[index]['label'] ?? '', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                            );
                          }
                          final date = data[index]['date'] as DateTime;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: List.generate(categories.length, (catIdx) {
                  final category = categories[catIdx];
                  final color = colors[catIdx % colors.length];
                  
                  return LineChartBarData(
                    spots: List.generate(data.length, (i) {
                      final breakdown = data[i]['breakdown'] as Map<String, int>;
                      return FlSpot(i.toDouble(), (breakdown[category] ?? 0).toDouble());
                    }),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // LEYENDA TIPO CHIPS
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: List.generate(categories.length, (index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors[index % colors.length].withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors[index % colors.length].withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: colors[index % colors.length], shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(categories[index], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis(ProductionProvider provider) {
    final data = provider.adaptiveChartData;
    if (data.length < 2 && provider.selectedStatRange != StatRange.comparative) return const SizedBox();

    String title = "Análisis de Producción";
    String description = "";
    bool isUp = true;
    IconData icon = Icons.auto_graph_rounded;

    if (provider.selectedStatRange == StatRange.comparative) {
      final comp = provider.customMonthlyComparison;
      final t1 = comp['total1'] as int;
      final t2 = comp['total2'] as int;
      final m1 = comp['month1'] as String;
      final m2 = comp['month2'] as String;
      
      final diff = t1 - t2;
      isUp = diff >= 0;
      title = isUp ? "Crecimiento detectado" : "Baja detectada";
      description = "En $m1 la producción es de $t1 cartones, lo cual es ${isUp ? 'mayor' : 'menor'} que en $m2 ($t2 cartones).";
      icon = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    } else {
      final last = data.last['total'] as int;
      final prev = data[data.length - 2]['total'] as int;
      final diff = last - prev;
      isUp = diff >= 0;
      title = isUp ? "¡Va muy bien!" : "Bajada detectada";
      description = isUp 
          ? "La producción ha subido ${diff.abs()} cartones respecto al periodo anterior."
          : "Se registra una baja de ${diff.abs()} cartones. Revisa el estado de las aves.";
      icon = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isUp ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUp ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: isUp ? Colors.green.shade700 : Colors.red.shade700, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isUp ? Colors.green.shade900 : Colors.red.shade900),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: isUp ? Colors.green.shade800 : Colors.red.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyComparison(ProductionProvider provider) {
    final comp = provider.customMonthlyComparison;
    final val1 = comp['total1'] ?? 0;
    final val2 = comp['total2'] ?? 0;
    final m1 = comp['month1'] ?? "";
    final m2 = comp['month2'] ?? "";
    
    final diff = val1 - val2;
    final isUp = diff >= 0;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("COMPARATIVA DE PERIODOS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.blueGrey)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _monthStat(m2, "$val2", Colors.grey),
                Container(height: 40, width: 1, color: Colors.grey.shade200),
                _monthStat(m1, "$val1", isUp ? Colors.teal : Colors.redAccent, showIcon: true, isUp: isUp),
              ],
            ),
            if (val2 > 0) ...[
              const Divider(height: 32),
              Text(
                isUp 
                  ? "Vas un ${((diff/val2)*100).toStringAsFixed(1)}% mejor que en $m2 ✨"
                  : "Estás un ${((diff.abs()/val2)*100).toStringAsFixed(1)}% por debajo de $m2.",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(ProductionProvider provider) {
    final categories = provider.activeCategories;
    final data = provider.adaptiveChartData;
    if (data.isEmpty) return const SizedBox();

    // Calcular totales por categoría para el periodo actual
    Map<String, int> totals = {};
    for (var day in data) {
      final breakdown = day['breakdown'] as Map<String, int>;
      breakdown.forEach((cat, val) {
        totals[cat] = (totals[cat] ?? 0) + val;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DESGLOSE POR CATEGORÍA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.blueGrey)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final total = totals[cat] ?? 0;
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Text("$total", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text("Cartones", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _monthStat(String label, String value, Color color, {bool showIcon = false, bool isUp = true}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (showIcon) Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: color),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const Text(" Cart.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.orange)),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.query_stats_rounded, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text("No hay datos para este periodo", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
