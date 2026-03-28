import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';
import '../../../core/services/notification_service.dart';

class ReminderProvider with ChangeNotifier {
  final ReminderService _service = ReminderService();
  final NotificationService _notificationService = NotificationService();

  List<ReminderModel> _activeReminders = [];
  List<ReminderModel> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReminderModel> get activeReminders => _activeReminders;
  List<ReminderModel> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> syncReminders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeReminders = await _service.getActiveReminders();
      
      // Reschedule all active reminders on this device
      for (final r in _activeReminders) {
        await _notificationService.scheduleReminder(
          id: r.id,
          title: r.title,
          body: r.description ?? 'Tienes una tarea programada.',
          scheduledDate: r.remindAt,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory(DateTime from, DateTime to) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _history = await _service.getHistory(from, to);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReminder(Map<String, dynamic> data) async {
    try {
      final newR = await _service.createReminder(data);
      _activeReminders.add(newR);
      _activeReminders.sort((a, b) => a.remindAt.compareTo(b.remindAt));
      
      // Schedule immediately for this device
      await _notificationService.scheduleReminder(
        id: newR.id,
        title: newR.title,
        body: newR.description ?? 'Tienes una tarea programada.',
        scheduledDate: newR.remindAt,
      );
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String> markAsDone(ReminderModel reminder) async {
    try {
      final detail = await _service.markAsDone(reminder.id);
      
      // Cancel local notifications for the closed instance
      await _notificationService.cancelReminder(reminder.id);
      
      // We remove it or simply re-sync
      _activeReminders.removeWhere((r) => r.id == reminder.id);
      notifyListeners();
      
      // Fetch fresh data in case a new future reminder was generated
      syncReminders();
      
      return detail;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
