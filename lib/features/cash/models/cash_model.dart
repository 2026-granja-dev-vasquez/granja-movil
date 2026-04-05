

class CashBoxModel {
  final int id;
  final String? name;
  final int userId;
  final double openingBalance;
  final double? closingBalance;
  final double totalIncome;
  final double totalExpense;
  final String status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final List<CashTransactionModel> transactions;

  CashBoxModel({
    required this.id,
    this.name,
    required this.userId,
    required this.openingBalance,
    this.closingBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.status,
    required this.openedAt,
    this.closedAt,
    this.transactions = const [],
  });

  bool get isOpen => status == 'open';

  double get currentBalance => openingBalance + totalIncome - totalExpense;

  static double _parseAmount(dynamic value) {
    if (value == null || value.toString().isEmpty) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  factory CashBoxModel.fromJson(Map<String, dynamic> json) {
    return CashBoxModel(
      id: json['id'],
      name: json['name'],
      userId: json['user_id'],
      openingBalance: _parseAmount(json['opening_balance']),
      closingBalance: json['closing_balance'] != null && json['closing_balance'].toString().isNotEmpty
          ? _parseAmount(json['closing_balance'])
          : null,
      totalIncome: _parseAmount(json['total_income']),
      totalExpense: _parseAmount(json['total_expense']),
      status: json['status'],
      openedAt: DateTime.parse(json['opened_at']),
      closedAt: json['closed_at'] != null && json['closed_at'].toString().isNotEmpty
          ? DateTime.parse(json['closed_at'])
          : null,
      transactions: json['transactions'] != null 
        ? (json['transactions'] as List).map((t) => CashTransactionModel.fromJson(t)).toList() 
        : [],
    );
  }
}

class CashTransactionModel {
  final int id;
  final int cashBoxId;
  final String type;
  final double amount;
  final String category;
  final String? description;
  final String status;
  final String? voidReason;
  final DateTime createdAt;

  CashTransactionModel({
    required this.id,
    required this.cashBoxId,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    this.status = 'active',
    this.voidReason,
    required this.createdAt,
  });

  bool get isVoided => status == 'voided';

  bool get isIncome => type == 'income';

  static double _parseAmount(dynamic value) {
    if (value == null || value.toString().isEmpty) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  factory CashTransactionModel.fromJson(Map<String, dynamic> json) {
    return CashTransactionModel(
      id: json['id'],
      cashBoxId: json['cash_box_id'],
      type: json['type'],
      amount: _parseAmount(json['amount']),
      category: json['category'],
      description: json['description'],
      status: json['status'] ?? 'active',
      voidReason: json['void_reason'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
