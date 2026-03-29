import '../../products/models/product_size_model.dart';

class OrderItemModel {
  final int? id;
  final int orderId;
  final int productSizeId;
  final int quantity;
  final ProductSizeModel? productSize;

  OrderItemModel({
    this.id,
    required this.orderId,
    required this.productSizeId,
    required this.quantity,
    this.productSize,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      orderId: json['order_id'] ?? 0,
      productSizeId: json['product_size_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      productSize: json['product_size'] != null 
          ? ProductSizeModel.fromJson(json['product_size']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_size_id': productSizeId,
      'quantity': quantity,
    };
  }

  String get formattedQuantity {
    final cartons = quantity ~/ 30;
    final leftover = quantity % 30;
    if (cartons > 0 && leftover > 0) {
      return '$cartons ct y $leftover u';
    } else if (cartons > 0) {
      return '$cartons ct';
    } else {
      return '$quantity u';
    }
  }
}
