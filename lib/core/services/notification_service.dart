import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Stream to listen to notification taps
  final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final dynamic tzData = await FlutterTimezone.getLocalTimezone();
      // In flutter_timezone 5.0+, it might be an object with .name
      final String timeZoneName = tzData is String ? tzData : (tzData.name ?? 'America/Guatemala');
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Final fallback
      tz.setLocalLocation(tz.getLocation('America/Guatemala'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsIOS, // Fixes macOS simulator compile crash
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        selectNotificationStream.add(response.payload);
      },
    );

    // Explicitly ask for permissions on Android 13+ 
    final androidImplementation = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    // Explicitly ask for permissions on iOS
    final iosImplementation = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // 1 hour before
    final preventiveTime = scheduledDate.subtract(const Duration(hours: 1));
    if (preventiveTime.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: id * 10, // unique id for preventive
        title: 'Próximo: $title',
        body: 'En 1 hora: $body',
        scheduledDate: preventiveTime,
        payload: id.toString(),
      );
    }

    // Exact time
    if (scheduledDate.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: id * 10 + 1, // unique id for exact
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: id.toString(),
      );
    } else {
      // If it's already past the exact time (unlikely but safe) or very close,
      // and we want some immediate feedback in-app (like a "Scheduled!" alert)
      // we can fire a one-time notification in 30 seconds as fallback
      await _scheduleNotification(
        id: id * 10 + 1,
        title: '¡Entrega hoy!: $title',
        body: 'Programado para ahora: $body',
        scheduledDate: DateTime.now().add(const Duration(seconds: 30)),
        payload: id.toString(),
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'farm_reminders',
          'Recordatorios de la Granja',
          channelDescription: 'Avisos de tareas programadas como vacunas o mantenimientos.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: 'Nueva tarea en Granja',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true, // For foreground iOS alerts
          presentList: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id * 10);
    await _flutterLocalNotificationsPlugin.cancel(id * 10 + 1);
  }
}
