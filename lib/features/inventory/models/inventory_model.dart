class InventoryModel {
  final int productSizeId;
  final String name;
  final int totalUnits;
  final int cartons;
  final int leftoverUnits;
  final String formatted;

  InventoryModel({
    required this.productSizeId,
    required this.name,
    required this.totalUnits,
    required this.cartons,
    required this.leftoverUnits,
    required this.formatted,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      productSizeId: json['product_size_id'],
      name: json['name'],
      totalUnits: json['total_units'],
      cartons: json['cartons'],
      leftoverUnits: json['leftover_units'],
      formatted: json['formatted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_size_id': productSizeId,
      'name': name,
      'total_units': totalUnits,
      'cartons': cartons,
      'leftover_units': leftoverUnits,
      'formatted': formatted,
    };
  }
}
