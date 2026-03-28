import 'customer_model.dart';
import '../../products/models/product_size_model.dart';

enum SaleStatus { pending, paid, partial }

class SaleModel {
  final int? id;
  final int? customerId;
  final double totalAmount;
  final double paidAmount;
  final SaleStatus status;
  final DateTime date;
  final String? notes;
  final CustomerModel? customer;
  final List<SaleItemModel> items;

  SaleModel({
    this.id,
    this.customerId,
    required this.totalAmount,
    this.paidAmount = 0,
    this.status = SaleStatus.pending,
    required this.date,
    this.notes,
    this.customer,
    this.items = const [],
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    SaleStatus status;
    switch (json['status']) {
      case 'paid':
        status = SaleStatus.paid;
        break;
      case 'partial':
        status = SaleStatus.partial;
        break;
      default:
        status = SaleStatus.pending;
    }

    return SaleModel(
      id: json['id'],
      customerId: json['customer_id'],
      totalAmount: double.parse(json['total_amount'].toString()),
      paidAmount: double.parse(json['paid_amount'].toString()),
      status: status,
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      customer: json['customer'] != null ? CustomerModel.fromJson(json['customer']) : null,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => SaleItemModel.fromJson(i)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'status': status.name,
      'date': date.toIso8601String().split('T')[0],
      'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class SaleItemModel {
  final int? id;
  final int? saleId;
  final int productSizeId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final ProductSizeModel? productSize;

  SaleItemModel({
    this.id,
    this.saleId,
    required this.productSizeId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.productSize,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'],
      saleId: json['sale_id'],
      productSizeId: json['product_size_id'],
      quantity: json['quantity'],
      unitPrice: double.parse(json['unit_price'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      productSize: json['product_size'] != null 
          ? ProductSizeModel.fromJson(json['product_size']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_size_id': productSizeId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }
}
