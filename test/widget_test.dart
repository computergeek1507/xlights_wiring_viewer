import 'package:flutter_test/flutter_test.dart';

import 'package:xmodel_wiring_viewer/main.dart';

void main() {
  testWidgets('Home page shows the three entry points', (WidgetTester tester) async {
    await tester.pumpWidget(const WiringViewerApp());

    expect(find.text('Browse Vendor Catalog'), findsOneWidget);
    expect(find.text('Load .xmodel from device'), findsOneWidget);
    expect(find.text('Load xlights_rgbeffects.xml'), findsOneWidget);
  });
}
