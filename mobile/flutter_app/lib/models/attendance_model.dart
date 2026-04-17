class AttendanceModel {
  final String id;
  final String studentId;
  final String sessionId;
  final DateTime checkedInAt;
  final String method; // 'qr' or 'manual'
  final String status; // 'Present', 'Absent', etc.

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.checkedInAt,
    required this.method,
    required this.status,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      studentId: json['student_id'],
      sessionId: json['session_id'],
      checkedInAt: DateTime.parse(json['checked_in_at']),
      method: json['method'] ?? 'qr',
      status: json['status'] ?? 'Present',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'session_id': sessionId,
      'checked_in_at': checkedInAt.toIso8601String(),
      'method': method,
      'status': status,
    };
  }
}
