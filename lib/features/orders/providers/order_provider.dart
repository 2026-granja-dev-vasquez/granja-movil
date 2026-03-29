import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final _authService = AuthService();
  final _notificationService = NotificationService();
  
  List<OrderModel> _pendingOrders = [];
  List<OrderModel> _historyOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get pendingOrders => _pendingOrders;
  List<OrderModel> get historyOrders => _historyOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchPendingOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final url = Uri.parse(ApiConstants.orders);
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _pendingOrders = data.map((e) => OrderModel.fromJson(e)).toList();
      } else {
        _errorMessage = 'Error al cargar pedidos';
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistoryOrders({DateTime? start, DateTime? end}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      String query = '';
      if (start != null && end != null) {
        final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
        final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
        query = '?start_date=$startStr&end_date=$endStr';
      }
      
      final url = Uri.parse('${ApiConstants.ordersHistory}$query');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _historyOrders = data.map((e) => OrderModel.fromJson(e)).toList();
      } else {
        _errorMessage = 'Error al cargar historial';
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder(int customerId, DateTime deliveryDate, List<Map<String, dynamic>> items, {String? notes}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final url = Uri.parse(ApiConstants.orders);
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customer_id': customerId,
          'delivery_date': deliveryDate.toUtc().toIso8601String(),
          'items': items,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        final newOrder = OrderModel.fromJson(jsonDecode(response.body));
        _pendingOrders.add(newOrder);
        
        // Arrange Notification 1 hour before
        await _scheduleOrderNotification(newOrder);
        
        // Sort
        _pendingOrders.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
        return true;
      } else {
        _errorMessage = 'Error al crear pedido';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de red: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(int orderId, String status, {DateTime? newDate, String? notes}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final url = Uri.parse(ApiConstants.ordersStatus(orderId));
      
      final Map<String, dynamic> payload = {'status': status};
      if (newDate != null) {
        payload['delivery_date'] = newDate.toUtc().toIso8601String();
      }
      if (notes != null) payload['notes'] = notes;

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final updatedOrder = OrderModel.fromJson(jsonDecode(response.body));
        
        // Remove from pending list
        _pendingOrders.removeWhere((o) => o.id == orderId);

        if (status == 'delivered' || status == 'cancelled') {
             // It goes to history
             _historyOrders.insert(0, updatedOrder);
             _cancelOrderNotification(orderId);
        } else if (status == 'postponed') {
             // Stay in pending, just updated
             _pendingOrders.add(updatedOrder);
             _pendingOrders.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
             
             // Reschedule Notification
             await _cancelOrderNotification(orderId);
             await _scheduleOrderNotification(updatedOrder);
        }
        
        return true;
      } else {
        _errorMessage = 'Error al actualizar estado del pedido';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de red: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method for notifications using an offset id to avoid conflicts with standard reminders
  Future<void> _scheduleOrderNotification(OrderModel order) async {
    // Passing the actual delivery date; the service will handle the 1-hour-before logic
    try {
      String itemSummary = order.items.map((i) => '${i.formattedQuantity} ${i.productSize?.name ?? ''}').join(', ');
      if (order.notes != null && order.notes!.isNotEmpty) {
        itemSummary += '\nNota: ${order.notes}';
      }

      await _notificationService.scheduleReminder(
        id: order.id + 100000, 
        title: 'Pedido de: ${order.customer?.name ?? 'Cliente'}',
        body: 'Entregar: $itemSummary',
        scheduledDate: order.deliveryDate,
      );
    } catch (e) {
      // Log gracefully
      debugPrint('Notification warning: Could not schedule notification $e');
    }
  }

  Future<void> _cancelOrderNotification(int orderId) async {
    try {
      await _notificationService.cancelReminder(orderId + 100000);
    } catch (e) {
       debugPrint('Notification warning: Could not cancel notification $e');
    }
  }
}
