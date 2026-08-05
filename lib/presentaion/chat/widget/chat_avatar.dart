import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool? online;
  final Color? ringColor;
  final Color? fallbackColor;
  final Color? fallbackTextColor;

  const ChatAvatar({
    Key? key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.online,
    this.ringColor,
    this.fallbackColor,
    this.fallbackTextColor,
  }) : super(key: key);

  String get initials {
    if (name == null) return '?';
    final parts = name!
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return initials.isNotEmpty ? initials : '?';
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: fallbackTextColor,
      fontSize: size * 0.4,
      fontWeight: FontWeight.bold,
    );

    // Build the avatar circle (with or without image)
    Widget avatar;
    if (imageUrl == null) {
      avatar = CircleAvatar(
        radius: size / 2,
        backgroundColor: fallbackColor,
        child: Text(initials, style: textStyle),
      );
    } else {
      avatar = ClipOval(
        child: Container(
          width: size,
          height: size,
          color: fallbackColor, // fallback while loading / on error
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            memCacheWidth: 150,
            errorWidget: (context, error, stackTrace) {
              // Show initials if image fails
              return Center(child: Text(initials, style: textStyle));
            },
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.surfaceBright,
              highlightColor: Theme.of(context).colorScheme.surfaceDim,
              child: Container(width: 120, height: 120, color: Colors.white),
            ),
          ),
        ),
      );
    }

    // Wrap with online dot if needed
    if (online == null) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online! ? Colors.green : Colors.grey,
              border: Border.all(color: ringColor ?? Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
