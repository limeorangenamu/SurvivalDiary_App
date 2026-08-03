import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../data/models.dart';
import 'detected_expense_candidate.dart';

enum NotificationAccessStatus {
  checking,
  enabled,
  disabled,
  unsupported,
  error,
}

class NotificationExpenseRepository extends ChangeNotifier {
  NotificationExpenseRepository._();

  static final NotificationExpenseRepository instance =
      NotificationExpenseRepository._();

  static const _methodChannel = MethodChannel(
    'com.survivaldiary.project_survival_diary/payment_notifications',
  );
  static const _eventChannel = EventChannel(
    'com.survivaldiary.project_survival_diary/payment_notification_events',
  );

  final Map<String, DetectedExpenseCandidate> _items = {};
  StreamSubscription<Object?>? _eventSubscription;
  NotificationAccessStatus _accessStatus = NotificationAccessStatus.checking;
  String? _errorMessage;
  bool _started = false;

  NotificationAccessStatus get accessStatus => _accessStatus;
  String? get errorMessage => _errorMessage;
  List<DetectedExpenseCandidate> get items {
    final result = _items.values.toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return List.unmodifiable(result);
  }

  bool get _supportsNotificationAccess =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> start() async {
    if (!_supportsNotificationAccess) {
      _accessStatus = NotificationAccessStatus.unsupported;
      notifyListeners();
      return;
    }

    if (!_started) {
      _started = true;
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
            _handlePlatformEvent,
            onError: _handlePlatformError,
          );
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (!_supportsNotificationAccess) {
      _accessStatus = NotificationAccessStatus.unsupported;
      notifyListeners();
      return;
    }

    if (_accessStatus != NotificationAccessStatus.enabled) {
      _accessStatus = NotificationAccessStatus.checking;
      notifyListeners();
    }

    try {
      final granted = await _methodChannel.invokeMethod<bool>(
            'isNotificationAccessGranted',
          ) ??
          false;
      final rawItems = await _methodChannel.invokeListMethod<Object?>(
            'getDetectedExpenses',
          ) ??
          const [];
      final platformItems = rawItems
          .whereType<Map<Object?, Object?>>()
          .map(DetectedExpenseCandidate.fromPlatformMap);
      _items
        ..clear()
        ..addEntries(platformItems.map((item) => MapEntry(item.id, item)));
      _accessStatus = granted
          ? NotificationAccessStatus.enabled
          : NotificationAccessStatus.disabled;
      _errorMessage = null;
    } on MissingPluginException {
      _accessStatus = NotificationAccessStatus.unsupported;
      _errorMessage = null;
    } on PlatformException catch (error) {
      _accessStatus = NotificationAccessStatus.error;
      _errorMessage = error.message;
    }
    notifyListeners();
  }

  Future<void> openNotificationAccessSettings() async {
    try {
      await _methodChannel.invokeMethod<void>('openNotificationAccessSettings');
    } on PlatformException catch (error) {
      _errorMessage = error.message;
      _accessStatus = NotificationAccessStatus.error;
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    final removed = await _methodChannel.invokeMethod<bool>(
          'removeDetectedExpense',
          {'id': id},
        ) ??
        false;
    if (removed || _items.containsKey(id)) {
      _items.remove(id);
      notifyListeners();
    }
  }

  Future<DetectedExpenseCandidate> update({
    required DetectedExpenseCandidate item,
    required String merchant,
    required int amount,
    required ExpenseCategory category,
  }) async {
    final updated = await _methodChannel.invokeMethod<bool>(
          'updateDetectedExpense',
          {
            'id': item.id,
            'merchant': merchant,
            'amount': amount,
            'category': category.name,
          },
        ) ??
        false;
    if (!updated) {
      throw PlatformException(
        code: 'NOT_FOUND',
        message: '이미 처리된 결제 알림이에요.',
      );
    }

    final result = item.copyWith(
      merchant: merchant,
      amount: amount,
      category: category,
      confidence: 1,
    );
    _items[item.id] = result;
    notifyListeners();
    return result;
  }

  void _handlePlatformEvent(Object? event) {
    if (event is! Map<Object?, Object?>) {
      return;
    }
    final item = DetectedExpenseCandidate.fromPlatformMap(event);
    _items[item.id] = item;
    _accessStatus = NotificationAccessStatus.enabled;
    _errorMessage = null;
    notifyListeners();
  }

  void _handlePlatformError(Object error) {
    _accessStatus = NotificationAccessStatus.error;
    _errorMessage =
        error is PlatformException ? error.message : error.toString();
    notifyListeners();
  }

  @visibleForTesting
  Future<void> reset() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _items.clear();
    _accessStatus = NotificationAccessStatus.checking;
    _errorMessage = null;
    _started = false;
  }
}
