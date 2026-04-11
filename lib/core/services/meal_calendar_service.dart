import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MealEntry {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime savedAt;

  MealEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.savedAt,
  });

  factory MealEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealEntry(
      id: doc.id,
      name: data['name'] ?? '',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0,
      savedAt: (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'savedAt': FieldValue.serverTimestamp(),
      };
}

class DaySummary {
  final DateTime date;
  final List<MealEntry> meals;

  DaySummary({required this.date, required this.meals});

  int get totalCalories => meals.fold(0, (s, m) => s + m.calories);
  double get totalProtein => meals.fold(0.0, (s, m) => s + m.protein);
  double get totalCarbs => meals.fold(0.0, (s, m) => s + m.carbs);
  double get totalFat => meals.fold(0.0, (s, m) => s + m.fat);
}

class MealCalendarService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static CollectionReference<Map<String, dynamic>> _mealsCol(DateTime date) {
    final uid = _uid;
    if (uid == null) throw Exception('Not logged in');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('meal_calendar')
        .doc(dateKey(date))
        .collection('meals');
  }

  /// Öğün kaydet
  static Future<bool> saveMeal(MealEntry entry, DateTime date) async {
    try {
      await _mealsCol(date).add(entry.toMap());
      debugPrint('MealCalendarService: Öğün kaydedildi - ${entry.name}');
      return true;
    } catch (e) {
      debugPrint('MealCalendarService: Hata - $e');
      return false;
    }
  }

  /// Günlük öğün akışı
  static Stream<List<MealEntry>> getMealsStream(DateTime date) {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('meal_calendar')
        .doc(dateKey(date))
        .collection('meals')
        .orderBy('savedAt')
        .snapshots()
        .map((s) => s.docs.map((d) => MealEntry.fromFirestore(d)).toList());
  }

  /// Öğün sil
  static Future<bool> deleteMeal(String mealId, DateTime date) async {
    try {
      await _mealsCol(date).doc(mealId).delete();
      return true;
    } catch (e) {
      debugPrint('MealCalendarService: Silme hatası - $e');
      return false;
    }
  }

  /// Haftanın 7 günü için özet (önceki Pazartesi → Pazar)
  static Future<Map<DateTime, DaySummary>> getWeeklySummary(
      DateTime weekStart) async {
    final uid = _uid;
    if (uid == null) return {};

    final result = <DateTime, DaySummary>{};

    for (int i = 0; i < 7; i++) {
      final day = DateTime(
          weekStart.year, weekStart.month, weekStart.day + i);
      try {
        final snap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('meal_calendar')
            .doc(dateKey(day))
            .collection('meals')
            .get();
        final meals = snap.docs.map((d) => MealEntry.fromFirestore(d)).toList();
        result[DateTime(day.year, day.month, day.day)] =
            DaySummary(date: day, meals: meals);
      } catch (_) {
        result[DateTime(day.year, day.month, day.day)] =
            DaySummary(date: day, meals: []);
      }
    }
    return result;
  }

  /// Haftalık AI özeti kaydet/getir
  static String _weekKey(DateTime date) {
    // ISO hafta numarası için yıl-hafta
    final dayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final weekNum = ((dayOfYear - date.weekday + 10) / 7).floor();
    return '${date.year}-W${weekNum.toString().padLeft(2, '0')}';
  }

  static Future<String?> getWeeklySummaryText(DateTime anyDayInWeek) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('weekly_ai_summaries')
          .doc(_weekKey(anyDayInWeek))
          .get();
      return doc.data()?['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveWeeklySummaryText(
      DateTime anyDayInWeek, String text) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('weekly_ai_summaries')
          .doc(_weekKey(anyDayInWeek))
          .set({'text': text, 'generatedAt': FieldValue.serverTimestamp()});
    } catch (_) {}
  }
}
