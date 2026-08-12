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

  Future<void> _handlePostReturned(Object? result) async {
    if (result == true) {
      await _loadPosts();
      return;
    }
    if (result is! CommunityPost || !mounted) return;
    final index = _posts.indexWhere((post) => post.id == result.id);
    if (index == -1) return;
    setState(() => _posts[index] = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '절약 커뮤니티',
                          style: AppTextStyles.title.copyWith(
                            color: AppColors.surface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          key: const ValueKey('community-notification'),
                          onPressed: () {},
                          color: AppColors.surface,
                          icon: const Icon(Icons.notifications_none_rounded),
                        ),
                        IconButton(
                          key: const ValueKey('community-account'),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.profile,
                          ),
                          color: AppColors.surface,
                          icon: const Icon(Icons.person_outline_rounded),
                        ),
                      ],
                    ),
                    GestureDetector(
                      key: const ValueKey('community-search-entry'),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.communitySearch,
                        arguments: _posts,
                      ),
                      child: Container(
                        height: 50,
                        margin: const EdgeInsets.only(top: 6, bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '절약 정보를 검색해 보세요',
                                style: AppTextStyles.bodyMuted,
                              ),
                            ),
                            const Icon(
                              Icons.search_rounded,
                              color: AppColors.primaryDeep,
                            ),
                          ],
                        ),
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: AppColors.surface,
                      indicatorWeight: 3,
                      labelColor: AppColors.surface,
                      unselectedLabelColor:
                          AppColors.surface.withValues(alpha: 0.62),
                      labelStyle: AppTextStyles.body.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: const [
                        Tab(text: '자유게시판'),
                        Tab(text: '정보 공유'),
                        Tab(text: '절약 인증'),
                        Tab(text: '질문'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _isLoading
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
                                    .where(
                                      (post) => post.category == category,
                                    )
                                    .toList(),
                                onReturned: _handlePostReturned,
                              ),
                          ],
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('post-write-fab'),
        onPressed: _openWrite,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  const _PostList({
    required this.category,
    required this.posts,
    required this.onReturned,
  });

  final String category;
  final List<CommunityPost> posts;
  final Future<void> Function(Object?) onReturned;

  String get _sectionEyebrow => switch (category) {
        '자유게시판' => '오늘의 자유 이야기',
        '정보 공유' => '알아두면 유용한 절약 정보',
        '절약 인증' => '함께 이어가는 절약 습관',
        '질문' => '궁금한 절약 이야기',
        _ => '커뮤니티 이야기',
      };

  String get _sectionTitle => switch (category) {
        '자유게시판' => '일상 속 절약 경험을 나눠보세요',
        '정보 공유' => '생활에 도움 되는 정보를 확인해보세요',
        '절약 인증' => '작은 실천과 성취를 함께 공유해요',
        '질문' => '알뜰한 생활에 대해 자유롭게 물어보세요',
        _ => '함께 나누는 절약 이야기',
      };

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: PageStorageKey('post-list-$category'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      itemCount: posts.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sectionEyebrow,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sectionTitle,
                        style: AppTextStyles.title.copyWith(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        final postIndex = index - 1;
        final post = posts[postIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PostCard(
            post: post,
            onReturned: onReturned,
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.postDetail,
                arguments: post,
              );
              await onReturned(result);
            },
          ),
        );
      },
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.onTap,
    required this.onReturned,
  });

  final CommunityPost post;
  final VoidCallback onTap;
  final Future<void> Function(Object?) onReturned;

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

  @override
  void didUpdateWidget(covariant _PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id || oldWidget.post != widget.post) {
      post = widget.post;
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

  Future<void> _openEdit() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.postWrite,
      arguments: post,
    );
    await widget.onReturned(result);
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('게시글을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = AuthSession.instance.accessToken;
    if (token == null) return;
    try {
      await _apiClient.delete(accessToken: token, postId: post.id);
      await widget.onReturned(true);
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
              if (post.isOwner)
                PopupMenuButton<String>(
                  key: ValueKey('post-menu-${post.id}'),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEdit();
                    } else if (value == 'delete') {
                      _deletePost();
                    }
                  },
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.textTertiary,
                  ),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('수정'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('삭제'),
                    ),
                  ],
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
              if (post.category != '질문')
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _toggle(false),
                  icon: Icon(
                    post.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: post.isLiked
                        ? AppColors.danger
                        : AppColors.textSecondary,
                  ),
                ),
              if (post.category != '질문') ...[
                const SizedBox(width: 4),
                Text('${post.likeCount}', style: AppTextStyles.caption),
              ],
              const SizedBox(width: 16),
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text('${post.commentCount}', style: AppTextStyles.caption),
              const Spacer(),
              if (post.category != '질문')
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
