import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/app_card.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: MockData.notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notification = MockData.notifications[index];
          return AppCard(
            color: notification.isUnread
                ? AppColors.primarySoft
                : AppColors.surface,
            borderColor: notification.isUnread
                ? AppColors.primarySoft
                : AppColors.border,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  child: Icon(notification.icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            notification.timeAgo,
                            style: AppTextStyles.captionTiny,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(notification.body, style: AppTextStyles.bodyMuted),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
