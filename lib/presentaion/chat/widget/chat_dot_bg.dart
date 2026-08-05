import 'package:flutter/material.dart';

class ChatDotBackground extends StatelessWidget {
  final Widget child;
  const ChatDotBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1E1B29) : const Color(0xFFFDFDFC),
      child: CustomPaint(
        painter: _DotPatternPainter(
          dotColor: isDark
              ? const Color(0xFF3C3489).withOpacity(0.35)
              : const Color(0xFFCECBF6),
        ),
        child: child,
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color dotColor;
  const _DotPatternPainter({required this.dotColor});

  static const double spacing = 22;
  static const double radius = 1.2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor;
}