import '../../products/models/product_size_model.dart';

class OrderItemModel {
  final int? id;
  final int orderId;
  final int productSizeId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final ProductSizeModel? productSize;

  OrderItemModel({
    this.id,
    required this.orderId,
    required this.productSizeId,
    required this.quantity,
    this.unitPrice = 0,
    this.subtotal = 0,
    this.productSize,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      orderId: json['order_id'] ?? 0,
      productSizeId: json['product_size_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
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

  String get formattedQuantity {
    final cartons = quantity ~/ 30;
    final leftover = quantity % 30;
    if (cartons > 0 && leftover > 0) {
      return '$cartons cartones y $leftover unidades';
    } else if (cartons > 0) {
      return '$cartons ${cartons == 1 ? 'cartón' : 'cartones'}';
    } else {
      return '$quantity ${quantity == 1 ? 'unidad' : 'unidades'}';
    }
  }
}
