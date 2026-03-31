import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/production_model.dart';
import '../providers/production_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/models/product_size_model.dart';

class AddSortingScreen extends StatefulWidget {
  const AddSortingScreen({super.key});

  @override
  State<AddSortingScreen> createState() => _AddSortingScreenState();
}

class _AddSortingScreenState extends State<AddSortingScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  int _sessionDamaged = 0;
  final TextEditingController _brokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _saveWithContext(BuildContext ctx, int? sizeId, int useful, {int damaged = 0}) async {
    await _saveClassification(sizeId, useful, damaged: damaged);
    if (mounted && Navigator.canPop(ctx)) Navigator.pop(ctx);
  }

  void _fetchData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProductionProvider>().fetchDailyData(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );
      if (mounted) {
        final totalDamaged = context.read<ProductionProvider>().totalDailyDamaged;
        setState(() {
          _sessionDamaged = totalDamaged;
          _brokenController.text = totalDamaged > 0 ? totalDamaged.toString() : "";
        });
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Colors.green)),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _sessionDamaged = 0;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final prodProvider = context.watch<ProductionProvider>();
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Clasificación y Limpieza'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () => _fetchData()),
        ],
      ),
      body: Column(
        children: [
          _buildBalanceSummary(prodProvider),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDateSelector(),
                  const SizedBox(height: 24),
                  
                  const Text(
                    "TAMAÑOS DE PRODUCTO",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 16),
                  
                  if (productProvider.isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  else
                    ...productProvider.sizes.map((size) => _buildSizeCard(size, prodProvider)),
                  
                  const SizedBox(height: 24),
                  _buildBrokenEggsFooter(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSummary(ProductionProvider provider) {
    final int todayRaw = provider.dailyBatchCollections
        .where((c) => c.type != 'adjustment')
        .fold(0, (sum, c) => sum + c.quantity);
    
    final int yesterdayPending = provider.pendingFromYesterday;
    final int adjustments = provider.dailyBatchCollections
        .where((c) => c.type == 'adjustment')
        .fold(0, (sum, c) => sum + c.quantity);
    
    final int totalAvailable = todayRaw + yesterdayPending + adjustments;
    final int alreadySorted = provider.totalSortedCount;
    final int remaining = totalAvailable - alreadySorted;

    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark blue-grey (Style from screenshot)
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.inventory_2, color: Colors.blueAccent, size: 20),
              Text("RESUMEN DE STOCK:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent.shade100, letterSpacing: 1.5)),
              const Spacer(),
              Text(DateFormat("MMM d").format(_selectedDate).toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statHeader("DISPONIBLE HOY", todayRaw.toString(), Colors.blue.shade300),
              _statHeader("AJUSTE/AYER", (yesterdayPending + adjustments).toString(), Colors.orange.shade300, onAdjust: () => _openMasterAdjustmentDialog(provider, yesterdayPending + adjustments)),
              _statHeader("POR CLASIFICAR", remaining.toString(), remaining < 0 ? Colors.redAccent : Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("YA CLASIFICADO:", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                Text("$alreadySorted HUEVOS", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statHeader(String label, String value, Color color, {VoidCallback? onAdjust}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        if (onAdjust != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onAdjust,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: Colors.orange.withOpacity(0.5)), borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 8, color: Colors.orange),
                      SizedBox(width: 4),
                      Text("MODIFICAR", style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.orange)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openMasterAdjustmentDialog(ProductionProvider provider, int currentTotal) {
    final TextEditingController adjCtrl = TextEditingController(text: currentTotal.toString());
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Ajustar Saldo Inicial", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("¿Cuántos huevos hay REALMENTE pendientes de ayer?", style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: adjCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.edit_note, color: Colors.orange),
                hintText: "Eje: 200",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
                final int realPending = int.tryParse(adjCtrl.text) ?? 0;
                final int neededAdjustment = realPending - provider.pendingFromYesterday;
                
                final adjModel = BatchCollectionModel(
                  batchId: 0,
                  quantity: neededAdjustment,
                  date: _selectedDate,
                  type: 'adjustment'
                );
                
                setState(() => _isSaving = true);
                await provider.addBatchCollection(adjModel);
                if (mounted) {
                  setState(() => _isSaving = false);
                  Navigator.pop(ctx);
                }
            },
            child: const Text("GUARDAR AJUSTE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.green, size: 20),
            const SizedBox(width: 12),
            Text(
              DateFormat("EEEE d 'de' MMMM", 'es').format(_selectedDate),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.edit, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeCard(ProductSizeModel size, ProductionProvider provider) {
    // Obtener lo que ya está guardado para este tamaño hoy
    final int alreadySorted = provider.dailySortedProductions
        .where((p) => p.productSizeId == size.id)
        .fold(0, (sum, p) => sum + p.usefulQuantity);
    
    final int cartons = alreadySorted ~/ 30;
    final int units = alreadySorted % 30;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: alreadySorted > 0 ? Colors.green.shade200 : Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openAdjustmentDialog(size, alreadySorted, provider),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.egg_outlined, color: alreadySorted > 0 ? Colors.green : Colors.grey.shade400),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(size.name.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade600)),
                      const SizedBox(height: 4),
                      Text(
                        alreadySorted > 0 ? "$cartons CARTONES Y $units HUEVOS" : "0 CARTONES Y 0 HUEVOS",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: alreadySorted > 0 ? Colors.green.shade700 : Colors.grey.shade400),
                      ),
                      Text("TOTAL: $alreadySorted HUEVOS", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                // Botón + para agregar rápido o abrir diálogo
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.green, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAdjustmentDialog(ProductSizeModel size, int alreadySorted, ProductionProvider provider) {
    final TextEditingController cartCtrl = TextEditingController(text: '${alreadySorted ~/ 30}');
    final TextEditingController unitCtrl = TextEditingController(text: '${alreadySorted % 30}');
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          int getDialogTotal() {
            int c = int.tryParse(cartCtrl.text) ?? 0;
            int u = int.tryParse(unitCtrl.text) ?? 0;
            return (c * 30) + u;
          }

          final int totalToSave = getDialogTotal();

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_circle, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      const Text("Registrar Ingreso", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Producto: ${size.name.toLowerCase()}", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),
                  
                  const Text("CANTIDAD EN CARTONES (30u)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  _dialogField(cartCtrl, Icons.grid_view_rounded, (v) => setDialogState(() {})),
                  
                  const SizedBox(height: 20),
                  
                  const Text("HUEVOS SUELTOS (UNIDADES)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  _dialogField(unitCtrl, Icons.egg_outlined, (v) => setDialogState(() {})),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("TOTAL FINAL:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13)),
                        Text("$totalToSave HUEVOS", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 18)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        onPressed: _isSaving ? null : () => _saveWithContext(ctx, size.id, totalToSave),
                        child: _isSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, IconData icon, Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: Colors.blueGrey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }


  Widget _buildBrokenEggsFooter() {
    final int savedTotal = context.read<ProductionProvider>().totalDailyDamaged;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: savedTotal > 0 ? Colors.red.shade200 : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.heart_broken, color: Colors.red, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("HUEVOS QUEBRADOS / DAÑADOS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 11)),
                  if (savedTotal > 0)
                    Text("REGISTRADO HOY: $savedTotal HUEVOS", style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
                  : TextButton(
                      onPressed: () => _saveClassification(null, 0, damaged: _sessionDamaged), 
                      child: const Text("GUARDAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 13))
                    )
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _brokenController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.red),
              onChanged: (v) => _sessionDamaged = int.tryParse(v) ?? 0,
              decoration: InputDecoration(
                hintText: "Eje: 10",
                hintStyle: TextStyle(color: Colors.red.withOpacity(0.2)),
                prefixIcon: const Icon(Icons.edit_note, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveClassification(int? sizeId, int useful, {int damaged = 0}) async {
    setState(() => _isSaving = true);
    
    final model = ProductionModel(
      productSizeId: sizeId,
      usefulQuantity: useful,
      damagedQuantity: damaged,
      date: _selectedDate,
    );

    final success = await context.read<ProductionProvider>().addSortedProduction(model);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado exitosamente')));
        _fetchData(); // Refrescar stock
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${context.read<ProductionProvider>().errorMessage}')));
      }
    }
  }
}
