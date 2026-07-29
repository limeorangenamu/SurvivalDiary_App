import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PigMascot extends StatelessWidget {
  const PigMascot({super.key, this.size = 70, this.message});

  final double size;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: BorderRadius.circular(size * 0.35),
          ),
          child: Text(
            '🐷',
            style: AppTextStyles.display.copyWith(fontSize: size * 0.52),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(
            message!,
            style: AppTextStyles.caption.copyWith(color: AppColors.primaryDeep),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
