import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/theme/app_theme.dart';
import 'package:project_survival_diary/features/policy/data/policy_external_link_launcher.dart';
import 'package:project_survival_diary/features/policy/data/policy_models.dart';
import 'package:project_survival_diary/features/policy/policy_external_link_confirm_page.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  test('https 정책 링크를 외부 애플리케이션 모드로 연다', () async {
    late Uri launchedUri;
    late LaunchMode launchedMode;
    final launcher = PolicyExternalLinkLauncher(
      launch: (url, {required mode}) async {
        launchedUri = url;
        launchedMode = mode;
        return true;
      },
    );

    await launcher.open('https://example.com/policies/1');

    expect(launchedUri, Uri.parse('https://example.com/policies/1'));
    expect(launchedMode, LaunchMode.externalApplication);
  });

  test('http와 https가 아닌 주소는 실행 전에 차단한다', () async {
    var launchCalled = false;
    final launcher = PolicyExternalLinkLauncher(
      launch: (url, {required mode}) async {
        launchCalled = true;
        return true;
      },
    );

    for (final invalidUrl in [
      'javascript:alert(1)',
      'https:///missing-host',
      'https://user@example.com/policies/1',
    ]) {
      expect(
        () => launcher.open(invalidUrl),
        throwsA(
          isA<PolicyExternalLinkException>().having(
            (error) => error.type,
            'type',
            PolicyExternalLinkErrorType.invalidUrl,
          ),
        ),
      );
    }
    expect(launchCalled, isFalse);
  });

  test('브라우저가 주소를 처리하지 못하면 실행 실패로 구분한다', () async {
    final launcher = PolicyExternalLinkLauncher(
      launch: (url, {required mode}) async => false,
    );

    expect(
      () => launcher.open('https://example.com'),
      throwsA(
        isA<PolicyExternalLinkException>().having(
          (error) => error.type,
          'type',
          PolicyExternalLinkErrorType.launchFailed,
        ),
      ),
    );
  });

  testWidgets('신청 사이트 실행 중에는 버튼 중복 입력을 막는다', (tester) async {
    final launchResult = Completer<bool>();
    var launchCount = 0;
    final launcher = PolicyExternalLinkLauncher(
      launch: (url, {required mode}) {
        launchCount += 1;
        return launchResult.future;
      },
    );
    await tester.pumpWidget(
      _externalLinkApp(launcher: launcher),
    );

    await tester.tap(
      find.byKey(const ValueKey('policy-open-external-button')),
    );
    await tester.pump();

    expect(find.text('브라우저 여는 중'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('policy-open-external-button')),
    );
    expect(button.onPressed, isNull);
    expect(launchCount, 1);

    launchResult.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('신청 사이트 열기'), findsOneWidget);
  });

  testWidgets('참고 링크를 신청 사이트와 다른 안내로 표시한다', (tester) async {
    final launcher = PolicyExternalLinkLauncher(
      launch: (url, {required mode}) async => true,
    );
    await tester.pumpWidget(
      _externalLinkApp(
        launcher: launcher,
        type: PolicyExternalLinkType.reference,
      ),
    );

    expect(find.text('참고 링크 이동'), findsOneWidget);
    expect(find.text('정책 안내 페이지로 이동할까요?'), findsOneWidget);
    expect(find.text('참고 링크 주소'), findsOneWidget);
    expect(find.text('참고 링크 열기'), findsOneWidget);
    expect(find.textContaining('실제 신청 경로임을 보장하지 않아요.'), findsOneWidget);
  });

  testWidgets('로그인 주소는 이동 전에 로그인이 필요함을 표시한다', (tester) async {
    final launcher = PolicyExternalLinkLauncher(
      launch: (url, {required mode}) async => true,
    );
    await tester.pumpWidget(
      _externalLinkApp(
        launcher: launcher,
        officialLinkType: PolicyOfficialLinkType.loginRequired,
      ),
    );

    expect(find.text('로그인이 필요한 서비스입니다'), findsOneWidget);
    expect(find.text('로그인 사이트 주소'), findsOneWidget);
    expect(find.text('로그인 페이지 열기'), findsOneWidget);
  });

  testWidgets('기관 홈페이지 주소는 정책명 검색 필요를 안내한다', (tester) async {
    final launcher = PolicyExternalLinkLauncher(
      launch: (url, {required mode}) async => true,
    );
    await tester.pumpWidget(
      _externalLinkApp(
        launcher: launcher,
        officialLinkType: PolicyOfficialLinkType.institutionHome,
      ),
    );

    expect(find.text('기관 홈페이지로 이동할까요?'), findsOneWidget);
    expect(find.textContaining('이동 후 정책명을 검색해 주세요.'), findsOneWidget);
    expect(find.text('기관 홈페이지 열기'), findsOneWidget);
  });

  testWidgets('브라우저 실행 실패를 사용자에게 안내한다', (tester) async {
    final launcher = PolicyExternalLinkLauncher(
      launch: (url, {required mode}) async => false,
    );
    await tester.pumpWidget(
      _externalLinkApp(launcher: launcher),
    );

    await tester.tap(
      find.byKey(const ValueKey('policy-open-external-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('브라우저를 열지 못했어요. 잠시 후 다시 시도해 주세요.'),
      findsOneWidget,
    );
  });
}

Widget _externalLinkApp({
  required PolicyExternalLinkLauncher launcher,
  PolicyExternalLinkType type = PolicyExternalLinkType.application,
  PolicyOfficialLinkType officialLinkType = PolicyOfficialLinkType.unknown,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: PolicyExternalLinkConfirmPage(
      arguments: PolicyExternalLinkArguments(
        title: '청년 주거 지원',
        url: 'https://example.com/policies/1',
        type: type,
        officialLinkType: officialLinkType,
      ),
      launcher: launcher,
    ),
  );
}
