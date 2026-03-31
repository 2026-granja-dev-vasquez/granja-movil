import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/views/login_screen.dart';
import 'features/batches/providers/batch_provider.dart';
import 'features/batches/views/batch_list_screen.dart';
import 'features/products/providers/product_provider.dart';
import 'features/products/views/product_config_screen.dart';
import 'features/production/providers/production_provider.dart';
import 'features/production/views/daily_production_screen.dart';
import 'features/sales/providers/customer_provider.dart';
import 'features/sales/providers/sale_provider.dart';
import 'features/inventory/providers/inventory_provider.dart';
import 'features/cash/providers/cash_provider.dart';
import 'features/users/providers/user_provider.dart';
import 'features/sales/views/customers_screen.dart';
import 'features/sales/views/add_sale_screen.dart';
import 'features/sales/views/sale_list_screen.dart';
import 'features/sales/views/accounts_receivable_screen.dart';
import 'features/inventory/views/product_stock_screen.dart';
import 'features/cash/views/cash_box_screen.dart';
import 'features/users/views/user_list_screen.dart';
import 'features/users/views/profile_screen.dart';
import 'core/services/notification_service.dart';
import 'features/reminders/providers/reminder_provider.dart';
import 'features/reminders/views/reminder_list_screen.dart';
import 'features/orders/providers/order_provider.dart';
import 'features/orders/views/orders_pending_screen.dart';
import 'features/sales/models/sale_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('es_GT', null);

  // Initialize local notifications and timezone
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => BatchProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ProductionProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CashProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: dotenv.env['APP_NAME'] ?? 'ERP Granja',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'GT'), Locale('en', 'US')],
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.indigo,
        primaryColor: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.indigo,
          iconTheme: IconThemeData(color: Colors.indigo),
        ),
      ),
      builder: (context, child) {
        return SafeArea(
          top: false,
          bottom: true,
          child: child!,
        );
      },
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (auth.isAuthenticated) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StreamSubscription<String?>? _notifSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().syncReminders();
      context.read<CashProvider>().fetchActiveBox();
      context.read<OrderProvider>().fetchPendingOrders().then((_) {
        _checkOverdueOrders();
      });
      context.read<SaleProvider>().fetchSales();
    });

    _notifSub = NotificationService().selectNotificationStream.stream.listen((
      payload,
    ) {
      if (payload != null && mounted) {
        final id = int.tryParse(payload) ?? 0;
        if (id >= 100000) {
          _showOrderAlarmDialog(id - 100000);
        } else {
          _showPendingReminderDialog(payload);
        }
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  void _showPendingReminderDialog(String reminderId) {
    if (!mounted) return;
    final rId = int.tryParse(reminderId);
    if (rId == null) return;

    final provider = context.read<ReminderProvider>();
    final reminder = provider.activeReminders
        .where((r) => r.id == rId)
        .firstOrNull;

    if (reminder == null) return;

    final isAdmin = context.read<AuthProvider>().user?.role == 'admin';

    showDialog(
      context: navigatorKey.currentContext ?? context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.orange, width: 3),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "¡ATENCIÓN GRANJA!",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tienes una tarea programada para este momento:",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              reminder.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.indigo,
              ),
            ),
            if (reminder.description != null &&
                reminder.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(reminder.description!, style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "⚠️ Este recordatorio ha sido notificado a todo el equipo.",
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "CERRAR AVISO",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          if (isAdmin)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final msg = await provider.markAsDone(reminder);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("MARCAR COMO HECHO"),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Text(
                "Solo Administradores pueden completar.",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _checkOverdueOrders() {
    if (!mounted) return;
    final provider = context.read<OrderProvider>();
    final overdueOrders = provider.pendingOrders.where((o) => o.isOverdue).toList();
    
    if (overdueOrders.isNotEmpty) {
      // Show alert for the first overdue one or a general one
      _showOrderAlarmDialog(overdueOrders.first.id, isOverdueMode: true);
    }
  }
  
  void _showOrderAlarmDialog(int orderId, {bool isOverdueMode = false}) async {
    if (!mounted) return;
    
    final provider = context.read<OrderProvider>();
    // Guarantee loading
    if (provider.pendingOrders.isEmpty) {
      await provider.fetchPendingOrders();
    }
    
    final order = provider.pendingOrders.where((o) => o.id == orderId).firstOrNull;
    if (order == null) return;

    showDialog(
      context: navigatorKey.currentContext ?? context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isOverdueMode ? Colors.red : Colors.indigo, width: 3),
        ),
        title: Row(
          children: [
            Icon(
              isOverdueMode ? Icons.warning_amber_rounded : Icons.local_shipping, 
              color: isOverdueMode ? Colors.red : Colors.indigo, 
              size: 36,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isOverdueMode ? "¡PEDIDO ATRASADO!" : "¡ALERTA DE ENTREGA!",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOverdueMode 
                ? "Tienes un pedido que no ha sido entregado a tiempo:"
                : "Un pedido debe ser entregado pronto:",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              "Cliente: ${order.customer?.name ?? '...'}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              "Entrega: ${DateFormat('dd/MM/yyyy hh:mm a').format(order.deliveryDate)}",
              style: TextStyle(
                color: isOverdueMode ? Colors.red : Colors.indigo, 
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CERRAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersPendingScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isOverdueMode ? Colors.red : Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text("GESTIONAR AHORA"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final isAdmin = user?.role == 'admin';
    final saleProvider = context.watch<SaleProvider>();

    // Calcular clientes únicos con deudas pendientes
    final pendingCustomersCount = saleProvider.sales
        .where((s) => s.status != SaleStatus.paid)
        .map((s) => s.customerId)
        .toSet()
        .length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          dotenv.env['APP_NAME'] ?? 'Mi Granja',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Text(
                "¡Hola, Bienvenido ${user?.name ?? 'Carlos'}!",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "¿Listo para un nuevo día de trabajo?",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 32),

              // Sección: Accesos Rápidos
              const Text(
                "ACCESOS RÁPIDOS",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _QuickActionCard(
                    title: 'Producción Diaria',
                    icon: Icons.egg_outlined,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DailyProductionScreen()),
                    ),
                  ),
                  _QuickActionCard(
                    title: 'Nueva Venta',
                    icon: Icons.shopping_cart_outlined,
                    color: Colors.blueAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddSaleScreen()),
                    ),
                  ),
                  _QuickActionCard(
                    title: 'Historial de Ventas',
                    icon: Icons.history_edu_outlined,
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SaleListScreen()),
                    ),
                  ),
                  _QuickActionCard(
                    title: 'Pedidos',
                    icon: Icons.local_shipping_outlined,
                    color: Colors.indigoAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersPendingScreen()),
                    ),
                  ),
                  _QuickActionCard(
                    title: 'Stock en Existencia',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.orange.shade800,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductStockScreen()),
                    ),
                  ),
                  if (isAdmin)
                    _QuickActionCard(
                      title: 'Caja',
                      icon: Icons.account_balance_wallet_outlined,
                      color: Colors.brown,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CashBoxScreen()),
                      ),
                    ),
                  _QuickActionCard(
                    title: 'Cuentas por Cobrar',
                    icon: Icons.assignment_late_outlined,
                    color: Colors.redAccent,
                    badgeCount: pendingCustomersCount,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountsReceivableScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              // Footer
              Center(
                child: Opacity(
                  opacity: 0.5,
                  child: Column(
                    children: [
                      Image.network(
                        'https://cdn-icons-png.flaticon.com/512/1151/1151608.png',
                        height: 48,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.wb_sunny_outlined, size: 40),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "El éxito depende del esfuerzo diario.",
                        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final isAdmin = user?.role == 'admin';

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.indigo),
                  accountName: Text(
                    user?.name ?? 'Usuario',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(
                    user?.role.toUpperCase() ?? 'OPERADOR',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.indigo, size: 40),
                  ),
                ),

                // MI CUENTA
                _DrawerItem(
                  icon: Icons.account_circle_outlined,
                  label: 'Mi Perfil',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),

                // RECORDATORIOS COMPARTIDOS
                _DrawerItem(
                  icon: Icons.notifications_active_outlined,
                  label: 'Recordatorios de Granja',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReminderListScreen(),
                    ),
                  ),
                ),

                const Divider(),

                // OPERACIONES DIARIAS
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Text(
                    "OPERACIONES DIARIAS",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.egg_outlined,
                  label: 'Producción Diaria',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DailyProductionScreen(),
                    ),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Nueva Venta',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddSaleScreen()),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.history_edu_outlined,
                  label: 'Historial de Ventas',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SaleListScreen()),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.payments_outlined,
                  label: 'Cobros (Cuentas x C.)',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountsReceivableScreen(),
                    ),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Stock en Existencia',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductStockScreen(),
                    ),
                  ),
                ),

                // CAJA: Solo Admins
                if (isAdmin)
                  _DrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Caja',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CashBoxScreen()),
                    ),
                  ),
                
                const Divider(),

                // PEDIDOS
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Text(
                    "LOGÍSTICA Y PEDIDOS",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.local_shipping_outlined,
                  label: 'Gestión de Pedidos',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersPendingScreen()),
                  ),
                ),

                const Divider(),

                // ADMINISTRACIÓN
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Text(
                    "ADMINISTRACIÓN",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.pets_outlined,
                  label: 'Gestión de Lotes',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BatchListScreen()),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Tamaños de Huevos y Precios',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductConfigScreen(),
                    ),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.people_outline,
                  label: 'Gestión de Clientes',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomersScreen()),
                  ),
                ),

                // GESTIÓN DE USUARIOS: Solo Admins
                if (isAdmin)
                  _DrawerItem(
                    icon: Icons.people_alt_outlined,
                    label: 'Gestión de Usuarios',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserListScreen()),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(),
          SafeArea(
            top: false,
            child: _DrawerItem(
              icon: Icons.logout,
              label: 'Cerrar Sesión',
              color: Colors.red,
              onTap: () => authProvider.logout(),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.indigo),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Cerrar drawer
        onTap();
      },
    );
  }
}
