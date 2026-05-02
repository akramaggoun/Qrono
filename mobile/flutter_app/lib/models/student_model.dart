import 'user_model.dart';

class StudentModel extends UserModel {
  final String urn;
  final String studentCode;
  final String? groupId;

  StudentModel({
    required super.id,
    required super.matricule,
    required super.fullName,
    required super.email,
    super.phone,
    required super.isActive,
    required super.createdAt,
    required this.urn,
    required this.studentCode,
    this.groupId,
  }) : super(role: 'student');

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? '',
      matricule: json['matricule'] ?? '',
      fullName: json['name'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      urn: json['urn'] ?? json['URN'] ?? json['matricule'] ?? '',
      studentCode: json['student_code'] ?? json['studentCode'] ?? '',
      groupId: json['groupId']?.toString() ?? json['group_id']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      'URN': urn,
      'student_code': studentCode,
      'group_id': groupId,
    });
    return map;
  }
}
