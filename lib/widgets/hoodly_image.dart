import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';

/// Reusable HoodlyImage widget that seamlessly handles HTTPS URLs,
/// Base64 Data URIs (storage fallback), and local File paths with clean error handling.
class HoodlyImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Widget? fallbackWidget;
  final double? width;
  final double? height;

  const HoodlyImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.fallbackWidget,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return fallbackWidget ?? const SizedBox.shrink();
    }

    final trimmed = imageUrl!.trim();

    // 1. Network Image (http / https)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            fallbackWidget ?? const SizedBox.shrink(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF2F0FA),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    // 2. Base64 Data URI (data:image/...)
    if (trimmed.startsWith('data:image') && trimmed.contains(';base64,')) {
      try {
        final base64Str = trimmed.split(';base64,').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              fallbackWidget ?? const SizedBox.shrink(),
        );
      } catch (_) {
        return fallbackWidget ?? const SizedBox.shrink();
      }
    }

    // 3. Local File Path (/data/..., file://..., C:\...)
    try {
      final cleanPath = trimmed.startsWith('file://')
          ? trimmed.replaceFirst('file://', '')
          : trimmed;
      final file = io.File(cleanPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              fallbackWidget ?? const SizedBox.shrink(),
        );
      }
    } catch (_) {}

    return fallbackWidget ?? const SizedBox.shrink();
  }
}
