import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

 @pragma('vm:entry-point')
  Future<void> _firebaseMessagingBGHandler(RemoteMessage message) async {
    //await _handleForegroundMessage(message);
    print('Handling a background message: ${message.messageId}');
    await showLocalNotification(message);
  
  }

  Future<void> showLocalNotification(RemoteMessage message) async {
  // Initialize flutter_local_notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Android settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

  // Create notification details
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'appointment_channel',
    'Appointment Notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: DarwinNotificationDetails(),
  );

  // Show the notification
  await flutterLocalNotificationsPlugin.show(
   id: message.data.hashCode, // unique id
   title:  message.notification?.title ?? message.data['title'] ?? 'Appointment Update',
   body:  message.notification?.body ?? message.data['body'] ?? 'You have a new notification',
   notificationDetails:  platformChannelSpecifics,
  );
}

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();


  void initInfo() async {
    await _setupNotifications();
    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!: ${message.data}');
      // Handle navigation or other actions based on message data
    });
  }

  Future<void> _setupNotifications() async {
  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(settings: initializationSettings);

}

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
   
    await _showLocalNotification(
        title: message.notification?.title,
        body: message.notification?.body,
        payload: message.data.toString(),
      );
  }

  Future<void> _showLocalNotification({
  String? title,
  String? body,
  String? payload,
}) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'appointment_channel',
    'Appointment Notifications',
    channelDescription: 'Notifications when app is in foreground',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

  await _notificationsPlugin.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: payload,
  );
}



}
