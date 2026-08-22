import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../../models/wired_model.dart';
import 'geometry_attrs.dart';

/// Builds a [WiredModel] for `DisplayAs="Arches"`. Mirrors xLights'
/// ArchesModel's dominant (non-layered/non-concentric) mode — the rarer
/// `LayerSizes` concentric-arch configuration is not implemented.
///
/// Note `LightsPerNode` (legacy `parm3`) is NOT the arc's angular span; that's
/// the separate `Arc` attribute (default 180°).
WiredModel buildArches(XmlElement root) {
  final numArches = attrInt(root, 'NumArches', parmFallback: 'parm1', fallback: 1);
  final nodesPerArch = attrInt(root, 'NodesPerArch', parmFallback: 'parm2', fallback: 1);
  final lightsPerNode = attrInt(root, 'LightsPerNode', parmFallback: 'parm3', fallback: 1);
  final arcDegrees = attrDouble(root, 'Arc', fallback: 180);
  final gap = attrDouble(root, 'Gap', fallback: 0);
  final reversed = attrString(root, 'Dir', fallback: 'L').toUpperCase() == 'R';

  final int perArch = math.max(1, nodesPerArch);
  final int perNode = math.max(1, lightsPerNode);
  final int n = perArch * perNode;
  final archRad = arcDegrees * math.pi / 180.0;
  final int archesCount = math.max(1, numArches);

  final nodes = <WiredNode>[];
  var xOffset = 0.0;
  var nodeCounter = 1;
  final archOrder = List.generate(archesCount, (i) => i);
  for (final archIdx in (reversed ? archOrder.reversed.toList() : archOrder)) {
    var points = _archPoints(n, archRad);
    if (reversed) points = points.reversed.toList();
    final xs = points.map((p) => p.x);
    final localMinX = xs.reduce(math.min);
    final archWidth = xs.reduce(math.max) - localMinX;

    for (final p in points) {
      nodes.add(WiredNode(
        node: nodeCounter++,
        x: xOffset + (p.x - localMinX),
        y: p.y,
        strand: 'Arch ${archIdx + 1}',
        strandIndex: archIdx,
      ));
    }
    xOffset += archWidth + gap;
  }

  return WiredModel.fromNodes(
    name: attrString(root, 'name', fallback: 'Arches'),
    displayAs: 'Arches',
    nodes: nodes,
  );
}

/// One arch's local points (before arch-to-arch x offset), y shifted so its
/// minimum is 0. `angle(p) = -Arc/2 + Arc*p/(n-1)`, `x=(n-1)*sin(angle)`,
/// `y=n*cos(angle)` (uses n, not n-1 — gives a slightly peaked arch, matching
/// xLights' own formula rather than a true semicircle).
List<({double x, double y})> _archPoints(int n, double archRad) {
  if (n <= 1) return const [(x: 0.0, y: 0.0)];
  final points = <({double x, double y})>[];
  for (var p = 0; p < n; p++) {
    final angle = -archRad / 2 + archRad * p / (n - 1);
    points.add((x: (n - 1) * math.sin(angle), y: n * math.cos(angle)));
  }
  final minY = points.map((e) => e.y).reduce(math.min);
  return [for (final p in points) (x: p.x, y: p.y - minY)];
}
