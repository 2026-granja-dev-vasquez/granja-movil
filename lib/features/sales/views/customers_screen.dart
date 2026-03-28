import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import 'add_customer_screen.dart';
import 'sale_list_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clientes'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchCustomers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de ayuda
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.indigo.shade50,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aquí puedes gestionar tus compradores frecuentes. La opción "Consumidor Final" siempre estará disponible en ventas.',
                    style: TextStyle(fontSize: 12, color: Colors.indigo.shade700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading && provider.customers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.customers.isEmpty
                    ? const Center(child: Text('No tienes clientes registrados todavía.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: provider.customers.length,
                        itemBuilder: (context, index) {
                          final customer = provider.customers[index];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: customer.isActive ? Colors.indigo.shade100 : Colors.grey.shade200,
                                child: Text(
                                  customer.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: customer.isActive ? Colors.indigo : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                customer.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: customer.isActive ? Colors.black87 : Colors.grey,
                                  decoration: customer.isActive ? null : TextDecoration.lineThrough,
                                ),
                              ),
                              subtitle: Text(customer.phone ?? 'Sin teléfono'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (customer.phone != null && customer.phone!.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.phone, color: Colors.green),
                                      onPressed: () => _makePhoneCall(customer.phone!),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.indigo),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => AddCustomerScreen(customer: customer)),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SaleListScreen(
                                      customerId: customer.id,
                                      customerName: customer.name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
        ),
        label: const Text('Nuevo Cliente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.person_add, color: Colors.white),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
