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
      id: json['id'],
      name: json['name'],
      yearLevel: json['year_level'] ?? '',
      specialty: json['specialty'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'year_level': yearLevel,
      'specialty': specialty,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
