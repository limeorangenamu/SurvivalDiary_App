import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';

class CommunityPostImageStrip extends StatelessWidget {
  const CommunityPostImageStrip({
    super.key,
    required this.imageUrls,
    this.height = 112,
    this.maxImages = 2,
  });

  final List<String> imageUrls;
  final double height;
  final int maxImages;

  @override
  Widget build(BuildContext context) {
    final visibleImages = imageUrls.take(maxImages).toList();
    if (visibleImages.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (var index = 0; index < visibleImages.length; index++) ...[
            if (index > 0) const SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _CommunityPostImage(imageUrl: visibleImages[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommunityPostImage extends StatelessWidget {
  const _CommunityPostImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final bytes = _dataImageBytes(imageUrl);
    if (bytes != null) {
      return Image.memory(
        bytes,
        key: ValueKey(imageUrl),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: _errorBuilder,
      );
    }

    return Image.network(
      _resolvedUrl(imageUrl),
      key: ValueKey(imageUrl),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: _errorBuilder,
    );
  }

  Uint8List? _dataImageBytes(String value) {
    if (!value.startsWith('data:image/') || !value.contains(',')) return null;
    try {
      return base64Decode(value.substring(value.indexOf(',') + 1));
    } on FormatException {
      return null;
    }
  }

  String _resolvedUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return '${AppConfig.apiBaseUrl}${value.startsWith('/') ? '' : '/'}$value';
  }

  Widget _errorBuilder(
      BuildContext context, Object error, StackTrace? stackTrace) {
    return const ColoredBox(
      color: AppColors.surfaceAlt,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
