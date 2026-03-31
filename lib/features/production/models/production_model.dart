

// PASO 1: Recolecta bruta por Lote
class BatchCollectionModel {
  final int? id;
  final int batchId;
  final int quantity;
  final DateTime date;
  final String? batchName;

  BatchCollectionModel({
    this.id,
    required this.batchId,
    required this.quantity,
    required this.date,
    this.batchName,
  });

  factory BatchCollectionModel.fromJson(Map<String, dynamic> json) {
    return BatchCollectionModel(
      id: json['id'],
      batchId: json['batch_id'],
      quantity: json['quantity'],
      date: DateTime.parse(json['date']),
      batchName: json['batch']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_id': batchId,
      'quantity': quantity,
      'date': date.toIso8601String(),
    };
  }
}

// PASO 2: Clasificación de Inventario por Tamaño
class ProductionModel {
  final int? id;
  final int? productSizeId; // Ahora opcional para quebrados globales
  final int usefulQuantity;
  final int damagedQuantity;
  final DateTime date;
  final String? productSizeName;

  ProductionModel({
    this.id,
    this.productSizeId,
    required this.usefulQuantity,
    this.damagedQuantity = 0,
    required this.date,
    this.productSizeName,
  });

  // Cálculos de cartones (Base 30)
  int get cartons => usefulQuantity ~/ 30;
  int get units => usefulQuantity % 30;

  String get formattedCollection => "$cartons cartones y $units $label";
  String get label => units == 1 ? "huevo" : "huevos";

  factory ProductionModel.fromJson(Map<String, dynamic> json) {
    return ProductionModel(
      id: json['id'],
      productSizeId: json['product_size_id'],
      usefulQuantity: json['useful_quantity'],
      damagedQuantity: json['damaged_quantity'] ?? 0,
      date: DateTime.parse(json['date']),
      productSizeName: json['product_size']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_size_id': productSizeId,
      'useful_quantity': usefulQuantity,
      'damaged_quantity': damagedQuantity,
      'date': date.toIso8601String(),
    };
  }
}

class ConsolidationModel {
  final int productSizeId;
  final String productSize;
  final int totalUnits;
  final int cartons;
  final int leftoverUnits;
  final String formatted;

  ConsolidationModel({
    required this.productSizeId,
    required this.productSize,
    required this.totalUnits,
    required this.cartons,
    required this.leftoverUnits,
    required this.formatted,
  });

  factory ConsolidationModel.fromJson(Map<String, dynamic> json) {
    return ConsolidationModel(
      productSizeId: json['product_size_id'],
      productSize: json['product_size'],
      totalUnits: json['total_units'],
      cartons: json['cartons'],
      leftoverUnits: json['leftover_units'],
      formatted: json['formatted'],
    );
  }
}
