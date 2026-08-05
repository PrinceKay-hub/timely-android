import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/*@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {


  // Initialize local notifications plugin
  final FlutterLocalNotificationsPlugin localPlugin =
      FlutterLocalNotificationsPlugin();

  // Show the notification
  await localPlugin.show(
    id: message.data.hashCode,
    title:  message.notification?.title,
    body:  message.notification?.body,
    payload: message.data.toString(),
  );
}*/

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize local notifications plugin (must be done in the isolate)
  final FlutterLocalNotificationsPlugin localPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
  await localPlugin.initialize(settings: initializationSettings);

  final payload = jsonEncode({
    'type': message.data['type'] ?? 'chat',
    'chatId': message.data['chatId'] ?? '',
  });

  await localPlugin.show(
    id: message.data.hashCode,
    title: message.notification?.title ?? message.data['title'] ?? 'New message',
    body: message.notification?.body ?? message.data['body'] ?? 'You have a new notification',
    payload: payload,
  );
}