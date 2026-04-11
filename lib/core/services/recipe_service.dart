import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('RecipeService: Kullanici giris yapmamis');
        return false;
      }

      final title = _extractRecipeTitle(content);
      debugPrint('RecipeService: Tarif kaydediliyor - "$title"');
      debugPrint('RecipeService: userId = $userId');
      debugPrint('RecipeService: path = users/$userId/recipes');

      final docRef = await _recipesCollection.add({
        'title': title,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('RecipeService: Tarif kaydedildi! docId = ${docRef.id}');
      return true;
    } catch (e) {
      debugPrint('RecipeService: HATA - $e');
      return false;
    }
  }

  /// Tarifleri getir (real-time stream)
  static Stream<List<Recipe>> getRecipesStream() {
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('RecipeService: Stream - kullanici giris yapmamis');
      return Stream.value([]);
    }

    debugPrint('RecipeService: Stream dinleniyor - users/$userId/recipes');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      debugPrint('RecipeService: ${snapshot.docs.length} tarif bulundu');
      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    });
  }

  /// Tarif sil
  static Future<bool> deleteRecipe(String recipeId) async {
    try {
      await _recipesCollection.doc(recipeId).delete();
      debugPrint('RecipeService: Tarif silindi - $recipeId');
      return true;
    } catch (e) {
      debugPrint('RecipeService: Silme hatasi - $e');
      return false;
    }
  }

  /// Icerikteki tarif basligini cikarir
  static String _extractRecipeTitle(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('tarif:')) {
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
