import 'package:easy_localization/easy_localization.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  String get localizedTitle {
    switch (type.toUpperCase()) {
      case 'ATTENDANCE_RECORDED':
        return 'notif_attendance_title'.tr();
      case 'SESSION_STARTED':
        return 'notif_session_start_title'.tr();
      case 'UNAUTHORIZED_ACCESS':
        if (title == 'notif_admin_alert_title') return 'notif_admin_alert_title'.tr();
        return 'notif_unauthorized_title'.tr();
      case 'WARNING':
        if (title.toLowerCase().contains('absence')) {
          return 'notif_warning_absence_title'.tr();
        }
        return title;
      default:
        return title;
    }
  }

  String get localizedBody {
    final dataMap = data ?? {};
    switch (type.toUpperCase()) {
      case 'ATTENDANCE_RECORDED':
        String course = dataMap['courseName']?.toString() ?? '';
        if (course.isEmpty && body.contains('for ')) {
          try {
            course = body.split('for ')[1].split(' has')[0];
          } catch (_) {}
        }
        return 'notif_attendance_body'.tr(args: [course]);
      case 'SESSION_STARTED':
        final parts = body.split('|');
        if (parts.length >= 3) {
          // notif_session_start_body|courseName|labName
          return parts[0].tr(args: [parts[1], parts[2]]);
        }
        return body;
      case 'UNAUTHORIZED_ACCESS':
        final parts = body.split('|');
        if (parts.length >= 3) {
          // notif_unauthorized_body|studentName|courseName
          return parts[0].tr(args: [parts[1], parts[2]]);
        } else if (parts.length == 2) {
          // notif_admin_alert_body|courseName
          return parts[0].tr(args: [parts[1]]);
        }
        return body;
      case 'WARNING':
        if (title.toLowerCase().contains('absence')) {
          return 'notif_warning_absence_body'.tr(args: [
            dataMap['absenceCount']?.toString() ?? '',
            dataMap['courseName']?.toString() ?? ''
          ]);
        }
        return body;
      default:
        return body;
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString()) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
