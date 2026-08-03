import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/pill_chip.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/auth_session.dart';
import '../data/expense_api_client.dart';
import 'detected_expense_candidate.dart';
import 'notification_expense_repository.dart';

class DetectedExpenseList extends StatefulWidget {
  const DetectedExpenseList({
    super.key,
    this.limit,
    this.showHeader = false,
    this.allowExclude = true,
    this.onExpenseSaved,
  });

  final int? limit;
  final bool showHeader;
  final bool allowExclude;
  final VoidCallback? onExpenseSaved;

  @override
  State<DetectedExpenseList> createState() => _DetectedExpenseListState();
}

class _DetectedExpenseListState extends State<DetectedExpenseList>
    with WidgetsBindingObserver {
  final _repository = NotificationExpenseRepository.instance;
  final _expenseApiClient = ExpenseApiClient();
  final Set<String> _savingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository.addListener(_repositoryChanged);
    unawaited(_start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _repository.removeListener(_repositoryChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  Future<void> _start() async {
    await _repository.start();
    await _requestExpenseAlertsIfReady();
  }

  Future<void> _refresh() async {
    await _repository.refresh();
    await _requestExpenseAlertsIfReady();
  }

  Future<void> _requestExpenseAlertsIfReady() async {
    final canDetectExpenses =
        _repository.accessStatus == NotificationAccessStatus.enabled ||
        _repository.smsAccessStatus == SmsAccessStatus.enabled ||
        _repository.smsAccessStatus == SmsAccessStatus.readOnly;
    if (canDetectExpenses) {
      await _repository.requestExpenseAlertPermission();
    }
  }

  void _repositoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _requestNotificationAccess() async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('결제 알림 접근 안내'),
        content: const Text(
          '자동 등록을 켜면 휴대폰의 알림 접근 권한이 필요해요. '
          '생존일기는 지원하는 금융 앱의 결제 알림만 기기에서 확인하고, '
          '가맹점·금액·시간만 보관해요. 원본 알림 내용은 서버로 보내지 않아요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('나중에'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('동의하고 설정 열기'),
          ),
        ],
      ),
    );
    if (agreed == true) {
      await _repository.openNotificationAccessSettings();
    }
  }

  Future<void> _requestSmsAccess() async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('문자함 결제 내역 조회 안내'),
        content: const Text(
          '문자함 연결을 켜면 최근 30일의 문자와 장문 문자에서 카드·은행 이름과 '
          '승인·결제 또는 출금·이체·송금 형식이 있는 내역만 기기에서 확인해요. '
          '일반 대화·광고·인증번호와 원본 문자는 저장하거나 서버로 보내지 않고, '
          '찾은 금액·가맹점·시간도 확인 후에만 지출로 등록돼요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('나중에'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('동의하고 문자함 연결'),
          ),
        ],
      ),
    );
    if (agreed != true) {
      return;
    }

    final granted = await _repository.requestSmsAccess();
    if (granted) {
      await _repository.requestExpenseAlertPermission();
    }
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('문자 접근이 허용되지 않아 알림 감지만 계속 사용해요.'),
        ),
      );
    }
  }

  Future<void> _edit(DetectedExpenseCandidate item) async {
    final edit = await showModalBottomSheet<DetectedExpenseEdit>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: DetectedExpenseEditor(item: item),
      ),
    );
    if (edit == null || !mounted) {
      return;
    }

    try {
      await _repository.update(
        item: item,
        merchant: edit.merchant,
        amount: edit.amount,
        category: edit.category,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('감지한 결제 정보를 수정했어요.')),
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? '결제 정보를 수정하지 못했어요.')),
        );
      }
    }
  }

  Future<void> _exclude(DetectedExpenseCandidate item) async {
    final shouldExclude = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('지출을 삭제할까요?', style: AppTextStyles.sectionTitle),
        content: const Text(
          '지출 내역은 삭제 후 복구할 수 없어요.',
          style: AppTextStyles.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              '삭제',
              style: AppTextStyles.body.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (shouldExclude != true) {
      return;
    }

    try {
      await _repository.remove(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('감지 내역에서 제외했어요.')),
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? '감지 내역에서 제외하지 못했어요.')),
        );
      }
    }
  }

  Future<void> _add(DetectedExpenseCandidate item) async {
    final currentUser = AuthSession.instance.currentUser;
    final accessToken = AuthSession.instance.accessToken;
    final userId = currentUser?.userId;
    if (userId == null || accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지출을 저장하려면 로그인이 필요해요.')),
      );
      return;
    }

    setState(() => _savingIds.add(item.id));
    try {
      await _expenseApiClient.createAutoExpense(
        accessToken: accessToken,
        request: CreateAutoExpenseRequest(
          userId: userId,
          category: item.category,
          title: item.merchant,
          amount: item.amount,
          spentAt: item.detectedAt,
          detectionKey: item.id,
          notificationSource: item.source,
        ),
      );

      try {
        await _repository.remove(item.id);
      } on PlatformException {
        await _repository.refresh();
      }
      widget.onExpenseSaved?.call();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text('${item.merchant} 지출을 추가했어요.')),
          );
      }
    } on ExpenseApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingIds.remove(item.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _repository.items;
    final visibleItems =
        widget.limit == null ? allItems : allItems.take(widget.limit!).toList();
    final showNotificationAccessCard =
        _repository.accessStatus != NotificationAccessStatus.enabled;
    final showSmsAccessCard =
        _repository.smsAccessStatus != SmsAccessStatus.enabled &&
        _repository.smsAccessStatus != SmsAccessStatus.readOnly;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        key: const PageStorageKey('detected-expense-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (widget.showHeader) ...[
            SectionHeader(
              title: '결제 내역에서 찾았어요',
              subtitle:
                  '알림 내용을 숨기거나 결제 알림 기능을 꺼두면 지출 내역이 감지되지 않을 수 있어요.',
              actionLabel: allItems.length > (widget.limit ?? allItems.length)
                  ? '전체 보기'
                  : null,
              onAction: allItems.length > (widget.limit ?? allItems.length)
                  ? () => Navigator.pushNamed(
                        context,
                        AppRoutes.detectedExpenses,
                      )
                  : null,
            ),
            const SizedBox(height: 10),
          ],
          if (showNotificationAccessCard) ...[
            _NotificationAccessCard(
              status: _repository.accessStatus,
              errorMessage: _repository.errorMessage,
              onRequestAccess: _requestNotificationAccess,
              onRetry: _refresh,
            ),
            const SizedBox(height: 10),
          ],
          if (showSmsAccessCard) ...[
            _SmsAccessCard(
              status: _repository.smsAccessStatus,
              errorMessage: _repository.smsErrorMessage,
              onRequestAccess: _requestSmsAccess,
              onRetry: _refresh,
            ),
            const SizedBox(height: 12),
          ],
          if ((_repository.accessStatus == NotificationAccessStatus.checking ||
                  _repository.smsAccessStatus == SmsAccessStatus.checking) &&
              allItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (visibleItems.isEmpty)
            const EmptyStateView(
              icon: Icons.notifications_none_rounded,
              title: '아직 감지한 결제가 없어요',
              description: '금융 앱 알림이나 카드·은행 결제 문자를 찾으면\n여기에 바로 표시돼요.',
            )
          else
            for (final item in visibleItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DetectedExpenseCard(
                  item: item,
                  isSaving: _savingIds.contains(item.id),
                  allowExclude: widget.allowExclude,
                  onEdit: () => _edit(item),
                  onExclude: () => _exclude(item),
                  onAdd: () => _add(item),
                ),
              ),
        ],
      ),
    );
  }
}

