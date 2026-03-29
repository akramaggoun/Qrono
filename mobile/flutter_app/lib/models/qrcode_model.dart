class QrCodeModel {
  final String id;
  final String token;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isRevoked;

  QrCodeModel({
    required this.id,
    required this.token,
    required this.validFrom,
    required this.validUntil,
    required this.isRevoked,
  });

  factory QrCodeModel.fromJson(Map<String, dynamic> json) {
    return QrCodeModel(
      id: json['id'],
      token: json['token'],
      validFrom: DateTime.parse(json['valid_from']),
      validUntil: DateTime.parse(json['valid_until']),
      isRevoked: json['is_revoked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'is_revoked': isRevoked,
    };
  }
}
