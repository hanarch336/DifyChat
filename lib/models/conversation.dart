class Conversation {
  final String id;
  String name;
  DateTime createdAt;
  DateTime updatedAt;

  Conversation({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      name: json['name'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] * 1000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] * 1000),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
  };
  
  Conversation copyWith({
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}