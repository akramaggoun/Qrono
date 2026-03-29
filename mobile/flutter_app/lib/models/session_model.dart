class SessionModel {
  final String? id;
  final String courseName;
  final String labId;
  final String groupId;
  final String professorId;
  final DateTime startTime;
  final DateTime endTime;
  final bool isRecurring;
  final Map<String, dynamic>? recurrence;

  SessionModel({
    this.id,
    required this.courseName,
    required this.labId,
    required this.groupId,
    required this.professorId,
    required this.startTime,
    required this.endTime,
    required this.isRecurring,
    this.recurrence,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'],
      courseName: json['course_name'],
      labId: json['lab_id'].toString(),
      groupId: json['group_id'].toString(),
      professorId: json['professor_id'].toString(),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      isRecurring: json['is_recurring'] ?? false,
      recurrence: json['recurrence'],
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
      'recurrence': recurrence,
    };
  }
}
