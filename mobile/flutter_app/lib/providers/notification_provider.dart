import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/notification_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationProvider extends ChangeNotifier {
  final _apiClient = ApiClient();
  IO.Socket? _socket;

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

    // Use dynamic base URL for wireless access support
    final socketUrl = ApiConstants.isWirelessAccess
        ? ApiConstants.baseUrl.replaceAll('/api', '')  // Remove /api suffix
        : 'http://localhost:3000';  // Default for local development

    print('📡 Connecting to Notification Socket for user: $userId');
    print('🌐 Socket URL: $socketUrl (${ApiConstants.connectionType})');

    _socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setQuery({'userId': userId})
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      print('✅ Connected to Notification Server (${ApiConstants.connectionType})');
    });

    _socket!.on('notification:new', (data) {
      print('📩 New real-time notification received!');
      fetchNotifications(); // Auto-refresh list
    });

    _socket!.onDisconnect((_) => print('❌ Disconnected from Notification Server'));
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
