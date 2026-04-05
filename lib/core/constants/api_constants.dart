import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl {
    final platform = int.tryParse(dotenv.env['ENV_PLATFORM'] ?? '1') ?? 1;
    
    switch (platform) {
      case 1:
        return dotenv.env['URL_MAC_SIMULATOR'] ?? 'http://127.0.0.1:8000/api';
      case 2:
        return dotenv.env['URL_ANDROID_EMULATOR'] ?? 'http://10.0.2.2:8000/api';
      case 3:
        return dotenv.env['URL_PHYSICAL_DEVICE'] ?? 'http://192.168.0.23:8000/api';
      default:
        return dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000/api';
    }
  }
  
  static String get login => '$baseUrl/auth/login';
  static String get logout => '$baseUrl/auth/logout';
  static String get me => '$baseUrl/auth/me';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get resetPassword => '$baseUrl/auth/reset-password';

  // Módulo de Pedidos
  static String get orders => '$baseUrl/orders';
  static String get ordersHistory => '$baseUrl/orders/history';
  static String ordersStatus(int id) => '$baseUrl/orders/$id/status';
  static String ordersUpdate(int id) => '$baseUrl/orders/$id';

  // Módulo de Caja
  static String get expenseCategories => '$baseUrl/expense-categories';
  static String expenseCategoryUpdate(int id) => '$baseUrl/expense-categories/$id';
  static String expenseCategoryDelete(int id) => '$baseUrl/expense-categories/$id';
  static String cashTransactionUpdate(int id) => '$baseUrl/cash/transactions/$id';
}

