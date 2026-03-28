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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historial de Bajas', style: TextStyle(fontSize: 16)),
            Text(widget.batchName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _batch == null || _batch!.mortalities.isEmpty
              ? const Center(child: Text('No hay registros de bajas para este lote.'))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.red.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total de Bajas Acumuladas:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_batch!.mortalities.fold(0, (sum, m) => sum + m.quantity)} aves',
                            style: const TextStyle(
                              color: Colors.red,
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
                        itemCount: _batch!.mortalities.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final mortality = _batch!.mortalities[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.trending_down, color: Colors.red),
                            ),
                            title: Text(
                              '${mortality.quantity} aves',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('dd/MM/yyyy').format(mortality.date)),
                                if (mortality.reason != null && mortality.reason!.isNotEmpty)
                                  Text(
                                    'Motivo: ${mortality.reason}',
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
