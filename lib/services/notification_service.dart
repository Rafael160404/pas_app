import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    print('📱 Initializing notifications...');

    if (kIsWeb) {
      print('⚠️ Notifications not supported on web');
      return;
    }

    await _requestPermissions();
    await _setupLocalNotifications();
    await _getFCMToken();
    _setupMessageHandlers();

    print('✅ Notification service initialized');
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ User granted provisional permission');
    } else {
      print('❌ User declined permission');
    }
  }

  Future<void> _setupLocalNotifications() async {
    // Android setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS setup (Darwin)
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    // Initialization
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        _handleNotificationTap(payload);
      },
    );

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('\n' + '=' * 50);
        print('🔥 FCM TOKEN:');
        print(token);
        print('=' * 50 + '\n');
      } else {
        print('❌ No FCM token available');
      }

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('\n' + '=' * 50);
        print('🔄 NEW FCM TOKEN:');
        print(newToken);
        print('=' * 50 + '\n');
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message received');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Background message opened');
      _handleNotificationTap(message.data.toString());
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('🚀 App launched from terminated state via notification');
        _handleNotificationTap(message.data.toString());
      }
    });

    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      0, // id
      notification.title ?? '',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data.toString(),
    );
  }

  void _handleNotificationTap(String? payload) {
    print('👆 Notification tapped with payload: $payload');
  }
}

// Background handler
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  print('📨 Background message: ${message.messageId}');
  print('Data: ${message.data}');
}