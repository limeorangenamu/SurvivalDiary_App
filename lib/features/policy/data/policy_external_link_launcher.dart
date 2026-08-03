import 'package:url_launcher/url_launcher.dart';

enum PolicyExternalLinkErrorType { invalidUrl, launchFailed }

class PolicyExternalLinkException implements Exception {
  const PolicyExternalLinkException(this.message, {required this.type});

  final String message;
  final PolicyExternalLinkErrorType type;

  @override
  String toString() => message;
}

typedef ExternalUrlLaunch = Future<bool> Function(
  Uri url, {
  required LaunchMode mode,
});

class PolicyExternalLinkLauncher {
  PolicyExternalLinkLauncher({ExternalUrlLaunch? launch})
      : _launch = launch ?? launchUrl;

  final ExternalUrlLaunch _launch;

  Future<void> open(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (!_isAllowed(uri)) {
      throw const PolicyExternalLinkException(
        '정책 링크 주소가 올바르지 않아요. 정책 상세에서 기관 정보를 확인해 주세요.',
        type: PolicyExternalLinkErrorType.invalidUrl,
      );
    }

    try {
      final launched = await _launch(
        uri!,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const PolicyExternalLinkException(
          '브라우저를 열지 못했어요. 잠시 후 다시 시도해 주세요.',
          type: PolicyExternalLinkErrorType.launchFailed,
        );
      }
    } on PolicyExternalLinkException {
      rethrow;
    } on Object {
      throw const PolicyExternalLinkException(
        '브라우저를 열지 못했어요. 잠시 후 다시 시도해 주세요.',
        type: PolicyExternalLinkErrorType.launchFailed,
      );
    }
  }

  bool _isAllowed(Uri? uri) {
    if (uri == null) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') &&
        uri.hasAuthority &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty;
  }
}
