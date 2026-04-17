class ScheduleModel {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final String createdByAdminId;
  final String professorId;
  final String? professorName;
  final String? adminName;
  final String? groupId;
  final String? groupName;
  final String? labId;
  final String? labName;
  final int? dayOfWeek;
  final String? startTime;
  final String? endTime;
  final int? sessionCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdByAdminId,
    required this.professorId,
    this.professorName,
    this.adminName,
    this.groupId,
    this.groupName,
    this.labId,
    this.labName,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.sessionCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdByAdminId: json['created_by_admin_id']?.toString() ?? json['createdByAdminId']?.toString() ?? '',
      professorId: json['professor_id']?.toString() ?? json['professorId']?.toString() ?? '',
      professorName: json['professor']?['user']?['name']?.toString(),
      adminName: json['createdByAdmin']?['name']?.toString(),
      groupId: json['group_id']?.toString() ?? json['groupId']?.toString(),
      groupName: json['group']?['name'],
      labId: json['lab_id'] ?? json['labId'],
      labName: json['lab']?['name'],
      dayOfWeek: json['day_of_week'] ?? json['dayOfWeek'],
      startTime: json['start_time'] ?? json['startTime'],
      endTime: json['end_time'] ?? json['endTime'],
      sessionCount: json['_count']?['sessions'],
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'professorId': professorId,
      'groupId': groupId,
      'labId': labId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
