class GroupModel {
  final String id;
  final String name;
  final String yearLevel;
  final String specialty;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.yearLevel,
    required this.specialty,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      yearLevel: json['yearLevel']?.toString() ?? '',
      specialty: json['specialty'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'yearLevel': yearLevel,
      'specialty': specialty,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
