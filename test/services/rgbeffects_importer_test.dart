import 'package:flutter_test/flutter_test.dart';
import 'package:xlights_wiring_viewer/services/rgbeffects_importer.dart';

// Trimmed but structurally real xlights_rgbeffects.xml: <xrgb> wrapping
// <models type="rgb_effects"> full of <model> elements alongside many other
// unrelated sections that a real show layout also contains.
const _sampleXml = '''
<xrgb>
  <models type="rgb_effects">
    <model name="Arch1" DisplayAs="Arches" NumArches="1" NodesPerArch="10" LightsPerNode="1" Arc="180">
      <ControllerConnection Port="1" Protocol="ws2811" Brightness="50"/>
    </model>
    <model name="MyGroup" DisplayAs="ModelGroup">
      <modelGroup>Arch1,Arch2</modelGroup>
    </model>
    <model name="Grid" DisplayAs="Gridlines" />
    <model name="Poop" DisplayAs="Custom" CustomWidth="2" CustomHeight="2"
           CustomModelCompressed="1,0,0;2,0,1;3,1,0;4,1,1" />
  </models>
  <colorPalettes></colorPalettes>
</xrgb>
''';

void main() {
  test('lists real wireable models and filters ModelGroup/Gridlines', () {
    final entries = parseRgbEffectsModelList(_sampleXml);
    expect(entries.map((e) => e.name).toList(), ['Arch1', 'Poop']);
  });

  test('each entry builds a WiredModel on demand', () {
    final entries = parseRgbEffectsModelList(_sampleXml);
    final arch = entries.firstWhere((e) => e.name == 'Arch1').build();
    expect(arch.displayAs, 'Arches');
    expect(arch.nodes.length, 10);

    final custom = entries.firstWhere((e) => e.name == 'Poop').build();
    expect(custom.displayAs, 'Custom');
    expect(custom.nodes.length, 4);
  });
}
