import 'dart:math' as math;
import 'package:flutter/material.dart';

class MacroRing extends StatelessWidget {
  final double consumedKcal;
  final int targetKcal;

  final double consumedProtein;
  final int targetProtein;
  final double consumedCarbs;
  final int targetCarbs;
  final double consumedFat;
  final int targetFat;

  const MacroRing({
    super.key,
    required this.consumedKcal,
    required this.targetKcal,
    required this.consumedProtein,
    required this.targetProtein,
    required this.consumedCarbs,
    required this.targetCarbs,
    required this.consumedFat,
    required this.targetFat,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remaining = (targetKcal - consumedKcal);

    return Column(
      children: [
        // ── The calorie ring ──
        SizedBox(
          width: 220,
          height: 220,
          child: CustomPaint(
            painter: _RingPainter(
              progress: targetKcal > 0 ? consumedKcal / targetKcal : 0,
              ringColor: scheme.primary,
              overColor: Colors.amber.shade700,
              trackColor: scheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    consumedKcal.round().toString(),
                    style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
                  ),
                  Text('of $targetKcal kcal',
                      style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(
                    remaining >= 0 ? '${remaining.round()} left' : '${(-remaining).round()} over',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: remaining >= 0 ? scheme.primary : Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // ── The three macro bars ──
        _MacroBar(label: 'Protein', consumed: consumedProtein, target: targetProtein, color: Colors.redAccent),
        const SizedBox(height: 12),
        _MacroBar(label: 'Carbs', consumed: consumedCarbs, target: targetCarbs, color: Colors.blueAccent),
        const SizedBox(height: 12),
        _MacroBar(label: 'Fat', consumed: consumedFat, target: targetFat, color: Colors.orangeAccent),
      ],
    );
  }
}

// Draws the circular calorie progress ring.
class _RingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0+ (can exceed 1 if over target)
  final Color ringColor;
  final Color overColor;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.overColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 18.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // background track (full circle)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // start at top (12 o'clock = -90 degrees = -pi/2)
    const startAngle = -math.pi / 2;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final sweep = 2 * math.pi * clampedProgress;

    final progressPaint = Paint()
      ..color = progress > 1.0 ? overColor : ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}

// A single labeled macro progress bar.
class _MacroBar extends StatelessWidget {
  final String label;
  final double consumed;
  final int target;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final over = consumed > target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${consumed.round()} / $target g',
                style: TextStyle(
                  color: over ? Colors.amber.shade800 : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: over ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(over ? Colors.amber.shade700 : color),
          ),
        ),
      ],
    );
  }
}