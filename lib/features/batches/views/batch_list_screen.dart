import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/batch_model.dart';
import '../providers/batch_provider.dart';
import 'batch_form_screen.dart';
import 'mortality_history_screen.dart';
import 'widgets/adjustment_dialog.dart';

class BatchListScreen extends StatefulWidget {
  const BatchListScreen({super.key});

  @override
  State<BatchListScreen> createState() => _BatchListScreenState();
}

class _BatchListScreenState extends State<BatchListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BatchProvider>().fetchBatches();
    });
  }

  Future<void> _confirmCloseBatch(BatchModel batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Finalizar Lote?'),
        content: Text('Esto marcará el lote "${batch.name}" como inactivo. Ya no aparecerá en las recolecciones diarias.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<BatchProvider>().closeBatch(batch.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lote "${batch.name}" finalizado.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Lotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<BatchProvider>().fetchBatches(),
          ),
        ],
      ),
      body: Consumer<BatchProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          if (provider.batches.isEmpty) {
            return const Center(child: Text('No hay lotes registrados.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.batches.length,
            itemBuilder: (context, index) {
              final batch = provider.batches[index];
              final isActive = batch.status == 'active';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            batch.name,
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              decoration: isActive ? null : TextDecoration.lineThrough,
                              color: isActive ? Colors.black87 : Colors.grey,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'ACTIVO' : 'FINALIZADO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.green.shade800 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'Inicial', value: batch.initialQuantity.toString()),
                          _StatItem(label: 'Vivos', value: batch.currentQuantity.toString(), color: isActive ? Colors.blue : Colors.grey),
                          _StatItem(
                            label: 'Bajas', 
                            value: (batch.initialQuantity - batch.currentQuantity).toString(),
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (isActive) ...[
                            TextButton.icon(
                              onPressed: () => _confirmCloseBatch(batch),
                              icon: const Icon(Icons.stop_circle_outlined, color: Colors.orange, size: 18),
                              label: const Text('Finalizar', style: TextStyle(color: Colors.orange, fontSize: 12)),
                            ),
                            TextButton.icon(
                              onPressed: () => _showAdjustmentDialog(batch.id),
                              icon: const Icon(Icons.scale_outlined, color: Colors.indigo, size: 18),
                              label: const Text('Ajuste', style: TextStyle(color: Colors.indigo, fontSize: 12)),
                            ),
                          ],
                          TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MortalityHistoryScreen(batchId: batch.id, batchName: batch.name),
                              ),
                            ),
                            icon: const Icon(Icons.history, color: Colors.blueGrey, size: 18),
                            label: const Text('Historial', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BatchFormScreen()),
        ),
        label: const Text('Nuevo Lote'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAdjustmentDialog(int batchId) {
    showDialog(
      context: context,
      builder: (_) => AdjustmentDialog(batchId: batchId),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
