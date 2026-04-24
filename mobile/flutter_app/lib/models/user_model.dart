class UserModel {
  final String id;
  final String matricule;  // URN or University ID
  final String fullName;   // First & Last Name
  final String email;
  final String? phone;
  final String role;       // admin, professor, student
  final bool isActive;
  final DateTime createdAt;
  final String? department;

  UserModel({
    required this.id,
    required this.matricule,
    required this.fullName,
    required this.email,
    this.phone,
    required this.isActive,
    required this.createdAt,
    required this.role,
    this.department,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      matricule: json['matricule'] ?? '',
      fullName: json['name'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      role: json['role']?.toString().toLowerCase() ?? 'student',
      department: json['department'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricule': matricule,
      'name': fullName,
      'email': email,
      'phone': phone,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'role': role,
      'department': department,
    };
  }
}
