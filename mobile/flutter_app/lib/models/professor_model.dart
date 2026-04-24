import 'user_model.dart';

class ProfessorModel extends UserModel {
  final String professorCode;
  final String department;

  ProfessorModel({
    required super.id,
    required super.matricule,
    required super.fullName,
    required super.isActive,
    required super.createdAt,
    required super.email,
    required this.professorCode,
    required this.department,
    super.phone,
  }) : super(role: 'professor');

  factory ProfessorModel.fromJson(Map<String, dynamic> json) {
    return ProfessorModel(
      id: json['id'] ?? '',
      matricule: json['matricule'] ?? '',
      fullName: json['name'] ?? json['full_name'] ?? '',
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      email: json['email'] ?? '',
      professorCode: json['professor_code'] ?? json['professorCode'] ?? json['matricule'] ?? '',
      department: json['department'] ?? '',
      phone: json['phone'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      'professor_code': professorCode,
      'department': department,
    });
    return map;
  }
}
