

// PASO 1: Recolecta bruta por Lote
class BatchCollectionModel {
  final int? id;
  final int? batchId;
  final int quantity;
  final DateTime date;
  final String? type; // 'collection', 'adjustment' o 'reset'
  final String? batchName;

  BatchCollectionModel({
    this.id,
    this.batchId,
    required this.quantity,
    required this.date,
    this.type = 'collection',
    this.batchName,
  });

  factory BatchCollectionModel.fromJson(Map<String, dynamic> json) {
    return BatchCollectionModel(
      id: json['id'],
      batchId: json['batch_id'],
      quantity: json['quantity'] ?? 0,
      date: DateTime.parse(json['date']),
      type: json['type'] ?? 'collection',
      batchName: json['batch']?['name'] ?? json['batch_name'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'quantity': quantity,
      'date': date.toIso8601String(),
      'type': type,
    };
    if (batchId != null) map['batch_id'] = batchId;
    return map;
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
  final String origin; // 'harvest' o 'remnant'

  ProductionModel({
    this.id,
    this.productSizeId,
    required this.usefulQuantity,
    this.damagedQuantity = 0,
    required this.date,
    this.productSizeName,
    this.origin = 'harvest',
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
      usefulQuantity: json['useful_quantity'] ?? 0,
      damagedQuantity: json['damaged_quantity'] ?? 0,
      date: DateTime.parse(json['date']),
      productSizeName: json['product_size']?['name'],
      origin: json['origin'] ?? 'harvest',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_size_id': productSizeId,
      'useful_quantity': usefulQuantity,
      'damaged_quantity': damagedQuantity,
      'date': date.toIso8601String(),
      'origin': origin,
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

// PASO 0: Huevos en Mesa de Ayer (remanentes físicos en área de trabajo)
class TableEggModel {
  final int? id;
  final DateTime date;
  final int productSizeId;
  final int quantity;
  final String? productSizeName;

  TableEggModel({
    this.id,
    required this.date,
    required this.productSizeId,
    required this.quantity,
    this.productSizeName,
  });

  int get cartons => quantity ~/ 30;
  int get units   => quantity % 30;

  factory TableEggModel.fromJson(Map<String, dynamic> json) {
    return TableEggModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      productSizeId: json['product_size_id'],
      quantity: json['quantity'],
      productSizeName: json['product_size']?['name'],
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String().substring(0, 10),
    'product_size_id': productSizeId,
    'quantity': quantity,
  };
}

