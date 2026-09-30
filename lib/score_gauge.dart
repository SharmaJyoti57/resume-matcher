import 'package:flutter/material.dart';
import 'theme.dart';

class ScoreGauge extends StatelessWidget {
  final int score;
  const ScoreGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppTheme.scoreColor(score, scheme);

    return TweenAnimationBuilder<double>(
      // Keying by score (done by the caller) makes this replay on every new result.
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(112, 112),
                painter: _GaugePainter(
                  progress: value / 100,
                  trackColor: scheme.surfaceContainerHighest,
                  progressColor: color,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value.round()}',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color),
                  ),
                  Text(
                    'MATCH SCORE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress; // 0.0–1.0
  final Color trackColor;
  final Color progressColor;

  _GaugePainter({required this.progress, required this.trackColor, required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final fg = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.14159265 / 2; // 12 o'clock
    final sweep = 2 * 3.14159265 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.progressColor != progressColor;
}
