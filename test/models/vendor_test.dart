import 'package:flutter_test/flutter_test.dart';
import 'package:xlights_wiring_viewer/models/vendor.dart';

void main() {
  test('isDmxVendor matches DMX vendor names case-insensitively', () {
    expect(isDmxVendor('DMX Fixture Library'), isTrue);
    expect(isDmxVendor('DMX Model Library'), isTrue);
    expect(isDmxVendor('dmx fixture library'), isTrue);
    expect(isDmxVendor('Boscoyo Studio, LLC'), isFalse);
    expect(isDmxVendor('EFL'), isFalse);
  });
}
