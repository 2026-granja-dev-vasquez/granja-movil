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

  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM SHEET: Ingresar/Editar huevos en mesa de ayer
  // ─────────────────────────────────────────────────────────────────────────
  void _openTableEggBottomSheet(ProductionProvider provider, ProductProvider productProvider) {
    final sizes = productProvider.sizes;
    if (sizes.isEmpty) return;

    // Pre-fill from existing table eggs
    final Map<int, TextEditingController> cartCtrl = {};
    final Map<int, TextEditingController> unitCtrl = {};
    for (final s in sizes) {
      final existing = provider.tableEggs.where((e) => e.productSizeId == s.id).firstOrNull;
      cartCtrl[s.id] = TextEditingController(text: (existing?.cartons ?? 0).toString());
      unitCtrl[s.id] = TextEditingController(text: (existing?.units ?? 0).toString());
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.table_restaurant, color: Colors.amber.shade700, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Huevos de ayer en la mesa",
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                            Text("Ingresa por tamaño cuántos hay sobre tu área de trabajo",
                                style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Per-size inputs
                  ...sizes.map((size) {
                    final carts = int.tryParse(cartCtrl[size.id]!.text) ?? 0;
                    final units = int.tryParse(unitCtrl[size.id]!.text) ?? 0;
                    final total = carts * 30 + units;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: total > 0 ? Colors.amber.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: total > 0 ? Colors.amber.shade200 : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.egg_outlined, size: 14, color: total > 0 ? Colors.amber.shade700 : Colors.grey),
                              const SizedBox(width: 6),
                              Text(size.name.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: total > 0 ? Colors.amber.shade800 : Colors.blueGrey)),
                              const Spacer(),
                              if (total > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text("$total huevos",
                                      style: TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("CARTONES (30u)",
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey.shade400)),
                                    const SizedBox(height: 6),
                                    Container(
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade200)),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 16),
                                            onPressed: () {
                                              final v = (int.tryParse(cartCtrl[size.id]!.text) ?? 0);
                                              if (v > 0) {
                                                cartCtrl[size.id]!.text = (v - 1).toString();
                                                setSheet(() {});
                                              }
                                            },
                                            color: Colors.blueGrey,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                          ),
                                          Expanded(
                                            child: TextField(
                                              controller: cartCtrl[size.id],
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              onChanged: (_) => setSheet(() {}),
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                              decoration: const InputDecoration(
                                                  border: InputBorder.none, contentPadding: EdgeInsets.zero),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 16),
                                            onPressed: () {
                                              final v = (int.tryParse(cartCtrl[size.id]!.text) ?? 0);
                                              cartCtrl[size.id]!.text = (v + 1).toString();
                                              setSheet(() {});
                                            },
                                            color: Colors.blueGrey,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("HUEVOS SUELTOS",
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey.shade400)),
                                    const SizedBox(height: 6),
                                    Container(
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade200)),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 16),
                                            onPressed: () {
                                              final v = (int.tryParse(unitCtrl[size.id]!.text) ?? 0);
                                              if (v > 0) {
                                                unitCtrl[size.id]!.text = (v - 1).toString();
                                                setSheet(() {});
                                              }
                                            },
                                            color: Colors.blueGrey,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                          ),
                                          Expanded(
                                            child: TextField(
                                              controller: unitCtrl[size.id],
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              onChanged: (_) => setSheet(() {}),
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                              decoration: const InputDecoration(
                                                  border: InputBorder.none, contentPadding: EdgeInsets.zero),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 16),
                                            onPressed: () {
                                              final v = (int.tryParse(unitCtrl[size.id]!.text) ?? 0);
                                              unitCtrl[size.id]!.text = (v + 1).toString();
                                              setSheet(() {});
                                            },
                                            color: Colors.blueGrey,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("CANCELAR", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  setSheet(() => _isSaving = true);
                                  setState(() => _isSaving = true);
                                  try {
                                    final prov = context.read<ProductionProvider>();
                                    for (final size in sizes) {
                                      final qty = (int.tryParse(cartCtrl[size.id]!.text) ?? 0) * 30 +
                                          (int.tryParse(unitCtrl[size.id]!.text) ?? 0);
                                      if (qty > 0) {
                                        await prov.saveTableEgg(TableEggModel(
                                          date: _selectedDate,
                                          productSizeId: size.id,
                                          quantity: qty,
                                        ));
                                      } else {
                                        final existing = prov.tableEggs.where((e) => e.productSizeId == size.id).firstOrNull;
                                        if (existing?.id != null) await prov.deleteTableEgg(existing!.id!);
                                      }
                                    }
                                    if (context.mounted) Navigator.pop(ctx);
                                  } finally {
                                    if (mounted) {
                                      setSheet(() => _isSaving = false);
                                      setState(() => _isSaving = false);
                                    }
                                  }
                                },
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
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

  // ─────────────────────────────────────────────────────────────────────────
  // DIALOG: Add classification entry for a size (Simple additive logic)
  // ─────────────────────────────────────────────────────────────────────────
  void _openAddEntryDialog(ProductSizeModel size, ProductionProvider provider, int tableQty, {ProductionModel? editEntry}) {
    final cartCtrl = TextEditingController(text: editEntry != null ? (editEntry.usefulQuantity ~/ 30).toString() : '0');
    final unitCtrl = TextEditingController(text: editEntry != null ? (editEntry.usefulQuantity % 30).toString() : '0');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          int netToday = (int.tryParse(cartCtrl.text) ?? 0) * 30 + (int.tryParse(unitCtrl.text) ?? 0);

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
                      Icon(editEntry != null ? Icons.edit_note : Icons.add_circle, 
                           color: editEntry != null ? Colors.amber : Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(editEntry != null ? "Modificar Registro" : "Registrar Limpieza",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                          Text(size.name.toLowerCase(),
                              style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (tableQty > 0 && editEntry == null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: Text(
                        "Información: De ayer quedaron ${tableQty ~/ 30} cart. + ${tableQty % 30} sueltos.",
                        style: TextStyle(fontSize: 11, color: Colors.brown.shade700, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const Divider(height: 28),
                  const Text("ESTOY AGREGANDO (CARTONES)",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  _dialogField(cartCtrl, Icons.grid_view_rounded, (v) => setDialogState(() {})),
                  const SizedBox(height: 16),
                  const Text("ESTOY AGREGANDO (SUELTOS)",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  _dialogField(unitCtrl, Icons.egg_outlined, (v) => setDialogState(() {})),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: editEntry != null ? Colors.amber.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: editEntry != null ? Colors.amber.shade200 : Colors.green.shade200)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(editEntry != null ? "NUEVO TOTAL:" : "POR AGREGAR:",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12)),
                        Text("$netToday HUEVOS",
                            style: TextStyle(fontWeight: FontWeight.w900, color: editEntry != null ? Colors.amber.shade700 : Colors.green, fontSize: 18)),
                      ],
                    ),
                  ),
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
                          backgroundColor: editEntry != null ? Colors.amber : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        onPressed: netToday > 0 && !_isSaving 
                          ? () async {
                              setState(() => _isSaving = true);
                              bool success;
                              if (editEntry != null) {
                                success = await provider.updateSortedProduction(ProductionModel(
                                  id: editEntry.id,
                                  productSizeId: size.id,
                                  usefulQuantity: netToday,
                                  damagedQuantity: editEntry.damagedQuantity,
                                  date: editEntry.date,
                                  origin: editEntry.origin,
                                ), date: DateFormat('yyyy-MM-dd').format(_selectedDate));
                              } else {
                                success = await provider.addSortedProduction(ProductionModel(
                                  productSizeId: size.id,
                                  usefulQuantity: netToday,
                                  damagedQuantity: 0,
                                  date: _selectedDate,
                                ));
                              }
                              if (mounted) {
                                setState(() => _isSaving = false);
                                if (success) Navigator.pop(ctx);
                              }
                            }
                          : null,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(editEntry != null ? "ACTUALIZAR" : "GUARDAR", style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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

  Future<void> _confirmDeleteEntry(ProductionModel entry, ProductionProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("¿Eliminar entrada?", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey)),
        content: Text("Se eliminará este registro de ${entry.usefulQuantity} huevos y se revertirá el stock."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("ELIMINAR"),
          ),
        ],
      ),
    );

    if (confirm == true && entry.id != null) {
      setState(() => _isSaving = true);
      final success = await provider.deleteSortedProduction(entry.id!, date: DateFormat('yyyy-MM-dd').format(_selectedDate));
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Registro eliminado y remanentes restaurados')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Error: ${provider.errorMessage}'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Guardado exitosamente')));
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${context.read<ProductionProvider>().errorMessage}')));
      }
    }
  }

  // Method _saveWithContext was removed as it is no longer used.

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

  // ─────────────────────────────────────────────────────────────────────────
  // BALANCE SUMMARY CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBalanceSummary(ProductionProvider provider) {
    final int netHarvest = provider.netTodayHarvest;
    final int tableRemainingInitial = provider.totalInitialTableRemnants; 
    
    final int totalSortedToday = provider.totalSortedCount; 
    final int remaining = provider.pendingEggs;
    final bool hasDeficit = provider.pendingFromYesterday < 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(15, 15, 15, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2A4E), // Deep Blue Screenshot
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2, color: Colors.blue.shade200, size: 16),
                  const SizedBox(width: 8),
                  Text("RESUMEN DE STOCK:",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade100, letterSpacing: 1.2)),
                ],
              ),
              Text(DateFormat("MMM d").format(_selectedDate).toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statHeader("DISPONIBLE HOY", netHarvest.toString(), Colors.blue.shade300),
              _statHeader(
                "HISTÓRICO/AYER",
                tableRemainingInitial.toString(),
                Colors.orange.shade300,
                onReset: hasDeficit ? () => _openResetDialog(provider) : null,
              ),
              _statHeader("POR CLASIFICAR", remaining.toString(), remaining < 0 ? Colors.redAccent : Colors.tealAccent),
            ],
          ),
          if (hasDeficit || remaining < 0) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    hasDeficit ? "Déficit detected (${provider.pendingFromYesterday}). Reiniciar." : "Balance negativo.",
                    style: const TextStyle(fontSize: 9, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(18)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("YA CLASIFICADO:", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade300)),
                Text("$totalSortedToday HUEVOS", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TARJETA PERMANENTE: Huevos en mesa de ayer
  // Siempre visible — sin huevos: pregunta / con huevos: muestra y permite editar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTableEggsCard(ProductionProvider provider, ProductProvider productProvider) {
    // La tarjeta es visible si hay huevos EN mesa O si ya se clasificó algo como remanente hoy
    final hasEggs = provider.tableEggs.isNotEmpty || provider.sortedRemnantUnits > 0;
    final totalUnits = provider.tableEggs.fold(0, (s, e) => s + e.quantity);
    final totalCartons = totalUnits ~/ 30;
    final totalLoose = totalUnits % 30;

    return Container(
      decoration: BoxDecoration(
        color: hasEggs ? Colors.amber.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasEggs ? Colors.amber.shade300 : Colors.blueGrey.shade100,
          width: hasEggs ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasEggs ? Colors.amber.withOpacity(0.08) : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: hasEggs
          // ── Vista con huevos registrados (Desplegable) ──
          ? Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.keyboard_arrow_down, color: Colors.amber.shade700, size: 22),
                ),
                title: Text("HUEVOS DE AYER EN TU ÁREA DE TRABAJO",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade800, letterSpacing: 1)),
                subtitle: Text("Total inicial: ${totalUnits} huevos ($totalCartons cart. + $totalLoose sueltos)",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.amber.shade900)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _confirmDeleteTableEggs(provider),
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _openTableEggBottomSheet(provider, productProvider),
                      icon: const Icon(Icons.edit, size: 18, color: Colors.amber),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.expand_more, color: Colors.amber),
                  ],
                ),
                children: [
                  const Divider(height: 1, color: Colors.amber),
                  const SizedBox(height: 12),
                  ...provider.tableEggs.map((egg) {
                    final name = egg.productSizeName ?? 'Tamaño ${egg.productSizeId}';
                    final remaining = provider.tableEggsRemainingForSize(egg.productSizeId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.egg_outlined, size: 12, color: Colors.amber.shade600),
                          const SizedBox(width: 8),
                          Text("$name: ", style: TextStyle(fontSize: 13, color: Colors.brown.shade600)),
                          const Spacer(),
                          Text("Pte: $remaining de ${egg.quantity}",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
                        ],
                      ),
                    );
                  }).toList(),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Text(
                      "💡 Al clasificar hoy, ingresa SOLO los huevos nuevos (sin contar los de arriba).",
                      style: TextStyle(fontSize: 10, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            )
          // ── Vista sin huevos registrados ──
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.table_restaurant, color: Colors.blueGrey.shade300, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Huevos de ayer en tu área de trabajo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.blueGrey.shade700)),
                        Text("agrega aca los huevos que ya estan clasificados pero estan en tu area de trabajo", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _openTableEggBottomSheet(provider, productProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("SÍ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ],
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Date selector
  // ─────────────────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION: Per-size with list of entries
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSizeSection(ProductSizeModel size, ProductionProvider provider) {
    final entries = provider.dailySortedProductions.where((p) => p.productSizeId == size.id).toList();

    final int totalSorted = entries.fold(0, (s, p) => s + p.usefulQuantity);
    final int tableQty = provider.tableEggsRemainingForSize(size.id);

    final int remnantsProcessed = entries.where((p) => p.origin == 'remnant').fold(0, (s, p) => s + p.usefulQuantity);
    final int harvestSorted = entries.where((p) => p.origin == 'harvest').fold(0, (s, p) => s + p.usefulQuantity);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: Colors.green.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(15)),
          child: Center(child: Icon(Icons.keyboard_arrow_down, color: Colors.green.shade600, size: 22)),
        ),
        title: Text(size.name.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400, letterSpacing: 1)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${(totalSorted + tableQty) ~/ 30} CARTONES Y ${(totalSorted + tableQty) % 30} HUEVOS",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: (totalSorted + tableQty) > 0 ? Colors.green.shade700 : Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (tableQty > 0 || remnantsProcessed > 0)
                  _pill(
                    "Ayer: ${(tableQty + remnantsProcessed) ~/ 30} cart. + ${(tableQty + remnantsProcessed) % 30} suelt.",
                    Icons.history,
                    Colors.amber.shade800,
                    Colors.amber.shade50,
                  ),
                if (harvestSorted > 0)
                  _pill(
                    "Hoy: ${harvestSorted ~/ 30} cart. + ${harvestSorted % 30} suelt.",
                    Icons.auto_awesome,
                    Colors.green.shade700,
                    Colors.green.shade50,
                  ),
              ],
            ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () => _openAddEntryDialog(size, provider, tableQty),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.shade100.withOpacity(0.5), shape: BoxShape.circle),
            child: Icon(Icons.add, color: Colors.green.shade700, size: 22),
          ),
        ),
        children: [
          const Divider(height: 1),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("No hay clasificaciones registradas para hoy.",
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 50),
              itemBuilder: (ctx, i) {
                final entry = entries[i];
                final ec = entry.usefulQuantity ~/ 30;
                final eu = entry.usefulQuantity % 30;
                return ListTile(
                  dense: true,
                  onTap: () => _openAddEntryDialog(size, provider, tableQty, editEntry: entry),
                  leading: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: entry.origin == 'remnant' ? Colors.orange.shade50 : Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(entry.origin == 'remnant' ? Icons.history : Icons.egg, 
                                 size: 14, color: entry.origin == 'remnant' ? Colors.orange : Colors.green),
                    ),
                  ),
                  title: Text("$ec cartones y $eu huevos", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text("${entry.origin == 'remnant' ? 'Remanente' : 'Cosecha'} • ${entry.usefulQuantity} huevos", 
                                 style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => _confirmDeleteEntry(entry, provider),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Broken eggs footer
  // ─────────────────────────────────────────────────────────────────────────
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
                  if (savedTotal > 0) Text("REGISTRADO HOY: $savedTotal HUEVOS", style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
                  : TextButton(onPressed: () => _saveClassification(null, 0, damaged: _sessionDamaged), child: const Text("GUARDAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 13)))
            ],
          ),
          const SizedBox(height: 16),
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

  // ─────────────────────────────────────────────────────────────────────────
  // MODIFICAR / REINICIAR dialogs
  // ─────────────────────────────────────────────────────────────────────────
  void _openResetDialog(ProductionProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.refresh, color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Reiniciar Balance", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
              child: const Text(
                "¿Estás seguro? Esto pondrá en CERO el saldo histórico para corregir errores y empezar el día limpio.",
                style: TextStyle(fontSize: 12, color: Colors.brown),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _isSaving
                ? null
                : () async {
                    final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                    setState(() => _isSaving = true);
                    final ok = await provider.resetBalance(date: dateStr, targetPending: 0);
                    if (mounted) {
                      setState(() => _isSaving = false);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok ? '✅ Saldo histórico reiniciado a 0' : '❌ Error al reiniciar'),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ));
                    }
                  },
            child: _isSaving
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("SÍ, REINICIAR", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _statHeader(String label, String value, Color color, {VoidCallback? onReset}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        if (onReset != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _miniButton("REINICIAR", Icons.refresh, Colors.redAccent, onReset),
          ),
      ],
    );
  }

  Widget _pill(String label, IconData icon, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _miniButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.4)), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 8, color: color),
              const SizedBox(width: 3),
              Text(label, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
        ),
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

  void _confirmDeleteTableEggs(ProductionProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Limpiar Mesa", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey)),
        content: const Text("¿Deseas eliminar todos los huevos registrados de ayer en la mesa para esta fecha?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              setState(() => _isSaving = true);
              final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
              await provider.clearTableEggs(dateStr);
              if (mounted) {
                setState(() => _isSaving = false);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Huevos en mesa eliminados")));
              }
            },
            child: const Text("SÍ, BORRAR TODO", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _fetchData()),
        ],
      ),
      body: Column(
        children: [
          _buildBalanceSummary(prodProvider),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDateSelector(),
                  const SizedBox(height: 12),
                  _buildTableEggsCard(prodProvider, productProvider),
                  const SizedBox(height: 20),
                  const Text(
                    "CLASIFICACIÓN POR TAMAÑO",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 12),
                  if (productProvider.isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  else
                    ...productProvider.sizes.map((size) => _buildSizeSection(size, prodProvider)),
                  const SizedBox(height: 20),
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
}
