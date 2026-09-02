import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/features/community/widgets/community_post_image_strip.dart';

void main() {
  const transparentPixel =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAEklEQVR42mNk+M/wHwAEAQH/5v4N3wAAAABJRU5ErkJggg==';

  testWidgets('커뮤니티 이미지는 최대 두 장을 가운데 기준으로 잘라 표시한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CommunityPostImageStrip(
            imageUrls: [transparentPixel, transparentPixel, transparentPixel],
          ),
        ),
      ),
    );

    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(2));
    expect(images.every((image) => image.fit == BoxFit.cover), isTrue);
    expect(
        images.every((image) => image.alignment == Alignment.center), isTrue);
  });
}
