class ReminderModel {
  final int id;
  final String title;
  final String? description;
  final DateTime remindAt;
  final String frequency; // once, custom_days, monthly
  final int? intervalDays;
  final bool isDone;
  final DateTime? completedAt;

  ReminderModel({
    required this.id,
    required this.title,
    this.description,
    required this.remindAt,
    required this.frequency,
    this.intervalDays,
    required this.isDone,
    this.completedAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    // Laravel sends dates like '2026-03-28T17:12:00.000000Z' which Flutter parses as UTC.
    // We want the literal clock face (17:12) to be treated as local time.
    final rawRemind = json['remind_at'].toString().replaceAll('Z', '');
    final rawCompleted = json['completed_at']?.toString().replaceAll('Z', '');

    return ReminderModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      remindAt: DateTime.parse(rawRemind),
      frequency: json['frequency'],
      intervalDays: json['interval_days'],
      isDone: json['is_done'] == 1 || json['is_done'] == true,
      completedAt: rawCompleted != null ? DateTime.parse(rawCompleted) : null,
    );
  }
}
