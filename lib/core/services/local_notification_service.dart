import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? navigatorKey;

  void initInfo({required GlobalKey<NavigatorState>? navigatorKey}) {
    this.navigatorKey = navigatorKey;
    _setupNotifications();
    _requestPermissions();
    _setupListeners();
  }

  Future<void> _setupNotifications() async {
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

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Called when a local notification is tapped (including when app is terminated)
        _handleNavigation(response.payload);
      },
    );
  }

  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void _setupListeners() {
    // Foreground messages (app is visible)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        title: message.notification?.title,
        body: message.notification?.body,
        payload: _buildPayload(message.data),
      );
    });

    // App opened from a notification (background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(_buildPayload(message.data));
    });

    // App launched from terminated state with a notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNavigation(_buildPayload(message.data));
      }
    });
  }

  // Build a JSON‑string payload containing type and chatId
  String _buildPayload(Map<String, dynamic> data) {
    return jsonEncode({
      'type': data['type'] ?? 'chat',
      'chatId': data['chatId'] ?? '',
    });
  }

  // Show local notification when app is in foreground
  Future<void> _showLocalNotification({
    String? title,
    String? body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }

  // Navigation helper
  void _handleNavigation(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;
      final chatId = data['chatId'] as String?;
      if (type == 'chat' && chatId != null && chatId.isNotEmpty) {
        final context = navigatorKey?.currentContext;
        if (context != null) {
          // Use GoRouter to navigate to the chat screen
          GoRouter.of(context).push('/chat/$chatId');
        }
      }
    } catch (e) {
      print('Navigation error: $e');
    }
  }
}