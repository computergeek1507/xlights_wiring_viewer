import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:xlights_wiring_viewer/models/wired_model.dart';
import 'package:xlights_wiring_viewer/services/xmodel_importer.dart';

void main() {
  group('Custom Model', () {
    test('round-trips a hand-authored 2x2 grid', () {
      const xml = '<custommodel name="TestGrid" CustomWidth="2" CustomHeight="2" '
          'CustomModelCompressed="1,0,0;2,0,1;3,1,0;4,1,1" DisplayAs="Custom" />';
      final model = importXModel(xml);

      expect(model.displayAs, 'Custom');
      expect(model.nodes.length, 4);
      expect(model.nodes.map((n) => n.node).toSet(), {1, 2, 3, 4});

      final byNode = {for (final n in model.nodes) n.node: n};
      expect(byNode[1]!.x, 0);
      expect(byNode[1]!.y, 0);
      expect(byNode[2]!.x, 1);
      expect(byNode[2]!.y, 0);
      expect(byNode[3]!.x, 0);
      expect(byNode[3]!.y, 1);
      expect(byNode[4]!.x, 1);
      expect(byNode[4]!.y, 1);
    });

    test('falls back to the legacy CustomModel grid', () {
      const xml = '<custommodel name="Legacy" CustomModel="1,2;,3" DisplayAs="Custom" />';
      final model = importXModel(xml);
      expect(model.nodes.length, 3);
      expect(model.nodes.map((n) => n.node).toSet(), {1, 2, 3});
    });

    test('unwraps xLights "Export Models" <models><model DisplayAs="Custom"> format', () {
      // xLights' own File > Export Models feature wraps the model in a
      // <models type="exported"> root with a generic <model> tag (DisplayAs
      // does the work), unlike vendor-distributed files which use a
      // <custommodel> root directly. Regression case: a real personal-library
      // export ("Poop Emoji.xmodel") failed to load before this was handled.
      const xml = '<models type="exported">'
          '<model name="Wrapped" DisplayAs="Custom" CustomWidth="2" CustomHeight="2" '
          'CustomModelCompressed="1,0,0;2,0,1;3,1,0;4,1,1" />'
          '</models>';
      final model = importXModel(xml);
      expect(model.displayAs, 'Custom');
      expect(model.nodes.length, 4);
      expect(model.nodes.map((n) => n.node).toSet(), {1, 2, 3, 4});
    });

    test('unwraps the export format for native shapes too', () {
      const xml = '<models type="exported">'
          '<model name="WrappedMatrix" DisplayAs="Matrix" '
          'NumStrings="1" NodesPerString="10" StrandsPerString="2" />'
          '</models>';
      final model = importXModel(xml);
      expect(model.displayAs, 'Matrix');
      expect(model.nodes.length, 10);
    });
  });

  test('DMX fixture models are rejected with a clear message', () {
    const xml = '<dmxmodel name="Fixture" />';
    expect(
      () => importXModel(xml),
      throwsA(isA<XModelImportException>().having(
        (e) => e.message,
        'message',
        contains('DMX fixture'),
      )),
    );
  });

  test('unsupported shape types are rejected listing what is supported', () {
    const xml = '<somemodel DisplayAs="Sphere" name="X" />';
    expect(
      () => importXModel(xml),
      throwsA(isA<XModelImportException>().having(
        (e) => e.message,
        'message',
        allOf(contains('Sphere'), contains('Matrix'), contains('Custom')),
      )),
    );
  });

  test('invalid XML is rejected, not thrown as a raw XmlException', () {
    expect(() => importXModel('not xml at all <<<'), throwsA(isA<XModelImportException>()));
  });

  group('Matrix', () {
    test('produces a contiguous node sequence sized NumStrings x NodesPerString', () {
      const xml = '<model DisplayAs="Matrix" name="M1" '
          'NumStrings="1" NodesPerString="10" StrandsPerString="2" />';
      final model = importXModel(xml);
      // PixelsPerStrand = 10/2 = 5, NumStrands = 1*2 = 2 -> 10 nodes.
      expect(model.nodes.length, 10);
      expect(model.nodes.map((n) => n.node).toList(), List.generate(10, (i) => i + 1));
    });

    test('zigzags odd strands so their column order reverses', () {
      const xml = '<model DisplayAs="Matrix" name="M1" '
          'NumStrings="1" NodesPerString="10" StrandsPerString="2" />';
      final model = importXModel(xml);
      // Strand 0 (nodes 1-5): columns ascend 0..4.
      final strand0 = model.nodes.sublist(0, 5).map((n) => n.x).toList();
      expect(strand0, [0, 1, 2, 3, 4]);
      // Strand 1 (nodes 6-10, zigzagged): columns descend 4..0.
      final strand1 = model.nodes.sublist(5, 10).map((n) => n.x).toList();
      expect(strand1, [4, 3, 2, 1, 0]);
    });
  });

  test('Single Line spaces NumStrings x NodesPerString pixels along y=0', () {
    const xml =
        '<model DisplayAs="Single Line" name="L1" NumStrings="1" NodesPerString="5" LightsPerNode="1" />';
    final model = importXModel(xml);
    expect(model.nodes.length, 5);
    expect(model.nodes.every((n) => n.y == 0), isTrue);
    expect(model.nodes.first.x, 0);
    expect(model.nodes.last.x, closeTo(1.0, 1e-9));
  });

  test('Arches produces NumArches x (NodesPerArch x LightsPerNode) nodes', () {
    const xml = '<model DisplayAs="Arches" name="A1" '
        'NumArches="2" NodesPerArch="5" LightsPerNode="1" Arc="180" />';
    final model = importXModel(xml);
    expect(model.nodes.length, 10);
    expect(model.nodes.map((n) => n.node).toSet(), Set.from(List.generate(10, (i) => i + 1)));
  });

  test('Tree (round) produces NumStrings*StrandsPerString x NodesPerString/StrandsPerString nodes', () {
    const xml = '<model DisplayAs="Tree" name="T1" TreeType="0" '
        'NumStrings="4" NodesPerString="10" StrandsPerString="1" />';
    final model = importXModel(xml);
    expect(model.nodes.length, 40);
    expect(model.nodes.map((n) => n.node).toSet(), Set.from(List.generate(40, (i) => i + 1)));
  });

  test('Tree (round) draws the wide base lower on screen than the narrow top', () {
    // Regression: xLights' own tree math is y-up, but the canvas is y-down —
    // porting the formula unflipped drew the wide physical base at the top
    // of the screen and the narrow top at the bottom.
    const xml = '<model DisplayAs="Tree" name="T1" TreeType="0" '
        'NumStrings="1" NodesPerString="10" StrandsPerString="1" TreeBottomTopRatio="6" />';
    final model = importXModel(xml);
    // Node 1 is at buffer row 0 (t=0, the wide physical base); the last
    // node is at the final row (t=1, the narrow top). A larger y means
    // further down the screen in this app's coordinate convention.
    expect(model.nodes.first.y, greaterThan(model.nodes.last.y));
  });

  test('Tree StartSide="T" starts wiring at the top instead of the bottom', () {
    // Regression: StartSide was documented but never actually read for
    // Matrix/Tree — a real vendor file ("Med NSR Tree", StartSide="T")
    // wired node 1 at the bottom when it should start at the top.
    const xml = '<model DisplayAs="Tree" name="T1" TreeType="0" StartSide="T" '
        'NumStrings="1" NodesPerString="10" StrandsPerString="1" TreeBottomTopRatio="6" />';
    final model = importXModel(xml);
    // Reversed from the StartSide="B" (default) case above: node 1 is now
    // at the narrow top (smallest y), the last node at the wide base.
    expect(model.nodes.first.y, lessThan(model.nodes.last.y));
  });

  test('Tree accepts a <treemodel> root with legacy DisplayAs="Tree <degrees>"', () {
    // Regression case: a real vendor file (EFL Designs "Med NSR Tree") uses
    // a <treemodel> root tag with DisplayAs="Tree 120" and no TreeType/
    // TreeDegrees attributes at all — the degree span is only encoded in
    // the DisplayAs string, and the root tag isn't <model>.
    const xml = '<treemodel name="Med NSR Tree" parm1="1" parm2="150" parm3="10" '
        'DisplayAs="Tree 120" StrandDir="Vertical" TreeBottomTopRatio="3.0" />';
    final model = importXModel(xml);
    expect(model.displayAs, 'Tree');
    expect(model.nodes.length, 150);
    expect(model.nodes.map((n) => n.node).toSet(), Set.from(List.generate(150, (i) => i + 1)));
  });

  test('Circle spaces NumStrings x NodesPerString nodes evenly around a ring', () {
    const xml = '<model DisplayAs="Circle" name="C1" NumStrings="1" NodesPerString="12" />';
    final model = importXModel(xml);
    expect(model.nodes.length, 12);
    // All nodes should sit at the same radius (numLights/2 = 6) from origin.
    for (final n in model.nodes) {
      final r = (n.x * n.x + n.y * n.y);
      expect(r, closeTo(36, 1e-6));
    }
  });

  test('Circle StartSide="B" (default) starts at the largest y (bottom of screen)', () {
    // Regression: same y-up-vs-y-down class of bug as Tree/Arches/Star.
    const xml = '<model DisplayAs="Circle" name="C1" NumStrings="1" NodesPerString="12" />';
    final model = importXModel(xml);
    final maxY = model.nodes.map((n) => n.y).reduce((a, b) => a > b ? a : b);
    expect(model.nodes.first.y, closeTo(maxY, 1e-6));
  });

  test('Arches peaks at the smallest y (top of screen), legs at the largest', () {
    // Regression: same y-up-vs-y-down class of bug as Tree/Circle/Star.
    const xml = '<model DisplayAs="Arches" name="A1" '
        'NumArches="1" NodesPerArch="9" LightsPerNode="1" Arc="180" />';
    final model = importXModel(xml);
    final byY = [...model.nodes]..sort((a, b) => a.y.compareTo(b.y));
    // The peak (center of the arc) should be among the smallest-y nodes;
    // the two legs (arc ends) among the largest-y nodes.
    final peak = model.nodes[model.nodes.length ~/ 2];
    expect(peak.y, closeTo(byY.first.y, 1e-6));
    expect(model.nodes.first.y, closeTo(byY.last.y, 1e-6));
    expect(model.nodes.last.y, closeTo(byY.last.y, 1e-6));
  });

  test('Star walks the outline placing NumStrings x NodesPerString nodes', () {
    const xml =
        '<model DisplayAs="Star" name="S1" NumStrings="1" NodesPerString="20" StarPoints="5" />';
    final model = importXModel(xml);
    expect(model.nodes.length, 20);
    expect(model.nodes.map((n) => n.node).toSet(), Set.from(List.generate(20, (i) => i + 1)));
  });

  test('Star with no StarStartLocation (defaults to Top) starts in the upper half', () {
    // Regression: same y-up-vs-y-down class of bug as Tree/Circle/Arches.
    // Node 1 starts at an inner knee vertex near the top, not necessarily
    // the single most-extreme point (an adjacent outer tip can be more
    // extreme), so this checks orientation (sign), not exact extremum.
    const xml =
        '<model DisplayAs="Star" name="S1" NumStrings="1" NodesPerString="20" StarPoints="5" />';
    final model = importXModel(xml);
    expect(model.nodes.first.y, lessThan(0));
  });

  test('Star LayerSizes produces nested layers, inner first (case-insensitive attrs)', () {
    // Regression case: a real vendor file ("Med Tree Star") uses lowercase
    // starRatio/starCenterPercent attribute names, and both lists and wires
    // LayerSizes innermost-first (confirmed against a reference render from
    // xLights itself) — node 1 belongs to the smaller inner layer.
    const xml = '<starmodel name="Med Tree Star" parm1="1" parm2="50" parm3="5" '
        'DisplayAs="Star" LayerSizes="20,30" starRatio="2.42" starCenterPercent="67" '
        'StarStartLocation="Bottom Ctr-CW" />';
    final model = importXModel(xml);
    expect(model.nodes.length, 50);
    // Inner layer (20 nodes) wired first, outer layer (30 nodes) second.
    expect(model.nodes.sublist(0, 20).every((n) => n.strandIndex == 0), isTrue);
    expect(model.nodes.sublist(20, 50).every((n) => n.strandIndex == 1), isTrue);

    double dist(WiredNode n) => n.x * n.x + n.y * n.y;
    final innerTip = model.nodes.sublist(0, 20).reduce((a, b) => dist(a) > dist(b) ? a : b);
    final outerTip = model.nodes.sublist(20, 50).reduce((a, b) => dist(a) > dist(b) ? a : b);
    // Inner layer's farthest point should be ~67% of the outer layer's.
    expect(math.sqrt(dist(innerTip)) / math.sqrt(dist(outerTip)), closeTo(0.67, 0.01));

    // Node 1 starts at an inner "knee" vertex, not an outer point: its
    // distance from center should match the inner layer's own innerRadius
    // (baseOuterRadius * innerScale / starRatio), not its outerRadius.
    final node1Dist = math.sqrt(dist(model.nodes.first));
    final layer0OuterRadius = (50 / 2) * 0.67;
    final layer0InnerRadius = layer0OuterRadius / 2.42;
    expect(node1Dist, closeTo(layer0InnerRadius, 0.01));
  });

  test('Spinner produces ArmsPerString x NodesPerArm nodes, arm-major order', () {
    const xml = '<model DisplayAs="Spinner" name="Sp1" '
        'NumStrings="1" NodesPerArm="5" ArmsPerString="4" />';
    final model = importXModel(xml);
    expect(model.nodes.length, 20);
    // Arm-major: nodes 1-5 all belong to strand (arm) index 0.
    final firstArm = model.nodes.sublist(0, 5);
    expect(firstArm.every((n) => n.strandIndex == 0), isTrue);
  });
}
