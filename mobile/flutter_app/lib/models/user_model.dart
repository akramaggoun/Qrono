enum UserRole {
  admin,
  professor,
  student;

  String get value => name;
  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name == role.toLowerCase(),
      orElse: () => UserRole.student,
    );
  }
}

class UserModel {
  final String id;
  final String matricule;  // URN or University ID
  final String fullName;   // First & Last Name
  final String email;
  final String? phone;
  final UserRole role;       // admin, professor, student
  final bool isActive;
  final DateTime createdAt;
  final String? department;
  final String? profileId; // Professor/Student/Admin actual ID

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
    this.profileId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      matricule: json['matricule'] ?? '',
      fullName: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      role: UserRole.fromString(json['role'] ?? 'student'),
      department: json['department'],
      profileId: json['profileId'],
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
      'role': role.value,
      'department': department,
      'profileId': profileId,
    };
  }
}
