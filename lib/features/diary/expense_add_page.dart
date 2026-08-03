import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'expense_stats_page.dart';
import 'notification_detection/detected_expense_list.dart';
import 'widgets/expense_form.dart';

class ExpenseAddPage extends StatefulWidget {
  const ExpenseAddPage({super.key});

  @override
  State<ExpenseAddPage> createState() => _ExpenseAddPageState();
}

class _ExpenseAddPageState extends State<ExpenseAddPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _statsRevision = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshStats() {
    setState(() => _statsRevision++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지출 일기'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryDeep,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: '지출 통계'),
            Tab(text: '자동 등록'),
            Tab(text: '직접 입력'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExpenseStatsView(key: ValueKey(_statsRevision)),
          DetectedExpenseList(
            limit: 3,
            showHeader: true,
            onExpenseSaved: _refreshStats,
          ),
          _DirectExpenseTab(onExpenseSaved: _refreshStats),
        ],
      ),
    );
  }
}

class _DirectExpenseTab extends StatelessWidget {
  const _DirectExpenseTab({required this.onExpenseSaved});

  final VoidCallback onExpenseSaved;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('direct-tab-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        ExpenseForm(
          showTitle: false,
          onSaved: onExpenseSaved,
        ),
      ],
    );
  }
}
