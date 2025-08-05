class Pairing {
  final String id;
  final String secret;
  final String myName;
  final String partnerName;
  final DateTime createdAt;

  Pairing({
    required this.id,
    required this.secret,
    required this.myName,
    required this.partnerName,
    required this.createdAt,
  });

  // Create a new pairing
  factory Pairing.create({
    required String secret,
    required String myName,
    required String partnerName,
  }) {
    return Pairing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      secret: secret,
      myName: myName,
      partnerName: partnerName,
      createdAt: DateTime.now(),
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'secret': secret,
      'myName': myName,
      'partnerName': partnerName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory Pairing.fromJson(Map<String, dynamic> json) {
    return Pairing(
      id: json['id'] as String,
      secret: json['secret'] as String,
      myName: json['myName'] as String,
      partnerName: json['partnerName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Create a copy with updated fields
  Pairing copyWith({
    String? id,
    String? secret,
    String? myName,
    String? partnerName,
    DateTime? createdAt,
  }) {
    return Pairing(
      id: id ?? this.id,
      secret: secret ?? this.secret,
      myName: myName ?? this.myName,
      partnerName: partnerName ?? this.partnerName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pairing && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Pairing(id: $id, myName: $myName, partnerName: $partnerName)';
  }
} 