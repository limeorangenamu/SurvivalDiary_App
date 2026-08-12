import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/data/models.dart';
import 'package:project_survival_diary/features/community/community_search_page.dart';

CommunityPost _post({required String category, required String title}) {
  return CommunityPost(
    id: title,
    author: '절약러',
    authorEmoji: '🙂',
    timeAgo: '방금 전',
    category: category,
    title: title,
    body: '생활비를 아끼는 방법을 공유해요.',
    hashtags: const ['생활비절약'],
    likeCount: 1,
    commentCount: 2,
    hasImage: false,
  );
}

void main() {
  testWidgets('검색 화면에 최근 검색어와 추천 검색어가 표시된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CommunitySearchPage(posts: []),
      ),
    );

    expect(find.text('최근 검색어'), findsOneWidget);
    expect(find.text('인기 통합 검색어'), findsOneWidget);
    expect(find.text('많이 찾는 절약 태그'), findsOneWidget);
  });

  testWidgets('검색어가 제목·내용·태그에 일치하는 게시물을 전체 결과로 보여준다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CommunitySearchPage(
          posts: [
            _post(category: '자유게시판', title: '식비를 줄이는 장보기'),
            _post(category: '질문', title: '이번 달 예산 궁금해요'),
          ],
        ),
      ),
    );

    await tester.enterText(
        find.byKey(const ValueKey('community-search-input')), '생활비');
    await tester.tap(find.byKey(const ValueKey('community-search-submit')));
    await tester.pumpAndSettle();

    expect(find.text('자유게시판'), findsNWidgets(2));
    expect(find.text('식비를 줄이는 장보기'), findsOneWidget);
    expect(find.text('질문'), findsNWidgets(2));
  });

  testWidgets('검색 결과가 없으면 생활일기 빈 상태를 보여준다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CommunitySearchPage(posts: []),
      ),
    );

    await tester.enterText(
        find.byKey(const ValueKey('community-search-input')), '없는검색어');
    await tester.tap(find.byKey(const ValueKey('community-search-submit')));
    await tester.pumpAndSettle();

    expect(find.text('아직 찾은 이야기가 없어요'), findsOneWidget);
    expect(find.text('다른 절약 키워드로 다시 찾아볼까요?'), findsOneWidget);
  });
}
