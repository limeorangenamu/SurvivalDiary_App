import 'package:flutter/material.dart';

import 'notification_detection/detected_expense_list.dart';

class DetectedExpensePage extends StatelessWidget {
  const DetectedExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('감지된 결제')),
      body: const DetectedExpenseList(),
    );
  }
}
