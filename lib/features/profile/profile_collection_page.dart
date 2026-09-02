import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models.dart';
import '../auth/auth_session.dart';
import '../community/data/community_api_client.dart';

class ProfileCollectionPage extends StatefulWidget {
  const ProfileCollectionPage({required this.type, super.key});

  final String type;

  @override
  State<ProfileCollectionPage> createState() => _ProfileCollectionPageState();
}

class _ProfileCollectionPageState extends State<ProfileCollectionPage> {
  final _apiClient = CommunityApiClient();
  List<CommunityPost> _posts = const [];
  List<CommunityPost> _allPosts = const [];
  bool _loading = true;

  String get _title => switch (widget.type) {
        'comment' => '내 댓글',
        'qna' => '나의 Q&A',
        _ => '북마크한 글',
      };

  bool get _isQna => widget.type == 'qna';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        _isQna
            ? _apiClient.getMyPosts(accessToken: token)
            : _apiClient.getPosts(accessToken: token),
        if (_isQna) _apiClient.getFaqs(accessToken: token),
      ]);
      final posts = results.first;
      final faqs = _isQna ? results.last : const <CommunityPost>[];
      if (!mounted) return;
      setState(() {
        _allPosts = faqs;
        _posts = switch (widget.type) {
          'comment' => posts
              .where((post) => post.commentCount > 0 && post.isOwner)
              .toList(),
          'qna' => posts
              .where((post) => post.category == '질문' && post.isOwner)
              .toList(),
          _ => posts.where((post) => post.isBookmarked).toList(),
        };
        _loading = false;
      });
    } on CommunityApiException {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPost(CommunityPost post) {
    if (!post.isAccessible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작성자와 관리자만 확인할 수 있는 글이에요.')),
      );
      return;
    }
    Navigator.pushNamed(context, AppRoutes.postDetail, arguments: post);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      floatingActionButton: _isQna
          ? FloatingActionButton.extended(
              key: const ValueKey('profile-qna-write'),
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.postWrite,
                arguments: '질문',
              ),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('질문하기'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isQna
              ? _QnaContent(myPosts: _posts, allPosts: _allPosts)
              : _posts.isEmpty
                  ? _EmptyCollection(title: _title)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      itemCount: _posts.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(post.title,
                              style: AppTextStyles.sectionTitle),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              post.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMuted,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _openPost(post),
                        );
                      },
                    ),
    );
  }
}

class _QnaContent extends StatelessWidget {
  const _QnaContent({required this.myPosts, required this.allPosts});

  final List<CommunityPost> myPosts;
  final List<CommunityPost> allPosts;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        children: [
          const Text('나의 Q&A', style: AppTextStyles.title),
          const SizedBox(height: 10),
          if (myPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('아직 등록한 질문이 없어요.')),
            )
          else
            for (final post in myPosts) _QnaTile(post: post),
          const Divider(height: 44),
          const Text('자주 묻는 질문', style: AppTextStyles.title),
          const SizedBox(height: 10),
          if (allPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('자주 묻는 질문을 준비하고 있어요.')),
            )
          else
            for (final post in allPosts) _QnaTile(post: post),
        ],
      );
}

class _QnaTile extends StatelessWidget {
  const _QnaTile({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: post.adminInquiry || post.isSecret
            ? Icon(
                post.adminInquiry
                    ? Icons.support_agent_rounded
                    : Icons.lock_outline_rounded,
                color: AppColors.primary,
              )
            : null,
        title: Text(post.title, style: AppTextStyles.sectionTitle),
        subtitle: Text(
          post.adminInquiry
              ? (post.isAnswered ? '관리자 답변 완료' : '관리자 답변 대기')
              : post.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.postDetail,
          arguments: post,
        ),
      );
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_stories_outlined,
                size: 72,
                color: AppColors.border,
              ),
              const SizedBox(height: 18),
              Text('$title이 아직 없어요', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 6),
              const Text('커뮤니티에서 이야기를 만나보세요.', style: AppTextStyles.bodyMuted),
            ],
          ),
        ),
      );
}
