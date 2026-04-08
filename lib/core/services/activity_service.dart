import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ActivityService {
  static const int dailyStepGoal = 10000;
  static const int dailyGlassGoal = 8;

  static String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>>? get _todayRef {
    final uid = _userId;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('daily_activity')
        .doc(_todayKey);
  }

  /// Bugunun bardak su sayisini canli dinle
  static Stream<int> getWaterGlassStream() {
    final ref = _todayRef;
    if (ref == null) return const Stream.empty();
    return ref.snapshots().map(
          (snap) => (snap.data()?['waterGlasses'] as int?) ?? 0,
        );
  }

  /// Bir bardak su ekle
  static Future<void> addWaterGlass() async {
    final ref = _todayRef;
    if (ref == null) return;
    try {
      await ref.set(
        {'waterGlasses': FieldValue.increment(1), 'date': _todayKey},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('ActivityService.addWaterGlass: $e');
    }
  }

  /// Bir bardak su cikar (minimum 0)
  static Future<void> removeWaterGlass() async {
    final ref = _todayRef;
    if (ref == null) return;
    try {
      final snap = await ref.get();
      final current = (snap.data()?['waterGlasses'] as int?) ?? 0;
      if (current > 0) await ref.update({'waterGlasses': current - 1});
    } catch (e) {
      debugPrint('ActivityService.removeWaterGlass: $e');
    }
  }

  /// Adim sayisina ve kullanici kilosuna gore yakilan kalori
  /// Formul: (adim / 1000) * kg * 0.6  (orta tempolu yuruyus MET degeri)
  static int calculateCalories(int steps, {double weightKg = 70}) {
    return ((steps / 1000) * weightKg * 0.6).round();
  }

  /// Hedef kalori (10000 adim icin)
  static int calorieGoalForWeight(double weightKg) {
    return calculateCalories(dailyStepGoal, weightKg: weightKg);
  }
}
