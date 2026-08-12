import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models.dart';

class CommunitySearchPage extends StatefulWidget {
  const CommunitySearchPage({required this.posts, super.key});

  final List<CommunityPost> posts;

  @override
  State<CommunitySearchPage> createState() => _CommunitySearchPageState();
}

class _CommunitySearchPageState extends State<CommunitySearchPage>
    with SingleTickerProviderStateMixin {
  static const _categories = ['전체', '자유게시판', '정보 공유', '절약 인증', '질문'];
  static const _popularQueries = ['한 달 식비 줄이기', '알뜰 장보기', '고정비 절약'];
  static const _popularTags = ['#식비절약', '#생활비절약', '#절약인증'];

  late final TabController _tabController;
  late final TextEditingController _controller;
  final _recentQueries = <String>['식비'];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _controller = TextEditingController();
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<CommunityPost> get _matches {
    final keyword = _query.trim().toLowerCase().replaceFirst('#', '');
    if (keyword.isEmpty) return const [];
    return widget.posts.where((post) {
      final searchable = [
        post.title,
        post.body,
        ...post.hashtags,
      ].join(' ').toLowerCase();
      return searchable.contains(keyword);
    }).toList();
  }

  void _search(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    setState(() {
      _query = query;
      _recentQueries.remove(query);
      _recentQueries.insert(0, query);
      if (_recentQueries.length > 5) _recentQueries.removeLast();
    });
  }

  void _selectSuggestion(String value) {
    final query = value.replaceFirst('#', '');
    _controller
      ..text = query
      ..selection = TextSelection.collapsed(offset: query.length);
    _search(query);
  }

  void _clearRecent() => setState(_recentQueries.clear);

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('community-search-back'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('community-search-input'),
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) => setState(() {}),
                      onSubmitted: _search,
                      decoration: const InputDecoration(
                        hintText: '#태그, 제목, 내용 검색하기',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('community-search-submit'),
                    onPressed: () => _search(_controller.text),
                    color: AppColors.primary,
                    icon: const Icon(Icons.search_rounded, size: 30),
                  ),
                ],
              ),
            ),
            if (!hasQuery)
              Expanded(
                  child: _DiscoveryContent(
                recentQueries: _recentQueries,
                popularQueries: _popularQueries,
                popularTags: _popularTags,
                onSelect: _selectSuggestion,
                onClearRecent: _clearRecent,
                onRemoveRecent: (query) =>
                    setState(() => _recentQueries.remove(query)),
              ))
            else ...[
              _SearchTabs(
                controller: _tabController,
                categories: _categories,
              ),
              Expanded(
                child: _SearchResults(
                  query: _query,
                  posts: _matches,
                  category: _categories[_tabController.index],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DiscoveryContent extends StatelessWidget {
  const _DiscoveryContent({
    required this.recentQueries,
    required this.popularQueries,
    required this.popularTags,
    required this.onSelect,
    required this.onClearRecent,
    required this.onRemoveRecent,
  });

  final List<String> recentQueries;
  final List<String> popularQueries;
  final List<String> popularTags;
  final ValueChanged<String> onSelect;
  final VoidCallback onClearRecent;
  final ValueChanged<String> onRemoveRecent;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        _DiscoveryHeading(
            title: '최근 검색어', action: '전체 삭제', onTap: onClearRecent),
        if (recentQueries.isEmpty)
          const Text('최근 검색어가 없어요', style: AppTextStyles.bodyMuted)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final query in recentQueries)
                InputChip(
                  label: Text(query),
                  onPressed: () => onSelect(query),
                  onDeleted: () => onRemoveRecent(query),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  backgroundColor: AppColors.surfaceAlt,
                  side: BorderSide.none,
                  labelStyle: AppTextStyles.bodyMuted,
                ),
            ],
          ),
        const SizedBox(height: 54),
        const _DiscoveryHeading(title: '인기 통합 검색어'),
        const SizedBox(height: 12),
        for (var i = 0; i < popularQueries.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Text('${i + 1}',
                style: AppTextStyles.title.copyWith(color: AppColors.primary)),
            title: Text(popularQueries[i], style: AppTextStyles.sectionTitle),
            onTap: () => onSelect(popularQueries[i]),
          ),
        const SizedBox(height: 42),
        const _DiscoveryHeading(title: '많이 찾는 절약 태그'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in popularTags)
              ActionChip(
                label: Text(tag),
                onPressed: () => onSelect(tag),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                labelStyle: AppTextStyles.bodyMuted,
              ),
          ],
        ),
      ],
    );
  }
}

