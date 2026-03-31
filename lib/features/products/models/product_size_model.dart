class ProductSizeModel {
  final int id;
  final String name;
  final double unitPrice;
  final double cartonPrice;
  final double boxPrice;
  final bool isActive;

  ProductSizeModel({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.cartonPrice,
    required this.boxPrice,
    required this.isActive,
  });

  factory ProductSizeModel.fromJson(Map<String, dynamic> json) {
    return ProductSizeModel(
      id: json['id'],
      name: json['name'],
      unitPrice: double.parse((json['unit_price'] ?? 0).toString()),
      cartonPrice: double.parse((json['carton_price'] ?? 0).toString()),
      boxPrice: double.parse((json['box_price'] ?? 0).toString()),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit_price': unitPrice,
      'carton_price': cartonPrice,
      'box_price': boxPrice,
      'is_active': isActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductSizeModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
