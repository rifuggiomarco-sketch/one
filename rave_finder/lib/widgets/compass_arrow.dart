import 'package:flutter/material.dart';

/// A colored arrow rotated to point at a bonded friend's last known GPS
/// position, the same way a phone maps app rotates a direction arrow -
/// [angleDegrees] is clockwise from straight up on the screen, in the
/// range 0-360.
///
/// Tracks a continuously unwrapped rotation internally so that crossing
/// the 0/360 boundary (e.g. 359 degrees to 1 degree) animates as a
/// short 2 degree turn instead of [AnimatedRotation] naively spinning
/// almost a full circle the other way.
class CompassArrow extends StatefulWidget {
  final double angleDegrees;
  final Color color;
  final double size;

  const CompassArrow({
    super.key,
    required this.angleDegrees,
    required this.color,
    this.size = 240,
  });

  @override
  State<CompassArrow> createState() => _CompassArrowState();
}

class _CompassArrowState extends State<CompassArrow> {
  late double _unwrappedDegrees = widget.angleDegrees;

  @override
  void didUpdateWidget(CompassArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.angleDegrees != widget.angleDegrees) {
      _unwrappedDegrees += _shortestDelta(oldWidget.angleDegrees, widget.angleDegrees);
    }
  }

  /// Shortest signed angular delta (-180..180] to get from [from] to [to].
  static double _shortestDelta(double from, double to) {
    var delta = (to - from) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return delta;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: _unwrappedDegrees / 360,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _ArrowPainter(color: widget.color),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;

  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius - 4, ringPaint);

    final arrowPaint = Paint()..color = color;
    final path = Path()
      ..moveTo(center.dx, center.dy - radius + 16)
      ..lineTo(center.dx - radius * 0.28, center.dy + radius * 0.35)
      ..lineTo(center.dx, center.dy + radius * 0.15)
      ..lineTo(center.dx + radius * 0.28, center.dy + radius * 0.35)
      ..close();
    canvas.drawPath(path, arrowPaint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(center, 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => oldDelegate.color != color;
}
