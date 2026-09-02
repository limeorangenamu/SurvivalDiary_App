import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_survival_diary/features/community/data/community_api_client.dart';

void main() {
  const image = 'data:image/png;base64,preview-image';

  test('HTML 본문의 태그를 제거하고 이미지를 추출한다', () async {
    final client = _clientWithContent(
      '<p>본문 <strong>내용</strong></p><img src="$image">',
    );

    final posts = await client.getPosts(accessToken: 'token');

    expect(posts.single.body, '본문 내용');
    expect(posts.single.imageUrls, [image]);
    expect(posts.single.hasImage, isTrue);
    expect(posts.single.authorSavingBadge?.code, 'LATTE');
    expect(posts.single.authorSavingBadge?.savedAmount, 5500);
    expect(posts.single.adminInquiry, isTrue);
    expect(posts.single.isSecret, isTrue);
    expect(posts.single.isAccessible, isTrue);
    expect(posts.single.isAnswered, isFalse);
  });

  test('Quill 본문의 문장과 이미지를 추출한다', () async {
    final client = _clientWithContent(jsonEncode([
      {'insert': '절약 이야기\n'},
      {
        'insert': {'image': image},
      },
    ]));

    final posts = await client.getPosts(accessToken: 'token');

    expect(posts.single.body, '절약 이야기');
    expect(posts.single.imageUrls, [image]);
  });

  test('FAQ 전용 API에서 관리자 질문을 불러온다', () async {
    late Uri requestedUri;
    final client = CommunityApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'content': [
                {
                  'postId': 9,
                  'author': '관리자',
                  'authorRole': 'ADMIN',
                  'category': '질문',
                  'title': '예산은 어떻게 설정하나요?',
                  'content': '<p>월 수입을 기준으로 설정해 주세요.</p>',
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final faqs = await client.getFaqs(accessToken: 'token');

    expect(requestedUri.path, '/api/community/posts/faqs');
    expect(faqs.single.title, '예산은 어떻게 설정하나요?');
    expect(faqs.single.isAdminAuthor, isTrue);
  });

  test('내 Q&A API는 관리자 문의를 포함해 조회한다', () async {
    late Uri requestedUri;
    final client = CommunityApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'content': [
                {
                  'postId': 11,
                  'author': '작성자',
                  'category': '질문',
                  'title': '관리자 문의',
                  'content': '문의 내용',
                  'adminInquiry': true,
                  'secret': false,
                  'accessible': true,
                  'answered': true,
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final posts = await client.getMyPosts(accessToken: 'token');

    expect(requestedUri.path, '/api/community/posts/mine');
    expect(posts.single.adminInquiry, isTrue);
    expect(posts.single.isAnswered, isTrue);
  });

  test('글 작성 요청에 관리자 문의와 비밀글 설정을 구분해 담는다', () {
    const request = CreateCommunityPostRequest(
      category: '질문',
      title: '문의',
      content: '내용',
      adminInquiry: true,
      secret: false,
    );

    expect(request.toJson()['adminInquiry'], isTrue);
    expect(request.toJson()['secret'], isFalse);
  });
}

CommunityApiClient _clientWithContent(String content) {
  return CommunityApiClient(
    baseUrl: 'https://example.com',
    client: MockClient((request) async {
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'content': [
              {
                'postId': 1,
                'author': '작성자',
                'category': '절약 인증',
                'title': '제목',
                'content': content,
                'imageUrls': <String>[],
                'authorSavingBadge': {
                  'code': 'LATTE',
                  'label': '라테 한 잔',
                  'emoji': '🥛',
                  'thresholdAmount': 5000,
                  'savedAmount': 5500,
                  'earnedMonth': '2026-08',
                  'message': '지난달에는 라테 한 잔에 가까운 금액을 절약했어요',
                },
                'adminInquiry': true,
                'secret': true,
                'accessible': true,
                'answered': false,
              },
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
}
