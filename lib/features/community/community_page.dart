import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models.dart';
import '../auth/auth_session.dart';
import '../../shared/widgets/app_card.dart';
import 'data/community_api_client.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  static const _categories = ['자유게시판', '정보 공유', '절약 인증', '질문'];
  late final TabController _tabController;
  final _apiClient = CommunityApiClient();
  List<CommunityPost> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openWrite() async {
    final created = await Navigator.pushNamed(
      context,
      AppRoutes.postWrite,
      arguments: _categories[_tabController.index],
    );
    if (created == true && mounted) {
      await _loadPosts();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글이 등록된 것처럼 처리했어요.')));
    }
  }

  Future<void> _loadPosts() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '로그인이 필요해요.';
        });
      }
      return;
    }
    try {
      final posts = await _apiClient.getPosts(accessToken: token);
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
          _error = null;
        });
      }
    } on CommunityApiException catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('절약 커뮤니티'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryDeep,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: '자유게시판'),
            Tab(text: '정보 공유'),
            Tab(text: '절약 인증'),
            Tab(text: '질문'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    for (final category in _categories)
                      _PostList(
                        category: category,
                        posts: _posts
                            .where((post) => post.category == category)
                            .toList(),
                        onReturned: _loadPosts,
                      ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('post-write-fab'),
        onPressed: _openWrite,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('글쓰기'),
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  const _PostList(
      {required this.category, required this.posts, required this.onReturned});

  final String category;
  final List<CommunityPost> posts;
  final Future<void> Function() onReturned;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: PageStorageKey('post-list-$category'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final post = posts[index];
        return _PostCard(
          post: post,
          onTap: () async {
            await Navigator.pushNamed(context, AppRoutes.postDetail,
                arguments: post);
            await onReturned();
          },
        );
      },
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post, required this.onTap});

  final CommunityPost post;
  final VoidCallback onTap;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late CommunityPost post;
  final _apiClient = CommunityApiClient();

  @override
  void initState() {
    super.initState();
    post = widget.post;
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
    return AppCard(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceAlt,
                child: Text(
                  post.authorEmoji,
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              const SizedBox(width: 9),
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
              const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(post.title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          Text(
            post.body,
            style: AppTextStyles.bodyMuted,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (post.hasImage) ...[
            const SizedBox(height: 12),
            Container(
              height: 128,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 34,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(height: 4),
                  Text('이미지 자리표시자', style: AppTextStyles.captionTiny),
                ],
              ),
            ),
          ],
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 5,
            children: [
              for (final tag in post.hashtags)
                Text(
                  '#$tag',
                  style: AppTextStyles.captionTiny.copyWith(
                    color: AppColors.primaryDeep,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _toggle(false),
                icon: Icon(
                  post.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 18,
                  color:
                      post.isLiked ? AppColors.danger : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Text('${post.likeCount}', style: AppTextStyles.caption),
              const SizedBox(width: 16),
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text('${post.commentCount}', style: AppTextStyles.caption),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _toggle(true),
                icon: Icon(post.isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
