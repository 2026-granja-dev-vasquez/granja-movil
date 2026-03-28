import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'features/sales/views/customers_screen.dart';
import 'features/sales/views/add_sale_screen.dart';
import 'features/sales/views/sale_list_screen.dart';
import 'features/sales/views/accounts_receivable_screen.dart';
import 'features/inventory/views/product_stock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('es_GT', null);

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
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: dotenv.env['APP_NAME'] ?? 'Granja Avícola ERP',
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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          dotenv.env['APP_NAME'] ?? 'Mi Granja',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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

            // Sección: Accesos Rápidos (Daily Drivers)
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
                    MaterialPageRoute(
                      builder: (_) => const DailyProductionScreen(),
                    ),
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
                  title: 'Cobros (Cuentas x C.)',
                  icon: Icons.payments_outlined,
                  color: Colors.red.shade700,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountsReceivableScreen(),
                    ),
                  ),
                ),
                _QuickActionCard(
                  title: 'Stock en Existencia',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.orange.shade800,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductStockScreen(),
                    ),
                  ),
                ),
                _QuickActionCard(
                  title: 'Caja',
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.brown,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Módulo de Caja Próximamente...")),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),
            // Mensaje Inspirador / Footer
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
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

    return Drawer(
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
              user?.role ?? 'Administrador',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.indigo, size: 40),
            ),
          ),
          
          // OPERACIONES DIARIAS
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text("OPERACIONES DIARIAS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          _DrawerItem(
            icon: Icons.egg_outlined,
            label: 'Producción Diaria',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyProductionScreen())),
          ),
          _DrawerItem(
            icon: Icons.shopping_cart_outlined,
            label: 'Nueva Venta',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSaleScreen())),
          ),
          _DrawerItem(
            icon: Icons.history_edu_outlined,
            label: 'Historial de Ventas',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleListScreen())),
          ),
          _DrawerItem(
            icon: Icons.payments_outlined,
            label: 'Cobros (Cuentas x C.)',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsReceivableScreen())),
          ),
          _DrawerItem(
            icon: Icons.inventory_2_outlined,
            label: 'Stock en Existencia',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductStockScreen())),
          ),
          _DrawerItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Caja',
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Módulo de Caja Próximamente...")));
            },
          ),
          
          const Divider(),
          
          // ADMINISTRACIÓN
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text("ADMINISTRACIÓN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          _DrawerItem(
            icon: Icons.pets_outlined,
            label: 'Gestión de Lotes',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BatchListScreen())),
          ),
          _DrawerItem(
            icon: Icons.settings_outlined,
            label: 'Configuración de Precios',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductConfigScreen())),
          ),
          _DrawerItem(
            icon: Icons.people_outline,
            label: 'Gestión de Clientes',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen())),
          ),
          
          const Divider(),
          
          _DrawerItem(
            icon: Icons.logout,
            label: 'Cerrar Sesión',
            color: Colors.red,
            onTap: () => authProvider.logout(),
          ),
          const SizedBox(height: 20),
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

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
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
