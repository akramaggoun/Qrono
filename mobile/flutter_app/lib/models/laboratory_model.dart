class LaboratoryModel {
  final String id;
  final String name;
  final String building;
  final String roomNumber;
  final int capacity;
  final bool isActive;

  LaboratoryModel({
    required this.id,
    required this.name,
    required this.building,
    required this.roomNumber,
    required this.capacity,
    required this.isActive,
  });

  factory LaboratoryModel.fromJson(Map<String, dynamic> json) {
    return LaboratoryModel(
      id: json['id'],
      name: json['name'],
      building: json['building'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      capacity: json['capacity'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'building': building,
      'roomNumber': roomNumber,
      'capacity': capacity,
      'isActive': isActive,
    };
  }
}
