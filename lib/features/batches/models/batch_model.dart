class BatchModel {
  final int id;
  final String name;
  final int initialQuantity;
  final int currentQuantity;
  final DateTime acquisitionDate;
  final String status;
  final List<MortalityModel> mortalities;

  BatchModel({
    required this.id,
    required this.name,
    required this.initialQuantity,
    required this.currentQuantity,
    required this.acquisitionDate,
    required this.status,
    this.mortalities = const [],
    this.adjustments = const [],
  });

  final List<BatchAdjustmentModel> adjustments;

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'],
      name: json['name'],
      initialQuantity: json['initial_quantity'],
      currentQuantity: json['current_quantity'],
      acquisitionDate: DateTime.parse(json['acquisition_date']),
      status: json['status'],
      mortalities: json['mortalities'] != null
          ? (json['mortalities'] as List)
              .map((m) => MortalityModel.fromJson(m))
              .toList()
          : [],
      adjustments: json['adjustments'] != null
          ? (json['adjustments'] as List)
              .map((a) => BatchAdjustmentModel.fromJson(a))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'initial_quantity': initialQuantity,
      'current_quantity': currentQuantity,
      'acquisition_date': acquisitionDate.toIso8601String(),
      'status': status,
    };
  }
}

class MortalityModel {
  final int id;
  final int batchId;
  final int quantity;
  final DateTime date;
  final String? reason;

  MortalityModel({
    required this.id,
    required this.batchId,
    required this.quantity,
    required this.date,
    this.reason,
  });

  factory MortalityModel.fromJson(Map<String, dynamic> json) {
    return MortalityModel(
      id: json['id'],
      batchId: json['batch_id'],
      quantity: json['quantity'],
      date: DateTime.parse(json['date']),
      reason: json['reason'],
    );
  }
}

class BatchAdjustmentModel {
  final int id;
  final int batchId;
  final int quantity;
  final DateTime date;
  final String? reason;

  BatchAdjustmentModel({
    required this.id,
    required this.batchId,
    required this.quantity,
    required this.date,
    this.reason,
  });

  factory BatchAdjustmentModel.fromJson(Map<String, dynamic> json) {
    return BatchAdjustmentModel(
      id: json['id'],
      batchId: json['batch_id'],
      quantity: json['quantity'].runtimeType == double 
          ? (json['quantity'] as double).toInt() 
          : json['quantity'],
      date: DateTime.parse(json['date']),
      reason: json['reason'],
    );
  }
}
