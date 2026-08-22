import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../../models/wired_model.dart';
import 'geometry_attrs.dart';
import 'matrix_buffer.dart';

/// Builds a [WiredModel] for `DisplayAs="Tree"` (and legacy `"Tree 360"`/
/// `"Tree Flat"`/`"Tree Ribbon"`). Tree reuses Matrix's buffer layout (see
/// [buildMatrixBuffer]) — strand index becomes the buffer's x axis, position
/// along the strand becomes its y axis — then projects that buffer onto a
/// shape selected by `TreeType` (0=Round/spiral cone [default], 1=Flat,
/// 2=Ribbon). Round mode is inherently 3D; z is dropped for a 2D front
/// elevation, which is enough to show wiring order.
WiredModel buildTree(XmlElement root) {
  final treeType = attrInt(root, 'TreeType', fallback: 0);
  final numStrings = math.max(1, attrInt(root, 'NumStrings', parmFallback: 'parm1', fallback: 1));
  final nodesPerString = math.max(1, attrInt(root, 'NodesPerString', parmFallback: 'parm2', fallback: 1));
  final strandsPerString =
      math.max(1, attrInt(root, 'StrandsPerString', parmFallback: 'parm3', fallback: 1));
  final vertical = attrString(root, 'StrandDir', fallback: 'Vertical').toLowerCase() != 'horizontal';
  final zigzag = !attrBool(root, 'NoZigZag');
  final alternateNodes = attrBool(root, 'AlternateNodes');

  final buffer = buildMatrixBuffer(
    numStrings: numStrings,
    nodesPerString: nodesPerString,
    strandsPerString: strandsPerString,
    vertical: vertical,
    zigzag: zigzag,
    alternateNodes: alternateNodes,
  );

  final bufferWi = buffer.fold(0, (m, p) => math.max(m, p.col)) + 1;
  final bufferHt = buffer.fold(0, (m, p) => math.max(m, p.row)) + 1;

  final nodes = <WiredNode>[];
  if (treeType == 0) {
    final treeDegrees = attrDouble(root, 'TreeDegrees', fallback: 360);
    final treeRotationDeg = attrDouble(root, 'TreeRotation', fallback: 3.0);
    final bottomTopRatio = attrDouble(root, 'TreeBottomTopRatio', fallback: 6.0);
    final spiralRotations = attrDouble(root, 'TreeSpiralRotations', fallback: 0);

    final renderHt = bufferHt * 3.0;
    final renderWi = renderHt / 1.8;
    final radius = renderWi / 2;
    final ratio = bottomTopRatio.abs() < 0.0001 ? 1.0 : bottomTopRatio.abs();
    final topRadius = radius / ratio;

    final radians = treeDegrees * math.pi / 180.0;
    final startAngle = -radians / 2 + treeRotationDeg * math.pi / 180.0;
    final angleIncr = (bufferWi > 1 && treeDegrees < 350)
        ? radians / (bufferWi - 1)
        : radians / bufferWi;

    for (final p in buffer) {
      final t = bufferHt > 1 ? p.row / (bufferHt - 1) : 0.0;
      final angle = startAngle + p.col * angleIncr + spiralRotations * 2 * math.pi * t;
      final xBottom = radius * math.sin(angle);
      final xTop = topRadius * math.sin(angle);
      final x = xBottom + (xTop - xBottom) * t;
      final y = renderHt * t - renderHt / 2;
      nodes.add(WiredNode(
        node: nodes.length + 1,
        x: x,
        y: y,
        strand: 'Strand ${p.strandIndex + 1}',
        strandIndex: p.strandIndex,
      ));
    }
  } else {
    // Flat (1) / Ribbon (2) — Ribbon treated as Flat with a wider base scale.
    final treeScale = treeType == 2 ? 5.0 : 4.0;
    final renderHt = bufferHt * 2.0;
    for (final p in buffer) {
      final t = bufferHt > 1 ? p.row / (bufferHt - 1) : 0.0;
      final xTop = (p.col + 0.5 - bufferWi / 2) * 0.9;
      final xBottom = (p.col + 0.5 - bufferWi / 2) * treeScale;
      final x = xBottom + (xTop - xBottom) * t;
      final y = renderHt * t - renderHt / 2;
      nodes.add(WiredNode(
        node: nodes.length + 1,
        x: x,
        y: y,
        strand: 'Strand ${p.strandIndex + 1}',
        strandIndex: p.strandIndex,
      ));
    }
  }

  return WiredModel.fromNodes(
    name: attrString(root, 'name', fallback: 'Tree'),
    displayAs: 'Tree',
    nodes: nodes,
  );
}
