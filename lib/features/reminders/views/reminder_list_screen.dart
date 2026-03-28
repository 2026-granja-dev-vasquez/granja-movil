import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reminder_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'add_reminder_screen.dart';
import 'reminder_history_screen.dart';
import '../models/reminder_model.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().syncReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.role == 'admin';

    // Organizar: Proximas y Vencidas/Para Hoy
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final dueReminders = provider.activeReminders.where((r) => r.remindAt.isBefore(todayEnd)).toList();
    final upcomingReminders = provider.activeReminders.where((r) => r.remindAt.isAfter(todayEnd)).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Recordatorios de Granja'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.history_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderHistoryScreen())),
              tooltip: 'Historial Auditado',
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.syncReminders(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (dueReminders.isEmpty && upcomingReminders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                            SizedBox(height: 16),
                            Text("¡Granja al día!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("No hay tareas programadas pendientes.", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),

                  if (dueReminders.isNotEmpty) ...[
                    const _SectionHeader(title: "⚠️ PARA HOY O ATRASADOS", color: Colors.orange),
                    const SizedBox(height: 12),
                    ...dueReminders.map((r) => _ReminderCard(reminder: r, isAdmin: isAdmin)),
                    const SizedBox(height: 32),
                  ],

                  if (upcomingReminders.isNotEmpty) ...[
                    const _SectionHeader(title: "📅 PRÓXIMAS TAREAS", color: Colors.indigo),
                    const SizedBox(height: 12),
                    ...upcomingReminders.map((r) => _ReminderCard(reminder: r, isAdmin: isAdmin)),
                  ],
                ],
              ),
            ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddReminderScreen())),
              backgroundColor: Colors.indigo,
              icon: const Icon(Icons.add_alert, color: Colors.white),
              label: const Text('NUEVA TAREA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color, letterSpacing: 1.1),
      ),
    );
  }
}

class _ReminderCard extends StatefulWidget {
  final ReminderModel reminder;
  final bool isAdmin;

  const _ReminderCard({required this.reminder, required this.isAdmin});

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  bool _isCompleting = false;

  void _markAsDone() async {
    if (!widget.isAdmin) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Validar Cumplimiento?'),
        content: const Text('¿Confirmas que esta tarea ha sido realizada en la granja? Si es recurrente, se programará automáticamente la siguiente fecha.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('SÍ, ESTÁ HECHO'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) setState(() => _isCompleting = true);
      try {
        final message = await context.read<ReminderProvider>().markAsDone(widget.reminder);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isCompleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.reminder.remindAt.isBefore(DateTime.now());
    
    String recurrenceText = '';
    if (widget.reminder.frequency == 'custom_days') {
      recurrenceText = '🔄 Cada ${widget.reminder.intervalDays} días';
    } else if (widget.reminder.frequency == 'monthly') {
      recurrenceText = '🔄 Mensual';
    } else {
      recurrenceText = '1 Solo Aviso';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isOverdue ? Colors.orange.shade200 : Colors.indigo.shade100, width: 2),
      ),
      color: isOverdue ? Colors.orange.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.reminder.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isOverdue ? Colors.orange.shade900 : Colors.black87),
                  ),
                  if (widget.reminder.description != null && widget.reminder.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(widget.reminder.description!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: isOverdue ? Colors.orange.shade800 : Colors.indigo),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(widget.reminder.remindAt),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isOverdue ? Colors.orange.shade800 : Colors.indigo),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                        child: Text(recurrenceText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.isAdmin)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _isCompleting
                    ? const SizedBox(width: 48, height: 48, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                    : InkWell(
                        onTap: _markAsDone,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.green, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.green, size: 28),
                        ),
                      ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(Icons.lock_outline, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }
}