class _SmsAccessCard extends StatelessWidget {
  const _SmsAccessCard({
    required this.status,
    required this.errorMessage,
    required this.onRequestAccess,
    required this.onRetry,
  });

  final SmsAccessStatus status;
  final String? errorMessage;
  final VoidCallback onRequestAccess;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      SmsAccessStatus.enabled => const AppCard(
          child: _AccessCardContent(
            icon: Icons.sms_rounded,
            iconColor: AppColors.primary,
            title: '문자함의 결제 내역도 확인 중이에요',
            description: '최근 30일의 카드·은행 결제 문자와 장문 문자만 기기에서 찾아요.',
          ),
        ),
      SmsAccessStatus.readOnly => AppCard(
          child: _AccessCardContent(
            icon: Icons.mark_chat_read_outlined,
            iconColor: AppColors.info,
            title: '문자함의 결제 내역을 확인 중이에요',
            description: '문자와 장문 문자는 조회할 수 있지만 실시간 수신 권한은 꺼져 있어요.',
            actionLabel: '실시간 감지 켜기',
            onAction: onRequestAccess,
          ),
        ),
      SmsAccessStatus.disabled => AppCard(
          child: _AccessCardContent(
            icon: Icons.sms_failed_outlined,
            iconColor: AppColors.warning,
            title: '문자함 결제 내역도 가져올 수 있어요',
            description: '일반 문자는 보관하지 않고 카드·은행 결제 형식만 기기에서 확인해요.',
            actionLabel: '문자함 연결하기',
            onAction: onRequestAccess,
          ),
        ),
      SmsAccessStatus.unsupported => const AppCard(
          child: _AccessCardContent(
            icon: Icons.sms_outlined,
            iconColor: AppColors.textSecondary,
            title: '이 기기에서는 문자함 조회를 지원하지 않아요',
            description: '기존 금융 앱 결제 알림 감지는 계속 사용할 수 있어요.',
          ),
        ),
      SmsAccessStatus.error => AppCard(
          child: _AccessCardContent(
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.danger,
            title: '문자함 결제 내역을 확인하지 못했어요',
            description: errorMessage ?? '문자 권한을 확인한 뒤 다시 시도해 주세요.',
            actionLabel: '다시 확인',
            onAction: onRetry,
          ),
        ),
      SmsAccessStatus.checking => const AppCard(
          child: _AccessCardContent(
            icon: Icons.sync_rounded,
            iconColor: AppColors.info,
            title: '문자함 연결 상태를 확인하고 있어요',
            description: '잠시만 기다려 주세요.',
          ),
        ),
    };
  }
}