class _DiscoveryHeading extends StatelessWidget {
  const _DiscoveryHeading({required this.title, this.action, this.onTap});

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          const Spacer(),
          if (action != null)
            TextButton(onPressed: onTap, child: Text(action!)),
        ],
      );
}

class _SearchTabs extends StatelessWidget {
  const _SearchTabs({required this.controller, required this.categories});

  final TabController controller;
  final List<String> categories;

  @override
  Widget build(BuildContext context) => TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textTertiary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        tabs: [for (final category in categories) Tab(text: category)],
      );
}

class _SearchResults extends StatelessWidget {
  const _SearchResults(
      {required this.query, required this.posts, required this.category});

  final String query;
  final List<CommunityPost> posts;
  final String category;

  @override
  Widget build(BuildContext context) {
    final filtered = category == '전체'
        ? posts
        : posts.where((post) => post.category == category).toList();
    if (filtered.isEmpty) return _EmptySearchResult(query: query);

    if (category == '전체') {
      final grouped = <String, List<CommunityPost>>{};
      for (final post in filtered) {
        grouped.putIfAbsent(post.category, () => []).add(post);
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          for (final entry in grouped.entries) ...[
            Text(entry.key, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            for (final post in entry.value.take(3))
              _CompactSearchPost(post: post),
            const SizedBox(height: 22),
          ],
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 26),
      itemBuilder: (context, index) =>
          _DetailedSearchPost(post: filtered[index]),
    );
  }
}

class _CompactSearchPost extends StatelessWidget {
  const _CompactSearchPost({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.postDetail, arguments: post),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _PostThumbnail(post: post, size: 64),
              const SizedBox(width: 12),
              Expanded(child: _PostSummary(post: post, compact: true)),
            ],
          ),
        ),
      );
}

class _DetailedSearchPost extends StatelessWidget {
  const _DetailedSearchPost({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.postDetail, arguments: post),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PostThumbnail(post: post, size: 84),
            const SizedBox(width: 14),
            Expanded(child: _PostSummary(post: post)),
          ],
        ),
      );
}

class _PostSummary extends StatelessWidget {
  const _PostSummary({required this.post, this.compact = false});

  final CommunityPost post;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.title,
              style: AppTextStyles.sectionTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(post.body,
              style: AppTextStyles.bodyMuted,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis),
          if (post.hashtags.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              post.hashtags.map((tag) => '#$tag').join(' '),
              style: AppTextStyles.captionTiny
                  .copyWith(color: AppColors.primaryDeep),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );
}

class _PostThumbnail extends StatelessWidget {
  const _PostThumbnail({required this.post, required this.size});

  final CommunityPost post;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.imageUrls.isEmpty ? null : post.imageUrls.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: AppColors.surfaceAlt,
        child: imageUrl == null
            ? const Icon(Icons.auto_stories_outlined,
                color: AppColors.textTertiary)
            : Image.network(imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.auto_stories_outlined,
                    color: AppColors.textTertiary)),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _DiaryGhost(),
              const SizedBox(height: 28),
              Text('“$query”',
                  style: AppTextStyles.title
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              const Text('아직 찾은 이야기가 없어요', style: AppTextStyles.bodyMuted),
              const SizedBox(height: 4),
              const Text('다른 절약 키워드로 다시 찾아볼까요?', style: AppTextStyles.caption),
            ],
          ),
        ),
      );
}

class _DiaryGhost extends StatelessWidget {
  const _DiaryGhost();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        height: 150,
        child: CustomPaint(painter: _DiaryGhostPainter()),
      );
}

class _DiaryGhostPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.border;
    final dark = Paint()..color = AppColors.textTertiary;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, 55), width: 72, height: 82),
        paint);
    final book = Path()
      ..moveTo(26, 94)
      ..quadraticBezierTo(55, 81, center.dx, 103)
      ..quadraticBezierTo(95, 81, 124, 94)
      ..lineTo(124, 132)
      ..quadraticBezierTo(94, 117, center.dx, 136)
      ..quadraticBezierTo(56, 117, 26, 132)
      ..close();
    canvas.drawPath(book, paint);
    canvas.drawLine(
        center.translate(0, 6), center.translate(0, 32), dark..strokeWidth = 3);
    canvas.drawCircle(const Offset(61, 53), 4, dark);
    canvas.drawCircle(const Offset(89, 53), 4, dark);
    canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx, 62), width: 24, height: 14),
        0.2,
        2.7,
        false,
        dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    canvas.drawCircle(const Offset(132, 39), 3, dark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
