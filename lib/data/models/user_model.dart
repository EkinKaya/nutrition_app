class UserModel {
  final String id;
  final String email;
  final String? name;
  final int? age;
  final double? weight;
  final double? height;
  final String? gender;
  final String? dietType;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.age,
    this.weight,
    this.height,
    this.gender,
    this.dietType,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'],
      age: map['age'],
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      gender: map['gender'],
      dietType: map['dietType'],
      createdAt: map['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'dietType': dietType,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    double? weight,
    double? height,
    String? gender,
    String? dietType,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      dietType: dietType ?? this.dietType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
