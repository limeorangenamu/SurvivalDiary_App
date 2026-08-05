import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_session.dart';
import 'data/community_api_client.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.post});

  final CommunityPost post;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late CommunityPost post;
  final _apiClient = CommunityApiClient();

  Widget _contentView() {
    try {
      final document =
          Document.fromJson(jsonDecode(post.contentJson ?? post.body));
      final controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 300),
        child: QuillEditor(
          controller: controller,
          focusNode: FocusNode(),
          scrollController: ScrollController(),
          config: QuillEditorConfig(
            scrollable: false,
            padding: EdgeInsets.zero,
            embedBuilders: FlutterQuillEmbeds.editorBuilders(
              imageEmbedConfig: QuillEditorImageEmbedConfig(
                imageProviderBuilder: (context, imageUrl) {
                  if (!imageUrl.startsWith('data:image/')) return null;
                  return MemoryImage(base64Decode(imageUrl.split(',').last));
                },
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      return Text(post.body, style: AppTextStyles.body);
    }
  }

  @override
  void initState() {
    super.initState();
    post = widget.post;
    _loadFreshPost();
  }

  Future<void> _loadFreshPost() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) return;
    try {
      final fresh =
          await _apiClient.getPost(accessToken: token, postId: post.id);
      if (mounted) setState(() => post = fresh);
    } on CommunityApiException {
      // Keep the list snapshot if refreshing the detail fails.
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.pushNamed(context, AppRoutes.postWrite,
        arguments: post);
    if (changed == true) {
      _loadFreshPost();
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('게시글을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = AuthSession.instance.accessToken;
    if (token == null) return;
    try {
      await _apiClient.delete(accessToken: token, postId: post.id);
      if (mounted) Navigator.pop(context, true);
    } on CommunityApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _toggle(bool bookmark) async {
    final token = AuthSession.instance.accessToken;
    if (token == null) return;
    try {
      final updated = bookmark
          ? await _apiClient.toggleBookmark(accessToken: token, postId: post.id)
          : await _apiClient.toggleLike(accessToken: token, postId: post.id);
      if (mounted) setState(() => post = updated);
    } on CommunityApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        actions: [
          if (post.isOwner) ...[
            IconButton(onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
            IconButton(
                onPressed: _delete, icon: const Icon(Icons.delete_outline)),
          ],
        ],
      ),
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
                _contentView(),
                if (post.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    height: 220,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Align(
                      alignment: switch (post.imageAlignment) {
                        'left' => Alignment.centerLeft,
                        'right' => Alignment.centerRight,
                        _ => Alignment.center,
                      },
                      child: SizedBox(
                        width: 280,
                        height: 220,
                        child: Image.network(
                          post.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            size: 54,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
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
                    IconButton(
                      onPressed: () => _toggle(false),
                      icon: Icon(
                          post.isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: post.isLiked
                              ? AppColors.danger
                              : AppColors.textSecondary),
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
                    IconButton(
                      onPressed: () => _toggle(true),
                      icon: Icon(post.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
