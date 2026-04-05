import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/batch_model.dart';
import '../providers/batch_provider.dart';

class MortalityHistoryScreen extends StatefulWidget {
  final int batchId;
  final String batchName;

  const MortalityHistoryScreen({
    super.key,
    required this.batchId,
    required this.batchName,
  });

  @override
  State<MortalityHistoryScreen> createState() => _MortalityHistoryScreenState();
}

class _MortalityHistoryScreenState extends State<MortalityHistoryScreen> {
  BatchModel? _batch;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<BatchProvider>();
    final result = await provider.getBatchDetailed(widget.batchId);
    setState(() {
      _batch = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Combinar y ordenar movimientos
    final List<dynamic> movements = [];
    if (_batch != null) {
      movements.addAll(_batch!.mortalities);
      movements.addAll(_batch!.adjustments);
      movements.sort((a, b) => b.date.compareTo(a.date));
    }

    final hasMovements = movements.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Movimientos del Lote', style: TextStyle(fontSize: 16)),
            Text(widget.batchName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasMovements
              ? const Center(child: Text('No hay registros de movimientos para este lote.'))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.indigo.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Población Actual:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_batch!.currentQuantity} aves',
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: movements.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final mv = movements[index];
                          final isAdjustment = mv is BatchAdjustmentModel;
                          
                          int quantity;
                          String label;
                          IconData icon;
                          Color color;
                          String? reason;

                          if (isAdjustment) {
                            quantity = mv.quantity;
                            label = quantity > 0 ? "Ajuste (Entrada)" : "Ajuste (Salida)";
                            icon = quantity > 0 ? Icons.add_circle : Icons.remove_circle;
                            color = quantity > 0 ? Colors.green : Colors.orange;
                            reason = mv.reason;
                          } else {
                            quantity = mv.quantity;
                            label = "Baja (Muerte)";
                            icon = Icons.trending_down;
                            color = Colors.red;
                            reason = mv.reason;
                          }

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  '${quantity > 0 ? '+' : ''}$quantity aves',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  label,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('dd/MM/yyyy').format(mv.date)),
                                if (reason != null && reason.isNotEmpty)
                                  Text(
                                    'Motivo: $reason',
                                    style: const TextStyle(fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
