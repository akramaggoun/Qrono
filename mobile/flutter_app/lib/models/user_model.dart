class UserModel {
  final String id;
  final String matricule;  // URN or University ID
  final String fullName;   // First & Last Name
  final String email;
  final String? phone;
  final String role;       // admin, professor, student
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.matricule,
    required this.fullName,
    required this.email,
    this.phone,
    required this.isActive,
    required this.createdAt,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      matricule: json['matricule'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      role: json['role'] ?? 'student',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricule': matricule,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'role': role,
    };
  }
}
