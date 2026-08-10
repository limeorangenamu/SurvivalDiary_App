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
  final _commentController = TextEditingController();
  final _comments = <CommunityComment>[];
  bool _commentsLoaded = false;
  bool _isCommentSubmitting = false;

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
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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

  Future<void> _loadComments() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) return;
    try {
      final comments = await _apiClient.getComments(
        accessToken: token,
        postId: post.id,
      );
      if (mounted) {
        setState(() {
          _comments
            ..clear()
            ..addAll(comments);
          _commentsLoaded = true;
        });
      }
    } on CommunityApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isCommentSubmitting) return;
    final token = AuthSession.instance.accessToken;
    if (token == null) return;
    setState(() => _isCommentSubmitting = true);
    try {
      final comment = await _apiClient.createComment(
        accessToken: token,
        postId: post.id,
        content: content,
      );
      if (mounted) {
        setState(() {
          _comments.add(comment);
          _commentsLoaded = true;
          _commentController.clear();
          _isCommentSubmitting = false;
        });
      }
    } on CommunityApiException catch (error) {
      if (mounted) {
        setState(() => _isCommentSubmitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    final token = AuthSession.instance.accessToken;
    if (token == null) return;
    try {
      await _apiClient.deleteComment(
        accessToken: token,
        commentId: comment.id,
      );
      if (mounted) setState(() => _comments.removeWhere((item) => item.id == comment.id));
    } on CommunityApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
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
                    Text(
                      '${_commentsLoaded ? _comments.length : post.commentCount}',
                      style: AppTextStyles.caption,
                    ),
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
          const SizedBox(height: 16),
          const Text('댓글', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          if (_comments.isEmpty && _commentsLoaded)
            const Text('첫 댓글을 남겨 보세요.', style: AppTextStyles.bodyMuted)
          else
            for (final comment in _comments)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.author,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(comment.content, style: AppTextStyles.body),
                            const SizedBox(height: 4),
                            Text(comment.timeAgo, style: AppTextStyles.captionTiny),
                          ],
                        ),
                      ),
                      if (comment.isOwner)
                        IconButton(
                          tooltip: '댓글 삭제',
                          onPressed: () => _deleteComment(comment),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 4),
          TextField(
            controller: _commentController,
            maxLength: 1000,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submitComment(),
            decoration: InputDecoration(
              hintText: '댓글을 입력해 주세요.',
              counterText: '',
              suffixIcon: IconButton(
                onPressed: _isCommentSubmitting ? null : _submitComment,
                icon: _isCommentSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
