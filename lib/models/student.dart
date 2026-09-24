class Student {
  final String id;
  final String name;
  final String email;
  final DateTime addedAt;

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'addedAt': addedAt.toIso8601String(),
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as String,
        name: json['name'] as String,
        email: (json['email'] as String?) ?? '',
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}
