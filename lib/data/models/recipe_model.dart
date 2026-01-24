class RecipeModel {
  final String id;
  final String title;
  final String imageUrl;
  final String duration;
  final String calories;
  final String difficulty;
  final List<String>? ingredients;
  final List<String>? instructions;

  RecipeModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.duration,
    required this.calories,
    required this.difficulty,
    this.ingredients,
    this.instructions,
  });

  factory RecipeModel.fromMap(Map<String, dynamic> map, String id) {
    return RecipeModel(
      id: id,
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      duration: map['duration'] ?? '',
      calories: map['calories'] ?? '',
      difficulty: map['difficulty'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'duration': duration,
      'calories': calories,
      'difficulty': difficulty,
      'ingredients': ingredients,
      'instructions': instructions,
    };
  }
}
