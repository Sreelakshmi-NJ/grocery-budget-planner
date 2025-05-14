import 'package:flutter/material.dart';
import '/services/notification_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the notification service.
    NotificationService().init();
  }

  /// Sends a test notification.
  void _sendTestNotification() async {
    await NotificationService().showNotification(
      title: 'Budget Alert',
      body: 'You have reached 90% of your budget!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Notifications'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _sendTestNotification,
          child: const Text('Send Test Notification'),
        ),
      ),
    );
  }
}
