import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/wired_model.dart';
import 'wiring_palette.dart';

// Every 50th node after the first (51, 101, 151, ...) marks the start of a
// new physical run — most pixel controllers/ports cap out around 50 pixels,
// so this is a useful "new port starts here" landmark while wiring by hand.
const _portRunLength = 50;
const _portMarkerColor = Color(0xFFFFC107);

bool _isPortBoundary(int node) => node > 1 && (node - 1) % _portRunLength == 0;

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
      dotPaint.color = _isPortBoundary(n.node) ? _portMarkerColor : colorForStrand(n.strandIndex);
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

    // Mark the last node (end of the wiring chain) with an octagon.
    final endOctagon = _octagonPath(screen(nodes.last), dotRadius + 7);
    canvas.drawPath(endOctagon, Paint()..style = PaintingStyle.fill..color = _portMarkerColor);
    canvas.drawPath(
      endOctagon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.black54,
    );

    if (showLabels) {
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

  /// A regular octagon (flat edge on top, like a stop sign) centered at
  /// [center] with the given [radius].
  Path _octagonPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + math.pi / 8 + i * (math.pi / 4);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant WiringPainter old) =>
      old.model != model || old.showLabels != showLabels;
}
