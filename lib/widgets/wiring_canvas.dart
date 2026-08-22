import 'package:flutter/material.dart';

import '../models/wired_model.dart';
import 'wiring_palette.dart';

/// Pan/zoomable wiring diagram: a polyline connecting nodes in wiring order
/// underneath color-by-strand dots, so the physical wiring sequence (node 1,
/// 2, 3, ...) is directly traceable. [showLabels] is owned by the caller
/// (the AppBar toggle on the wiring view page), not this widget, so there is
/// one source of truth for that state.
class WiringCanvas extends StatelessWidget {
  final WiredModel model;
  final bool showLabels;

  const WiringCanvas({super.key, required this.model, required this.showLabels});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.2,
      maxScale: 8.0,
      boundaryMargin: const EdgeInsets.all(200),
      child: SizedBox(
        width: 2000,
        height: 2000,
        child: CustomPaint(
          painter: WiringPainter(model: model, showLabels: showLabels),
        ),
      ),
    );
  }
}

class WiringPainter extends CustomPainter {
  final WiredModel model;
  final bool showLabels;

  // Above this many nodes, labels are auto-suppressed even if requested —
  // otherwise dense props (100+ pixels) turn into an unreadable smear.
  static const labelThreshold = 150;

  WiringPainter({required this.model, required this.showLabels});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF101014));

    final nodes = model.nodes;
    if (nodes.isEmpty) return;

    const margin = 32.0;
    final availW = size.width - margin * 2;
    final availH = size.height - margin * 2;
    final scaleW = availW / model.width;
    final scaleH = availH / model.height;
    final scale = scaleW < scaleH ? scaleW : scaleH;
    if (scale.isNaN || scale.isInfinite || scale <= 0) return;

    final drawnW = model.width * scale;
    final drawnH = model.height * scale;
    final originX = (size.width - drawnW) / 2;
    final originY = (size.height - drawnH) / 2;

    Offset screen(WiredNode n) => Offset(
          originX + (n.x - model.minX) * scale,
          originY + (n.y - model.minY) * scale,
        );

    // Wiring path first, underneath the dots.
    final path = Path();
    for (var i = 0; i < nodes.length; i++) {
      final p = screen(nodes[i]);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withAlpha(90),
    );

    const dotRadius = 4.0;
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (final n in nodes) {
      dotPaint.color = colorForStrand(n.strandIndex);
      canvas.drawCircle(screen(n), dotRadius, dotPaint);
    }

    // Mark node 1 distinctly so the wiring start/direction is visible even
    // with labels off.
    canvas.drawCircle(
      screen(nodes.first),
      dotRadius + 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );

    if (showLabels && nodes.length <= labelThreshold) {
      for (final n in nodes) {
        final p = screen(n);
        final tp = TextPainter(
          text: TextSpan(
            text: '${n.node}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, p + Offset(dotRadius + 2, -tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant WiringPainter old) =>
      old.model != model || old.showLabels != showLabels;
}
