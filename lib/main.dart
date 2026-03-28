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
      supportedLocales: const [
        Locale('es', 'GT'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.orange,
        primaryColor: Colors.orange,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (auth.isAuthenticated) {
            return const DashboardPlaceholder();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}

class DashboardPlaceholder extends StatelessWidget {
  const DashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.dashboard_outlined,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'Bienvenido, ${user?.name ?? 'Usuario'}',
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              'Rol: ${user?.role ?? 'N/A'}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            // Botón para acceder al Módulo 2
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BatchListScreen()),
                ),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text(
                  'Gestión de Lotes',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductConfigScreen(),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
                label: const Text(
                  'Tamaño y precio de huevos',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DailyProductionScreen(),
                  ),
                ),
                icon: const Icon(Icons.egg_outlined),
                label: const Text(
                  'Producción Diaria',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Módulo 1, 2, 3 & 4 operativos.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
