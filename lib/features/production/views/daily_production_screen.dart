import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/production_model.dart';
import '../providers/production_provider.dart';
import '../../batches/providers/batch_provider.dart';
import '../../products/providers/product_provider.dart';
import 'add_batch_collection_screen.dart';
import 'add_sorting_screen.dart';

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
              Tab(icon: Icon(Icons.menu_book), text: 'Bitácora Galeras'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const DailyProductionComparisonTab(),
            RawCollectionsTab(isFiltered: _selectedRange != null),
            BatchCollectionHistoryTab(isFiltered: _selectedRange != null),
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
              ),
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
              ),
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
        padding: const EdgeInsets.all(16),
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
                    color: isEmpty
                        ? Colors.grey.shade400
                        : Colors.orange.shade700,
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
                    color: isEmpty
                        ? Colors.grey.shade400
                        : Colors.teal.shade700,
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

class BatchCollectionHistoryTab extends StatelessWidget {
  final bool isFiltered;
  const BatchCollectionHistoryTab({super.key, required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.batchCollections.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.fetchDailyData(),
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(
              child: Text(
                'Sin registros de campo en este periodo.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    // Agrupar las recolectas por fecha en el UI
    final Map<String, List<BatchCollectionModel>> groupedByDate = {};
    for (var collection in provider.batchCollections) {
      final dateStr = DateFormat('yyyy-MM-dd').format(collection.date);
      if (!groupedByDate.containsKey(dateStr)) {
        groupedByDate[dateStr] = [];
      }
      groupedByDate[dateStr]!.add(collection);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () => provider.fetchDailyData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final collections = groupedByDate[dateKey]!;
          final dateObj = DateTime.parse(dateKey);
          final dateTitle = DateFormat(
            "EEEE d 'de' MMMM",
            'es',
          ).format(dateObj);
          final fullDateTitle =
              dateTitle[0].toUpperCase() + dateTitle.substring(1);

          return Card(
            margin: const EdgeInsets.only(bottom: 24),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera de la Bitácora de Campo (Azul Acero)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade700,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fullDateTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "${collections.length} recolecciones",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de Recolectas Individuales
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: collections.length,
                  // Invertimos el orden dentro del día para que la más reciente (última en entrar) sea la #1 en el log o viceversa.
                  // Mostraremos ID de entrada (Audit Trail)
                  separatorBuilder: (context, i) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = collections[i];
                    final cartons = item.quantity ~/ 30;
                    final leftovers = item.quantity % 30;
                    final formatted = cartons > 0
                        ? "$cartons cartones y $leftovers huevos"
                        : "$leftovers huevos";

                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade50,
                        radius: 12,
                        child: Text(
                          "${collections.length - i}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      title: Text(
                        "Lote: ${item.batchName}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Entró: $formatted"),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "RESUMEN DE STOCK:",
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          ...stock.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  item.formatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