class _NotificationAccessCard extends StatelessWidget {
  const _NotificationAccessCard({
    required this.status,
    required this.errorMessage,
    required this.onRequestAccess,
    required this.onRetry,
  });

  final NotificationAccessStatus status;
  final String? errorMessage;
  final VoidCallback onRequestAccess;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      NotificationAccessStatus.enabled => const AppCard(
          child: _AccessCardContent(
            icon: Icons.notifications_active_rounded,
            iconColor: AppColors.primary,
            title: '결제 알림을 실시간으로 확인 중이에요',
            description: '토스·카카오페이·주요 카드와 은행 앱의 결제 푸시 알림을 확인해요.',
          ),
        ),
      NotificationAccessStatus.disabled => AppCard(
          child: _AccessCardContent(
            icon: Icons.notifications_off_outlined,
            iconColor: AppColors.warning,
            title: '자동 등록을 사용하려면 알림 접근이 필요해요',
            description: '안내를 확인한 뒤 휴대폰 설정에서 생존일기의 알림 접근을 허용해 주세요.',
            actionLabel: '자동 등록 켜기',
            onAction: onRequestAccess,
          ),
        ),
      NotificationAccessStatus.unsupported => const AppCard(
          child: _AccessCardContent(
            icon: Icons.phone_android_rounded,
            iconColor: AppColors.textSecondary,
            title: '안드로이드 앱에서 사용할 수 있어요',
            description: '다른 앱의 결제 알림 감지는 안드로이드 휴대폰에서만 지원해요.',
          ),
        ),
      NotificationAccessStatus.error => AppCard(
          child: _AccessCardContent(
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.danger,
            title: '알림 감지 상태를 확인하지 못했어요',
            description: errorMessage ?? '잠시 후 다시 시도해 주세요.',
            actionLabel: '다시 확인',
            onAction: onRetry,
          ),
        ),
      NotificationAccessStatus.checking => const AppCard(
          child: _AccessCardContent(
            icon: Icons.sync_rounded,
            iconColor: AppColors.info,
            title: '알림 감지 상태를 확인하고 있어요',
            description: '잠시만 기다려 주세요.',
          ),
        ),
    };
  }
}

