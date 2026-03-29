import '../../sales/models/customer_model.dart';
import 'package:intl/intl.dart';

class OrderModel {
  final int id;
  final int customerId;
  final DateTime deliveryDate;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final CustomerModel? customer;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.deliveryDate,
    required this.status,
    this.notes,
    required this.createdAt,
    this.customer,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      customerId: json['customer_id'],
      deliveryDate: DateTime.parse(json['delivery_date']).toLocal(),
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      customer: json['customer'] != null ? CustomerModel.fromJson(json['customer']) : null,
    );
  }

  // Helper getters for UI
  bool get isPending => status == 'pending';
  bool get isDelivered => status == 'delivered';
  bool get isPostponed => status == 'postponed';
  bool get isCancelled => status == 'cancelled';

  bool get isOverdue {
    if (isDelivered || isCancelled) return false;
    return DateTime.now().isAfter(deliveryDate);
  }

  String get formattedDeliveryDate {
    return DateFormat('EEE d MMM, hh:mm a', 'es_GT').format(deliveryDate);
  }
}
