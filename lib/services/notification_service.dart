// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios));
  }

  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
    bool isCritical = false,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'iot_alerts',
          'Alertas IoT',
          channelDescription: 'Alertas del sistema IoT Achocalla',
          importance: isCritical ? Importance.max : Importance.high,
          priority: isCritical ? Priority.max : Priority.high,
          color: isCritical ? const Color(0xFFFF3B3B) : const Color(0xFF0D7BF5),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: isCritical
              ? InterruptionLevel.critical
              : InterruptionLevel.active,
        ),
      ),
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
}
