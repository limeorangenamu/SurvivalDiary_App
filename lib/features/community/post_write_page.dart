import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/pill_chip.dart';

class PostWritePage extends StatefulWidget {
  const PostWritePage({super.key});

  @override
  State<PostWritePage> createState() => _PostWritePageState();
}

class _PostWritePageState extends State<PostWritePage> {
  static const categories = ['자유게시판', '정보 공유', '절약 인증', '질문'];
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _category;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_category == null ||
        _titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      setState(() => _error = '카테고리, 제목, 내용을 모두 입력해 주세요.');
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('글쓰기'),
        actions: [
          TextButton(
            key: const ValueKey('post-submit-button'),
            onPressed: _submit,
            child: const Text('등록'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const Text('카테고리', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                PillChip(
                  label: category,
                  selected: _category == category,
                  onTap: () => setState(() {
                    _category = category;
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            key: const ValueKey('post-title-field'),
            controller: _titleController,
            maxLength: 60,
            onChanged: (_) => setState(() => _error = null),
            decoration: const InputDecoration(
              labelText: '제목',
              hintText: '이야기의 제목을 적어 주세요.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('post-body-field'),
            controller: _bodyController,
            minLines: 9,
            maxLines: 14,
            maxLength: 1200,
            onChanged: (_) => setState(() => _error = null),
            decoration: const InputDecoration(
              labelText: '내용',
              alignLabelWithHint: true,
              hintText: '절약 경험이나 궁금한 점을 자유롭게 나눠 주세요.',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Container(
              key: const ValueKey('post-write-error'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            '게시글은 서버에 저장되지 않는 UI 프로토타입입니다.',
            style: AppTextStyles.captionTiny,
          ),
        ],
      ),
    );
  }
}
