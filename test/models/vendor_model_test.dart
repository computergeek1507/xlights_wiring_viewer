import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xmodel_wiring_viewer/models/vendor_model.dart';

void main() {
  test('parses multiple <wiring> options with their labels', () {
    const xml = '''
<model>
  <id>371</id>
  <name>Medium NSR Tree</name>
  <wiring>
    <xmodellink>https://efl-designs.com/wp-content/uploads/filr/371/Med NSR Tree (1).xmodel</xmodellink>
    <name>Medium NSR Tree</name>
  </wiring>
  <wiring>
    <xmodellink>https://efl-designs.com/wp-content/uploads/filr/7250/Med Tree Star.xmodel</xmodellink>
    <name>with Star (200 pixels)</name>
  </wiring>
</model>
''';
    final element = XmlDocument.parse(xml).rootElement;
    final model = VendorModel.fromXml(element)!;

    expect(model.wirings.length, 2);
    expect(model.wirings[0].name, 'Medium NSR Tree');
    expect(model.wirings[0].url, contains('Med NSR Tree (1).xmodel'));
    expect(model.wirings[1].name, 'with Star (200 pixels)');
    expect(model.wirings[1].url, contains('Med Tree Star.xmodel'));
  });

  test('a single <wiring> with no <name> still parses (name is nullable)', () {
    const xml = '''
<model>
  <id>1</id>
  <name>3 Ring Arch</name>
  <wiring>
    <xmodellink>http://example.com/foo.xmodel</xmodellink>
  </wiring>
</model>
''';
    final element = XmlDocument.parse(xml).rootElement;
    final model = VendorModel.fromXml(element)!;

    expect(model.wirings.length, 1);
    expect(model.wirings[0].name, isNull);
    expect(model.wirings[0].url, 'http://example.com/foo.xmodel');
  });

  test('a model with no <wiring> at all parses with an empty list', () {
    const xml = '<model><id>2</id><name>No Wiring</name></model>';
    final element = XmlDocument.parse(xml).rootElement;
    final model = VendorModel.fromXml(element)!;
    expect(model.wirings, isEmpty);
  });
}
