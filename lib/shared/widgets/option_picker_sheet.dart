import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class OptionPickerSheet<T> extends StatelessWidget {
  const OptionPickerSheet({
    super.key,
    required this.title,
    required this.options,
    required this.labelBuilder,
    this.selected,
  });

  final String title;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option == selected;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      labelBuilder(option),
                      style: isSelected
                          ? AppTextStyles.body.copyWith(
                              color: AppColors.primaryDeep,
                              fontWeight: FontWeight.w700,
                            )
                          : AppTextStyles.body,
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showOptionPickerSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T value) labelBuilder,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => OptionPickerSheet<T>(
      title: title,
      options: options,
      labelBuilder: labelBuilder,
      selected: selected,
    ),
  );
}
