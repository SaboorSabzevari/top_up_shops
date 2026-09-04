
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SmartAvatar extends StatelessWidget {
  final String? path;
  final String fallbackText;
  final double radius;
  final Color? backgroundColor;

  const SmartAvatar({
    super.key,
    required this.path,
    required this.fallbackText,
    this.radius = 20,
    this.backgroundColor,
  });

  bool get _isUrl => path != null && (path!.startsWith('http://') || path!.startsWith('https://'));

  bool get _isLocalFile => path != null && path!.isNotEmpty && !_isUrl;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Colors.grey.shade200;
    final initial = fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?';

    if (_isUrl) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: path!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => SizedBox(
              width: radius,
              height: radius,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => Text(initial),
          ),
        ),
      );
    }

    if (_isLocalFile) {
      final file = File(path!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          backgroundImage: FileImage(file),
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}