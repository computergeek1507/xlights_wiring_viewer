import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../../models/wired_model.dart';
import 'geometry_attrs.dart';

/// Builds a [WiredModel] for `DisplayAs="Circle"`. Mirrors xLights'
/// CircleModel's single-ring (dominant) case; multi-ring circles (via
/// `LayerSizes`) are not implemented — all pixels are placed on one ring.
WiredModel buildCircle(XmlElement root) {
  final numStrings = math.max(1, attrInt(root, 'NumStrings', parmFallback: 'parm1', fallback: 1));
  final nodesPerString =
      math.max(1, attrInt(root, 'NodesPerString', parmFallback: 'parm2', fallback: 1));
  final numLights = numStrings * nodesPerString;

  final isBotToTop = attrString(root, 'StartSide', fallback: 'B').toUpperCase() != 'T';
  final isLtoR = attrString(root, 'Dir', fallback: 'L').toUpperCase() != 'R';

  final radius = numLights / 2;
  final nodes = <WiredNode>[];
  for (var n = 0; n < numLights; n++) {
    final frac = n / numLights;
    var angle = (isBotToTop ? -math.pi : 0) + 2 * math.pi * frac;
    if (!isLtoR) angle = -angle;
    nodes.add(WiredNode(
      node: n + 1,
      x: radius * math.sin(angle),
      // Negated: xLights' angle convention is y-up (angle 0 = "top" sits at
      // +y), but this canvas draws y-down, so left unflipped "Bottom" would
      // render at the top of the screen — same class of bug fixed in Tree
      // and Star.
      y: -radius * math.cos(angle),
    ));
  }

  return WiredModel.fromNodes(
    name: attrString(root, 'name', fallback: 'Circle'),
    displayAs: 'Circle',
    nodes: nodes,
  );
}
