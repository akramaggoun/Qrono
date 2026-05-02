import 'dart:convert';
import '../core/network/api_client.dart';
import '../models/notification_model.dart';
import '../core/config/api_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:audioplayers/audioplayers.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  final _apiClient = ApiClient();
  io.Socket? _socket;
  final _audioPlayer = AudioPlayer();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  // ═══════════════════════════════
  //  REAL-TIME SOCKET INIT (Phase 2)
  // ═══════════════════════════════

  void initSocket(String userId) {
    if (_socket != null) return;

    final socketUrl = ApiConfig.socketBaseUrl;

    debugPrint('📡 Connecting to Notification Socket for user: $userId');
    debugPrint('🌐 Socket URL: $socketUrl (${ApiConfig.connectionType})');

    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setQuery({'userId': userId})
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      debugPrint('✅ Connected to Notification Server (${ApiConfig.connectionType})');
    });

    _socket!.on('notification:new', (data) {
      try {
        final notification = NotificationModel.fromJson(data);
        _showPopup(notification);
        _playSound(notification.type);
      } catch (e) {
        debugPrint('⚠️ Error parsing real-time notification: $e');
      }
      fetchNotifications();
    });

    _socket!.onDisconnect((_) => debugPrint('❌ Disconnected from Notification Server'));
  }

  void _playSound(String type) async {
    try {
      await _audioPlayer.stop(); // Stop any currently playing audio properly
      String soundFile;
      switch (type.toUpperCase()) {
        case 'WARNING':
        case 'ERROR':
        case 'CRITICAL':
        case 'UNAUTHORIZED_ACCESS':
          soundFile = 'sounds/warning.mp3';
          break;
        case 'SUCCESS':
        case 'ATTENDANCE_RECORDED':
          soundFile = 'sounds/success.mp3';
          break;
        case 'INFO':
        case 'SESSION_STARTED':
        default:
          soundFile = 'sounds/info.mp3';
      }
      await _audioPlayer.play(AssetSource(soundFile));
    } catch (e) {
      debugPrint('⚠️ Could not play notification sound: $e');
    }
  }

  void _showPopup(NotificationModel notification) {
    Color bgColor;
    IconData icon;

    switch (notification.type.toUpperCase()) {
      case 'WARNING':
      case 'CRITICAL':
      case 'UNAUTHORIZED_ACCESS':
        bgColor = Colors.red.shade800; // Changed from orange to red
        icon = Icons.warning_amber_rounded;
        break;
      case 'ERROR':
        bgColor = Colors.red.shade900;
        icon = Icons.error_outline_rounded;
        break;
      case 'SUCCESS':
      case 'ATTENDANCE_RECORDED':
        bgColor = Colors.green.shade800;
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        bgColor = Colors.blue.shade800;
        icon = Icons.notifications_active_rounded;
    }

    showSimpleNotification(
      Text(
        notification.localizedTitle,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        notification.localizedBody,
        style: const TextStyle(color: Colors.white70),
      ),
      leading: Icon(icon, color: Colors.white, size: 30),
      background: bgColor,
      duration: const Duration(seconds: 4),
      elevation: 4,
      slideDismissDirection: DismissDirection.horizontal,
    );
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
  }

  // ═══════════════════════════════
  //  SCENARIO 5 — READ NOTIFICATIONS (UML)
  // ═══════════════════════════════

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/notifications');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['notifications'];
        _notifications = data.map((n) => NotificationModel.fromJson(n)).toList();
        _updateUnreadCount();
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _apiClient.patch('/notifications/$id/read', {});
      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          // Local update for better UX
          final old = _notifications[index];
          _notifications[index] = NotificationModel(
            id: old.id,
            type: old.type,
            title: old.title,
            body: old.body,
            data: old.data,
            isRead: true,
            createdAt: old.createdAt,
          );
          _updateUnreadCount();
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint("Error marking notification read: $e");
    }
    return false;
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.patch('/notifications/read-all', {});
      if (response.statusCode == 200) {
        _notifications = _notifications.map((n) => NotificationModel(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        )).toList();
        _unreadCount = 0;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error marking all as read: $e");
    }
    return false;
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  // NOTE: On real device, FCM setup would be here to call fetchNotifications 
  // when a background message is received or app is opened via notification.
}

