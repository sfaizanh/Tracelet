import '../rust/api_dart/battery_budget.dart';
import '../rust/state/battery_budget.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Rust-powered battery budget engine.
class BatteryBudgetEngine {
  BatteryBudgetEngineDart? _inner;
  final DateTime Function() _clock;

  BatteryBudgetEngine({
    double targetBudgetPerHour = 3.0,
    double initialDistanceFilter = 10.0,
    int initialAccuracyIndex = 0,
    int? initialPeriodicInterval,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _targetBudgetPerHour = targetBudgetPerHour,
       _initialDistanceFilter = initialDistanceFilter,
       _initialAccuracyIndex = initialAccuracyIndex,
       _initialPeriodicInterval = initialPeriodicInterval;

  /// Initialize the Rust-backed budget engine.
  ///
  /// Must be called after [RustLib.init] has completed.
  /// Safe to call multiple times (idempotent).
  void initialize() {
    if (_inner != null) return;
    if (!kIsWeb) {
      _inner = BatteryBudgetEngineDart(
        targetBudgetPerHour: _targetBudgetPerHour,
        initialDistanceFilter: _initialDistanceFilter,
        initialAccuracyIndex: _initialAccuracyIndex,
        initialPeriodicInterval: _initialPeriodicInterval,
      );
    }
  }

  final double _initialDistanceFilter;
  final int _initialAccuracyIndex;
  final int? _initialPeriodicInterval;

  BudgetAdjustmentEvent? processSample(
    double batteryLevel, {
    bool isCharging = false,
  }) {
    if (_inner == null) return null;
    return _inner!.processSample(
      level: batteryLevel,
      isCharging: isCharging,
      timestampMs: PlatformInt64Util.from(_clock().millisecondsSinceEpoch),
    );
  }

  int getRecommendedIntervalMs(int defaultIntervalMs) {
    if (_inner == null) return defaultIntervalMs;
    return _inner!
        .getRecommendedIntervalMs(
          defaultIntervalMs: PlatformInt64Util.from(defaultIntervalMs),
        )
        .toInt();
  }

  bool shouldThrottleLocation() {
    return _inner?.shouldThrottleLocation() ?? false;
  }

  bool isCharging() {
    return _inner?.isCharging() ?? false;
  }

  double get targetBudgetPerHour {
    // The dart side cannot directly access this from inner if it's not exposed,
    // but we can expose it via an FRB getter or just store it.
    // Wait, the tests check engine.targetBudgetPerHour! Let's store it.
    return _targetBudgetPerHour; // We need to add this field.
  }

  final double _targetBudgetPerHour;

  double get distanceFilter => _inner?.getDistanceFilter() ?? 10.0;
  int get accuracyIndex => _inner?.getAccuracyIndex() ?? 0;
  int? get periodicInterval => _inner?.getPeriodicInterval();

  void reset() {
    _inner?.reset();
  }
}
