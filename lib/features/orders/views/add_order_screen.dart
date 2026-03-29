import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../../sales/providers/customer_provider.dart';
import '../../sales/models/customer_model.dart';
import '../../../shared/widgets/loading_button.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  CustomerModel? _selectedCustomer;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
    });
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCustomer == null || _selectedCustomer!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un cliente')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Validate that the scheduled time is in the future
    if (finalDateTime.isBefore(DateTime.now())) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora de entrega debe ser en el futuro')),
      );
      return;
    }

    final success = await context.read<OrderProvider>().createOrder(
      _selectedCustomer!.id!,
      finalDateTime,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido programado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isSaving = false);
        final error =
            context.read<OrderProvider>().errorMessage ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Pedido'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Programar Entregas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona un cliente y la fecha/hora en la que entregarás el producto. Recibirás una alarma 1 hora antes.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Selector de Clientes
            Consumer<CustomerProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.activeCustomers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(),
                  );
                }
                return DropdownButtonFormField<CustomerModel>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCustomer,
                  items: provider.activeCustomers.map((customer) {
                    return DropdownMenuItem(
                      value: customer,
                      child: Text(customer.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCustomer = val),
                  validator: (val) => val == null ? 'Selecciona un cliente válido' : null,
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Selector de Fecha (Simulado con TextFormField)
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: DateFormat('EEEE d, MMMM yyyy', 'es_GT').format(_selectedDate)),
              decoration: const InputDecoration(
                labelText: 'Fecha de Entrega',
                prefixIcon: Icon(Icons.calendar_month, color: Colors.indigo),
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),

            const SizedBox(height: 20),

            // Selector de Hora (Simulado con TextFormField)
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: _selectedTime.format(context)),
              decoration: const InputDecoration(
                labelText: 'Hora Programada',
                prefixIcon: Icon(Icons.access_time_filled, color: Colors.orange),
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null) {
                  setState(() => _selectedTime = picked);
                }
              },
            ),

            const SizedBox(height: 48),
            LoadingButton(
              text: 'PROGRAMAR ALARMA DE PEDIDO',
              isLoading: _isSaving,
              onPressed: _submit,
            ),
          ]
        ),
      ),
    );
  }
}
