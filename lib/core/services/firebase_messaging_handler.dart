import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
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
}