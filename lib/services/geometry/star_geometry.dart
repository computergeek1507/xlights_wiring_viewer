import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../../models/wired_model.dart';
import 'geometry_attrs.dart';

/// Builds a [WiredModel] for `DisplayAs="Star"`. Mirrors xLights' StarModel's
/// single-layer (dominant) case: trace the `2*StarPoints`-gon outline
/// (alternating outer/inner radius vertices) and place pixels at constant
/// arc-length spacing along that closed path. Multi-layer (nested) stars via
/// `LayerSizes` are not implemented.
WiredModel buildStar(XmlElement root) {
  final numStrings = math.max(1, attrInt(root, 'NumStrings', parmFallback: 'parm1', fallback: 1));
  final nodesPerString =
      math.max(1, attrInt(root, 'NodesPerString', parmFallback: 'parm2', fallback: 1));
  final starPoints = math.max(3, attrInt(root, 'StarPoints', parmFallback: 'parm3', fallback: 5));
  final starRatioRaw = attrDouble(root, 'StarRatio', fallback: 2.618034);
  final starRatio = starRatioRaw.abs() < 0.0001 ? 1.0 : starRatioRaw.abs();
  final startLocation = attrString(root, 'StarStartLocation', fallback: 'Top-CW').toLowerCase();

  final pixelCount = numStrings * nodesPerString;
  final outerRadius = pixelCount / 2;
  final innerRadius = outerRadius / starRatio;
  final pointAngleGap = 2 * math.pi / starPoints;

  double startAngle;
  if (startLocation.contains('bottom')) {
    startAngle = math.pi;
  } else if (startLocation.contains('left')) {
    startAngle = -math.pi / 2;
  } else if (startLocation.contains('right')) {
    startAngle = math.pi / 2;
  } else {
    startAngle = 0; // Top
  }
  final directionUnit = startLocation.contains('ccw') ? -1.0 : 1.0;

  final segments = starPoints * 2;
  final vertices = <({double x, double y})>[];
  var curAngle = startAngle;
  for (var i = 0; i < segments; i++) {
    final r = i.isEven ? outerRadius : innerRadius;
    vertices.add((x: r * math.sin(curAngle), y: r * math.cos(curAngle)));
    curAngle += directionUnit * pointAngleGap / 2;
  }

  final segLengths = <double>[];
  final prefix = <double>[0];
  for (var i = 0; i < segments; i++) {
    final a = vertices[i];
    final b = vertices[(i + 1) % segments];
    final len = math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2));
    segLengths.add(len);
    prefix.add(prefix.last + len);
  }
  final totalPerimeter = prefix.last;

  final nodes = <WiredNode>[];
  if (totalPerimeter > 0 && pixelCount > 0) {
    final step = totalPerimeter / pixelCount;
    for (var n = 0; n < pixelCount; n++) {
      final targetDist = n * step;
      var segIdx = segments - 1;
      for (var i = 0; i < segments; i++) {
        if (targetDist < prefix[i + 1] || i == segments - 1) {
          segIdx = i;
          break;
        }
      }
      final segLen = segLengths[segIdx];
      final t = segLen <= 0 ? 0.0 : (targetDist - prefix[segIdx]) / segLen;
      final a = vertices[segIdx];
      final b = vertices[(segIdx + 1) % segments];
      nodes.add(WiredNode(
        node: n + 1,
        x: a.x + (b.x - a.x) * t,
        y: a.y + (b.y - a.y) * t,
      ));
    }
  }

  return WiredModel.fromNodes(
    name: attrString(root, 'name', fallback: 'Star'),
    displayAs: 'Star',
    nodes: nodes,
  );
}
