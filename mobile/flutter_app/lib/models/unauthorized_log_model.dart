class UnauthorizedLogModel {
  final String id;
  final String scannedToken;
  final String reason;
  final DateTime occurredAt;
  final DateTime? professorNotifiedAt;
  final DateTime? adminNotifiedAt;

  UnauthorizedLogModel({
    required this.id,
    required this.scannedToken,
    required this.reason,
    required this.occurredAt,
    this.professorNotifiedAt,
    this.adminNotifiedAt,
  });

  factory UnauthorizedLogModel.fromJson(Map<String, dynamic> json) {
    return UnauthorizedLogModel(
      id: json['id'],
      scannedToken: json['scanned_token'] ?? '',
      reason: json['reason'] ?? '',
      occurredAt: DateTime.parse(json['occurred_at']),
      professorNotifiedAt: json['professor_notified_at'] != null 
          ? DateTime.parse(json['professor_notified_at']) 
          : null,
      adminNotifiedAt: json['admin_notified_at'] != null 
          ? DateTime.parse(json['admin_notified_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scanned_token': scannedToken,
      'reason': reason,
      'occurred_at': occurredAt.toIso8601String(),
      'professor_notified_at': professorNotifiedAt?.toIso8601String(),
      'admin_notified_at': adminNotifiedAt?.toIso8601String(),
    };
  }
}
