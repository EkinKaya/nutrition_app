import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService {
  static const List<HealthDataType> _types = [HealthDataType.STEPS];
  static const List<HealthDataAccess> _permissions = [HealthDataAccess.READ];

  /// Belirtilen gün sayısı kadar geri gidip her güne ait adım toplamını döner.
  /// Anahtar: gece yarısından başlayan DateTime (saat 00:00).
  static Future<Map<DateTime, int>> getStepsPerDay({required int days}) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1));

      final dataPoints = await Health().getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      final result = <DateTime, int>{};
      for (final point in dataPoints) {
        final day = DateTime(
            point.dateFrom.year, point.dateFrom.month, point.dateFrom.day);
        final value =
            (point.value as NumericHealthValue).numericValue.toInt();
        result[day] = (result[day] ?? 0) + value;
      }
      return result;
    } catch (e) {
      debugPrint('HealthService.getStepsPerDay: $e');
      return {};
    }
  }

  /// Adim sayisi izni var mi?
  static Future<bool> hasPermissions() async {
    try {
      final result =
          await Health().hasPermissions(_types, permissions: _permissions);
      return result ?? false;
    } catch (e) {
      debugPrint('HealthService.hasPermissions: $e');
      return false;
    }
  }

  /// Health Connect izni iste
  static Future<bool> requestPermissions() async {
    try {
      await Health().configure();
      return await Health()
          .requestAuthorization(_types, permissions: _permissions);
    } catch (e) {
      debugPrint('HealthService.requestPermissions: $e');
      return false;
    }
  }

  /// Bugunun adim sayisini getir
  static Future<int> getTodaySteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final steps = await Health().getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (e) {
      debugPrint('HealthService.getTodaySteps: $e');
      return 0;
    }
  }
}
