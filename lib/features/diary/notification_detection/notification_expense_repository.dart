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

enum SmsAccessStatus {
  checking,
  enabled,
  readOnly,
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
  SmsAccessStatus _smsAccessStatus = SmsAccessStatus.checking;
  String? _errorMessage;
  String? _smsErrorMessage;
  bool _started = false;
  bool _demoSeedRequested = false;
  bool _expenseAlertPermissionRequested = false;

  NotificationAccessStatus get accessStatus => _accessStatus;
  SmsAccessStatus get smsAccessStatus => _smsAccessStatus;
  String? get errorMessage => _errorMessage;
  String? get smsErrorMessage => _smsErrorMessage;
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
      _smsAccessStatus = SmsAccessStatus.unsupported;
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
    await _seedDebugDemoExpenses();
    await refresh();
  }

  Future<void> _seedDebugDemoExpenses() async {
    if (!kDebugMode || _demoSeedRequested) {
      return;
    }
    _demoSeedRequested = true;
    try {
      await _methodChannel.invokeMethod<int>(
        'seedDemoDetectedExpenses',
        {'debug': true},
      );
    } on MissingPluginException {
      return;
    } on PlatformException {
      _demoSeedRequested = false;
    }
  }

  Future<void> refresh() async {
    if (!_supportsNotificationAccess) {
      _accessStatus = NotificationAccessStatus.unsupported;
      _smsAccessStatus = SmsAccessStatus.unsupported;
      notifyListeners();
      return;
    }

    if (_accessStatus != NotificationAccessStatus.enabled) {
      _accessStatus = NotificationAccessStatus.checking;
    }
    if (_smsAccessStatus != SmsAccessStatus.enabled &&
        _smsAccessStatus != SmsAccessStatus.readOnly) {
      _smsAccessStatus = SmsAccessStatus.checking;
    }
    notifyListeners();

    try {
      final granted = await _methodChannel.invokeMethod<bool>(
            'isNotificationAccessGranted',
          ) ??
          false;
      final smsState = await _methodChannel.invokeMethod<String>(
            'getSmsAccessState',
          ) ??
          'unsupported';
      String? smsScanError;
      if (smsState == 'enabled' || smsState == 'read_only') {
        try {
          await _methodChannel.invokeMethod<int>('scanSmsInbox');
        } on PlatformException catch (error) {
          smsScanError = error.message;
        }
      }
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
      _smsAccessStatus = switch (smsState) {
        'enabled' when smsScanError == null => SmsAccessStatus.enabled,
        'enabled' => SmsAccessStatus.error,
        'read_only' when smsScanError == null => SmsAccessStatus.readOnly,
        'read_only' => SmsAccessStatus.error,
        'disabled' => SmsAccessStatus.disabled,
        _ => SmsAccessStatus.unsupported,
      };
      _smsErrorMessage = smsScanError;
    } on MissingPluginException {
      _accessStatus = NotificationAccessStatus.unsupported;
      _smsAccessStatus = SmsAccessStatus.unsupported;
      _errorMessage = null;
      _smsErrorMessage = null;
    } on PlatformException catch (error) {
      _accessStatus = NotificationAccessStatus.error;
      _smsAccessStatus = SmsAccessStatus.error;
      _errorMessage = error.message;
      _smsErrorMessage = error.message;
    }
    notifyListeners();
  }

  Future<bool> requestSmsAccess() async {
    _smsAccessStatus = SmsAccessStatus.checking;
    _smsErrorMessage = null;
    notifyListeners();
    try {
      final granted = await _methodChannel.invokeMethod<bool>(
            'requestSmsAccess',
          ) ??
          false;
      if (granted) {
        await refresh();
      } else {
        _smsAccessStatus = SmsAccessStatus.disabled;
        notifyListeners();
      }
      return granted;
    } on MissingPluginException {
      _smsAccessStatus = SmsAccessStatus.unsupported;
      notifyListeners();
      return false;
    } on PlatformException catch (error) {
      _smsAccessStatus = SmsAccessStatus.error;
      _smsErrorMessage = error.message;
      notifyListeners();
      return false;
    }
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

  Future<void> requestExpenseAlertPermission() async {
    if (!_supportsNotificationAccess || _expenseAlertPermissionRequested) {
      return;
    }
    _expenseAlertPermissionRequested = true;
    try {
      await _methodChannel.invokeMethod<bool>('requestExpenseAlertPermission');
    } on MissingPluginException {
      return;
    } on PlatformException {
      _expenseAlertPermissionRequested = false;
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
    final channel = event['detectionChannel'] as String?;
    if (channel == 'sms') {
      _smsAccessStatus = SmsAccessStatus.enabled;
      _smsErrorMessage = null;
    } else {
      _accessStatus = NotificationAccessStatus.enabled;
      _errorMessage = null;
    }
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
    _smsAccessStatus = SmsAccessStatus.checking;
    _errorMessage = null;
    _smsErrorMessage = null;
    _started = false;
    _demoSeedRequested = false;
    _expenseAlertPermissionRequested = false;
  }
}
