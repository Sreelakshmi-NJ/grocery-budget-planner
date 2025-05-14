import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone data.
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      // Add iOS settings here if needed.
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Shows an immediate notification.
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'budget_channel', // Channel ID
      'Budget Notifications', // Channel name
      channelDescription: 'Alerts when spending nears or exceeds your budget',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      details,
      payload: 'Budget Payload',
    );
  }

  /// Schedules a notification to be shown at a future [scheduledDate].
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'expiry_channel', // Channel ID for expiry alerts
      'Expiry Alerts', // Channel name
      channelDescription: 'Alerts when a pantry item expires',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // Convert the scheduledDate to a timezone-aware DateTime.
    final tz.TZDateTime scheduledTZDate =
        tz.TZDateTime.from(scheduledDate, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, // Unique notification id.
      title,
      body,
      scheduledTZDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // New required parameter for scheduling notifications:
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'Expiry Alert',
    );
  }
}
