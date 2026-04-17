import 'schedule_model.dart';

enum SessionStatus {
  ACTIVE,
  CLOSED;

  String get value => name;
  static SessionStatus fromString(String status) {
    return SessionStatus.values.firstWhere(
      (e) => e.name == status.toUpperCase(),
      orElse: () => SessionStatus.ACTIVE,
    );
  }
}

class SessionModel {
  final String? id;
  final String courseName;
  final String labId;
  final String groupId;
  final String professorId;
  final DateTime startTime;
  final DateTime endTime;
  final bool isRecurring;
  final String? qrToken;
  final Map<String, dynamic>? recurrence;
  final String? scheduleId;
  final ScheduleModel? schedule;
  
  // Extended fields for UI
  final SessionStatus? status;
  final String? labName;
  final String? groupName;
  final int? attendanceCount;

  SessionModel({
    this.id,
    required this.courseName,
    required this.labId,
    required this.groupId,
    required this.professorId,
    required this.startTime,
    required this.endTime,
    required this.isRecurring,
    this.qrToken,
    this.recurrence,
    this.scheduleId,
    this.schedule,
    this.status,
    this.labName,
    this.groupName,
    this.attendanceCount,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'],
      courseName: json['course_name'] ?? json['courseName'] ?? '',
      labId: json['lab_id']?.toString() ?? json['labId']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? json['groupId']?.toString() ?? '',
      professorId: json['professor_id']?.toString() ?? json['professorId']?.toString() ?? '',
      startTime: DateTime.tryParse(json['start_time'] ?? json['startTime'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['end_time'] ?? json['endTime'] ?? '') ?? DateTime.now(),
      isRecurring: json['is_recurring'] ?? json['isRecurring'] ?? false,
      qrToken: json['qr_code'] != null ? json['qr_code']['token'] : null,
      recurrence: json['recurrence'],
      scheduleId: json['schedule_id']?.toString() ?? json['scheduleId']?.toString(),
      schedule: json['schedule'] != null ? ScheduleModel.fromJson(json['schedule']) : null,
      status: json['status'] != null ? SessionStatus.fromString(json['status']) : null,
      labName: json['lab']?['name'],
      groupName: json['group']?['name'],
      attendanceCount: json['_count']?['attendance']?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'course_name': courseName,
      'lab_id': labId,
      'group_id': groupId,
      'professor_id': professorId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_recurring': isRecurring,
      'schedule_id': scheduleId,
      'recurrence': recurrence,
      'status': status?.value,
    };
  }
}