class _AccessCardContent extends StatelessWidget {
  const _AccessCardContent({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.12),
          foregroundColor: iconColor,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 4),
              Text(description, style: AppTextStyles.caption),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class DetectedExpenseCard extends StatelessWidget {
  const DetectedExpenseCard({
    super.key,
    required this.item,
    required this.isSaving,
    required this.allowExclude,
    required this.onEdit,
    required this.onExclude,
    required this.onAdd,
  });

  final DetectedExpenseCandidate item;
  final bool isSaving;
  final bool allowExclude;
  final VoidCallback onEdit;
  final VoidCallback onExclude;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: item.category.color.withValues(alpha: 0.12),
                foregroundColor: item.category.color,
                child: Icon(item.category.icon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.merchant,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.needsReview) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '확인 필요',
                              style: AppTextStyles.captionTiny.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_detectedTime(item.detectedAt)} · ${item.source} · ${item.category.label}',
                      style: AppTextStyles.captionTiny,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(Formatters.amount(item.amount), style: AppTextStyles.amount),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (allowExclude) ...[
                Expanded(
                  child: FilledButton(
                    key: ValueKey('exclude-detected-${item.id}'),
                    onPressed: isSaving ? null : onExclude,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.surface,
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('제외'),
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Expanded(
                child: FilledButton(
                  key: ValueKey('edit-detected-${item.id}'),
                  onPressed: isSaving ? null : onEdit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: AppColors.surface,
                    minimumSize: const Size(0, 44),
                  ),
                  child: const Text('수정'),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: FilledButton(
                  key: ValueKey('add-detected-${item.id}'),
                  onPressed: isSaving ? null : onAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    minimumSize: const Size(0, 44),
                  ),
                  child: Text(isSaving ? '저장 중' : '추가'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DetectedExpenseEdit {
  const DetectedExpenseEdit({
    required this.merchant,
    required this.amount,
    required this.category,
  });

  final String merchant;
  final int amount;
  final ExpenseCategory category;
}

class DetectedExpenseEditor extends StatefulWidget {
  const DetectedExpenseEditor({super.key, required this.item});

  final DetectedExpenseCandidate item;

  @override
  State<DetectedExpenseEditor> createState() => _DetectedExpenseEditorState();
}

class _DetectedExpenseEditorState extends State<DetectedExpenseEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late ExpenseCategory _category;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.item.merchant);
    _amountController =
        TextEditingController(text: widget.item.amount.toString());
    _category = widget.item.category;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      DetectedExpenseEdit(
        merchant: _merchantController.text.trim(),
        amount: int.parse(_amountController.text.replaceAll(',', '').trim()),
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('감지한 결제 수정', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 4),
              Text(
                '${_detectedTime(widget.item.detectedAt)} · ${widget.item.source}',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 18),
              const Text('카테고리', style: AppTextStyles.body),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final category in ExpenseCategory.values)
                    PillChip(
                      label: category.label,
                      icon: category.icon,
                      color: category.color,
                      selected: _category == category,
                      onTap: () => setState(() => _category = category),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(labelText: '지출 내용'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return '지출 내용을 입력해 주세요.';
                  }
                  if (text.length > 100) {
                    return '지출 내용은 100자 이하로 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '금액',
                  suffixText: '원',
                ),
                validator: (value) {
                  final amount = int.tryParse(
                    value?.replaceAll(',', '').trim() ?? '',
                  );
                  return amount == null || amount <= 0
                      ? '올바른 금액을 입력해 주세요.'
                      : null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('수정 내용 저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _detectedTime(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  final isToday = local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return isToday
      ? '오늘 $hour:$minute'
      : '${local.month}/${local.day} $hour:$minute';
}
