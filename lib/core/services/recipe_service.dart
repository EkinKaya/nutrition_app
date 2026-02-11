import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Recipe {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class RecipeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> get _recipesCollection {
    final userId = currentUserId;
    if (userId == null) throw Exception('Kullanici giris yapmamis');
    return _firestore.collection('users').doc(userId).collection('recipes');
  }

  /// Tarif kaydet
  static Future<bool> saveRecipe(String content) async {
    try {
      // Basliktan tarif adini cikar
      final title = _extractRecipeTitle(content);

      await _recipesCollection.add({
        'title': title,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Tarifleri getir (real-time stream)
  static Stream<List<Recipe>> getRecipesStream() {
    try {
      return _recipesCollection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Tarif sil
  static Future<bool> deleteRecipe(String recipeId) async {
    try {
      await _recipesCollection.doc(recipeId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Icerikteki tarif basligini cikarir
  static String _extractRecipeTitle(String content) {
    // "Tarif:" iceren satiri bul (markdown formatini da destekle)
    final lines = content.split('\n');
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('tarif:')) {
        // "**Tarif: Mercimek Corbasi**" -> "Mercimek Corbasi"
        // Markdown isaretlerini ve "Tarif:" kismini kaldir
        String title = line
            .replaceAll('**', '')
            .replaceAll('*', '')
            .replaceFirst(RegExp(r'[Tt]arif:\s*'), '')
            .trim();

        if (title.isNotEmpty) {
          if (title.length > 50) {
            return '${title.substring(0, 47)}...';
          }
          return title;
        }
      }
    }

    // Fallback: Ilk bos olmayan satiri al
    for (final line in lines) {
      final trimmed = line.replaceAll('**', '').replaceAll('*', '').trim();
      if (trimmed.isNotEmpty) {
        if (trimmed.length > 50) {
          return '${trimmed.substring(0, 47)}...';
        }
        return trimmed;
      }
    }
    return 'Tarif';
  }
}
