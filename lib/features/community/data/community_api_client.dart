import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../data/models.dart';

class CommunityApiException implements Exception {
  const CommunityApiException(this.message);
  final String message;
}

class CreateCommunityPostRequest {
  const CreateCommunityPostRequest(
      {required this.category,
      required this.title,
      required this.content,
      this.hashtags = const [],
      this.imageUrls = const [],
      this.imageAlignment = 'center'});
  final String category;
  final String title;
  final String content;
  final List<String> hashtags;
  final List<String> imageUrls;
  final String imageAlignment;

  Map<String, dynamic> toJson() => {
        'category': category,
        'title': title.trim(),
        'content': content,
        'hashtags': hashtags,
        'imageUrls': imageUrls,
        'imageAlignment': imageAlignment,
      };
}

class CommunityApiClient {
  CommunityApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;
  final http.Client _client;
  final String _baseUrl;

  Future<List<CommunityPost>> getPosts(
      {required String accessToken, String? category}) async {
    final uri =
        Uri.parse('$_baseUrl/api/community/posts').replace(queryParameters: {
      if (category != null && category.isNotEmpty) 'category': category,
      'size': '50',
    });
    final response = await _client.get(uri, headers: _headers(accessToken));
    final data = _data(response);
    final content = data['content'] as List<dynamic>? ?? const [];
    return content.map((item) => _post(item as Map<String, dynamic>)).toList();
  }

  Future<CommunityPost> create(
      {required String accessToken,
      required CreateCommunityPostRequest request}) async {
    final response = await _client.post(
        Uri.parse('$_baseUrl/api/community/posts'),
        headers: {..._headers(accessToken), 'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()));
    return _post(_data(response));
  }

  Future<CommunityPost> getPost(
      {required String accessToken, required String postId}) async {
    final response = await _client.get(
        Uri.parse('$_baseUrl/api/community/posts/$postId'),
        headers: _headers(accessToken));
    return _post(_data(response));
  }

  Future<CommunityPost> update(
      {required String accessToken,
      required String postId,
      required CreateCommunityPostRequest request}) async {
    final response = await _client.put(
        Uri.parse('$_baseUrl/api/community/posts/$postId'),
        headers: {..._headers(accessToken), 'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()));
    return _post(_data(response));
  }

  Future<void> delete(
      {required String accessToken, required String postId}) async {
    final response = await _client.delete(
        Uri.parse('$_baseUrl/api/community/posts/$postId'),
        headers: _headers(accessToken));
    _data(response);
  }

  Future<CommunityPost> toggleLike(
          {required String accessToken, required String postId}) async =>
      _toggle(accessToken, postId, 'like');
  Future<CommunityPost> toggleBookmark(
          {required String accessToken, required String postId}) async =>
      _toggle(accessToken, postId, 'bookmark');

  Future<List<CommunityComment>> getComments({
    required String accessToken,
    required String postId,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/community/posts/$postId/comments'),
      headers: _headers(accessToken),
    );
    final data = _listData(response);
    return data.map((item) => _comment(item)).toList();
  }

  Future<CommunityComment> createComment({
    required String accessToken,
    required String postId,
    required String content,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/community/posts/$postId/comments'),
      headers: {..._headers(accessToken), 'Content-Type': 'application/json'},
      body: jsonEncode({'content': content.trim()}),
    );
    return _comment(_data(response));
  }

  Future<void> deleteComment({
    required String accessToken,
    required String commentId,
  }) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/api/community/posts/comments/$commentId'),
      headers: _headers(accessToken),
    );
    _data(response);
  }

  Future<CommunityPost> _toggle(String token, String id, String action) async {
    final response = await _client.post(
        Uri.parse('$_baseUrl/api/community/posts/$id/$action'),
        headers: _headers(token));
    return _post(_data(response));
  }

  Map<String, String> _headers(String token) =>
      {'Accept': 'application/json', 'Authorization': 'Bearer $token'};

  Map<String, dynamic> _data(http.Response response) {
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      final error = body['error'] as Map<String, dynamic>?;
      throw CommunityApiException(
          error?['message'] as String? ?? '커뮤니티 요청에 실패했어요.');
    }
    return body['data'] as Map<String, dynamic>;
  }

  List<dynamic> _listData(http.Response response) {
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      final error = body['error'] as Map<String, dynamic>?;
      throw CommunityApiException(
          error?['message'] as String? ?? '커뮤니티 요청에 실패했어요.');
    }
    return body['data'] as List<dynamic>? ?? const [];
  }

  CommunityPost _post(Map<String, dynamic> json) {
    final images = (json['imageUrls'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();
    return CommunityPost(
      id: '${json['postId']}',
      author: (json['nickname'] as String?)?.trim().isNotEmpty == true
          ? json['nickname'] as String
          : json['author'] as String? ?? '사용자',
      authorEmoji: '생',
      timeAgo: _timeAgo(json['createdAt'] as String?),
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: _contentPreview(json['content'] as String? ?? ''),
      contentJson: json['content'] as String? ?? '',
      hashtags: (json['hashtags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      hasImage: images.isNotEmpty,
      imageUrls: images,
      imageAlignment: json['imageAlignment'] as String? ?? 'center',
      isLiked: json['liked'] as bool? ?? false,
      isBookmarked: json['bookmarked'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      isOwner: json['owner'] as bool? ?? false,
    );
  }

  CommunityComment _comment(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    return CommunityComment(
      id: '${json['commentId']}',
      author: (json['nickname'] as String?)?.trim().isNotEmpty == true
          ? json['nickname'] as String
          : json['author'] as String? ?? '사용자',
      content: json['content'] as String? ?? '',
      timeAgo: _timeAgo(json['createdAt'] as String?),
      createdAt: createdAt,
      isOwner: json['owner'] as bool? ?? false,
    );
  }

  String _contentPreview(String content) {
    try {
      final delta = jsonDecode(content) as List<dynamic>;
      return delta
          .whereType<Map<String, dynamic>>()
          .map((op) => op['insert'])
          .whereType<String>()
          .join()
          .trim();
    } catch (_) {
      return content;
    }
  }

  String _timeAgo(String? raw) {
    final created = DateTime.tryParse(raw ?? '')?.toLocal();
    if (created == null) return '';
    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}
