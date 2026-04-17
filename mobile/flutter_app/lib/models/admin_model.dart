import 'user_model.dart';

class AdminModel extends UserModel {

  AdminModel({
    required super.id,
    required super.matricule,
    required super.fullName,
    required super.isActive,
    required super.createdAt,
    required super.email,
    super.phone,
  }) : super(role: 'admin');

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] ?? '',
      matricule: json['matricule'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      email: json['email'] ?? '',
      phone: json['phone'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return super.toJson();
  }
}
