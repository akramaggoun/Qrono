import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? get _fcm {
    try {
      return FirebaseMessaging.instance;
    } catch (e) {
      print('⚠️ FCM instance not available (Firebase not initialized?)');
      return null;
    }
  }

  Future<void> init() async {
    final fcm = _fcm;
    if (fcm == null) return;

    // Phase 2: User registration for push notifications (HMI step)
    NotificationSettings settings = await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('🔔 Notification Permission Granted');
    } else {
      print('🔕 Notification Permission Denied');
    }

    // Foreground message handler
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Foreground Message Received: ${message.notification?.title}');
      });
    } catch (e) {}
  }

  Future<String?> getToken() async {
    final fcm = _fcm;
    if (fcm == null) return null;
    
    try {
      String? token = await fcm.getToken();
      if (token != null) {
        print('📱 FCM TOKEN GENERATED: $token');
      }
      return token;
    } catch (e) {
      print('❌ FCM Token Generation Error: $e');
      return null;
    }
  }
}
