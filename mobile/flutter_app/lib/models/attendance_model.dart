enum AttendanceMethod {
  qr,
  manual;

  String get value => name;

  static AttendanceMethod fromString(String method) {
    return AttendanceMethod.values.firstWhere(
      (e) => e.name == method.toLowerCase(),
      orElse: () => AttendanceMethod.qr,
    );
  }
}

class AttendanceModel {
  final String id;
  final String studentId;
  final String sessionId;
  final DateTime? checkedInAt;
  final AttendanceMethod method;
  final String status;
  
  // Optional for UI
  final String? courseName;
  final String? labName;
  final String? studentName;
  final String? urn;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.sessionId,
    this.checkedInAt,
    required this.method,
    required this.status,
    this.courseName,
    this.labName,
    this.studentName,
    this.urn,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? 'none',
      studentId: json['student_id'] ?? json['studentId'] ?? '',
      sessionId: json['session_id'] ?? json['sessionId'] ?? '',
      checkedInAt: DateTime.tryParse(json['checkInAt'] ?? json['check_in_at'] ?? ''),
      method: json['method'] != null ? AttendanceMethod.fromString(json['method']) : AttendanceMethod.qr,
      status: json['status'] ?? 'present',
      courseName: json['session']?['courseName'] ?? json['session']?['course_name'],
      labName: json['session']?['lab']?['name'],
      studentName: json['student']?['user']?['name'],
      urn: json['student']?['URN'] ?? json['student']?['urn'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'session_id': sessionId,
      'checked_in_at': checkedInAt?.toIso8601String(),
      'method': method.value,
      'status': status,
    };
  }
}
