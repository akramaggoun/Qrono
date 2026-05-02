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
      debugPrint('⚠️ FCM instance not available (Firebase not initialized?)');
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
      debugPrint('🔔 Notification Permission Granted');
    } else {
      debugPrint('🔕 Notification Permission Denied');
    }

    // Foreground message handler
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 Foreground Message Received: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('Error setting up foreground message handler: $e');
    }
  }

  Future<String?> getToken() async {
    final fcm = _fcm;
    if (fcm == null) return null;
    
    try {
      String? token = await fcm.getToken();
      if (token != null) {
        debugPrint('📱 FCM TOKEN GENERATED: $token');
      }
      return token;
    } catch (e) {
      debugPrint('❌ FCM Token Generation Error: $e');
      return null;
    }
  }
}
