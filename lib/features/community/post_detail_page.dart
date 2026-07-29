import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시글')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.surfaceAlt,
                      child: Text(
                        post.authorEmoji,
                        style: AppTextStyles.sectionTitle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${post.category} · ${post.timeAgo}',
                            style: AppTextStyles.captionTiny,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(post.title, style: AppTextStyles.title),
                const SizedBox(height: 12),
                Text(post.body, style: AppTextStyles.body),
                if (post.hasImage) ...[
                  const SizedBox(height: 18),
                  Container(
                    height: 220,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 54,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final tag in post.hashtags)
                      Text(
                        '#$tag',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryDeep,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text('${post.likeCount}', style: AppTextStyles.caption),
                    const SizedBox(width: 20),
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text('${post.commentCount}', style: AppTextStyles.caption),
                    const Spacer(),
                    const Icon(
                      Icons.bookmark_border_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const AppCard(
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.info),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '좋아요·댓글·북마크는 UI만 제공해요.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
