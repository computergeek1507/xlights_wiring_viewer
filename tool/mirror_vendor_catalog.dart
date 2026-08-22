// ignore_for_file: avoid_print
// Mirrors the xLights vendor catalog (xlights_vendors.xml) and every
// vendor's own model-inventory XML into web/data/, so the web build can
// browse vendor model lists without hitting CORS — vendor sites don't send
// CORS headers, so a browser can't fetch them directly, but GitHub Pages
// serving our own mirrored copy is same-origin and always works.
//
// Run manually with: dart run tool/mirror_vendor_catalog.dart
// Run automatically by .github/workflows/mirror-vendors.yml (daily cron).
//
// Scope: mirrors catalog/metadata XML only (vendor list + each vendor's
// model inventory), not the .xmodel files themselves or thumbnail images.
// Thumbnails already load fine cross-origin (plain <img> tags aren't
// CORS-gated); downloading a specific .xmodel via "View Wiring" still goes
// straight to the vendor's site and will still hit CORS on web until/unless
// that's mirrored too — out of scope here due to the storage/vendor-load
// cost of mirroring potentially thousands of files across all vendors.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:xlights_wiring_viewer/models/vendor.dart';
import 'package:xml/xml.dart';

const _vendorsUrl =
    'https://raw.githubusercontent.com/xLightsSequencer/xLights/master/download/xlights_vendors.xml';
const _outDir = 'web/data';
const _timeout = Duration(seconds: 20);

String _slugify(String name) {
  final lower = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return lower.replaceAll(RegExp(r'^-+|-+$'), '');
}

Future<void> main() async {
  final vendorsResponse = await http.get(Uri.parse(_vendorsUrl)).timeout(_timeout);
  if (vendorsResponse.statusCode != 200) {
    stderr.writeln('Failed to fetch $_vendorsUrl: HTTP ${vendorsResponse.statusCode}');
    exitCode = 1;
    return;
  }

  final vendors = <Vendor>[];
  for (final e in XmlDocument.parse(vendorsResponse.body).findAllElements('vendor')) {
    final v = Vendor.fromXml(e);
    if (v != null && !isDmxVendor(v.name)) vendors.add(v);
  }
  print('Found ${vendors.length} vendors (DMX vendors excluded).');

  final vendorDir = Directory('$_outDir/vendor');
  await vendorDir.create(recursive: true);
  await File('$_outDir/vendors.xml').writeAsString(vendorsResponse.body);

  final manifest = <String, String>{};
  final usedSlugs = <String>{};

  for (final vendor in vendors) {
    var slug = _slugify(vendor.name);
    if (slug.isEmpty) slug = 'vendor';
    while (usedSlugs.contains(slug)) {
      slug = '$slug-2';
    }
    usedSlugs.add(slug);

    stdout.write('Fetching ${vendor.name} (${vendor.inventoryUrl}) ... ');
    try {
      final response = await http.get(Uri.parse(vendor.inventoryUrl)).timeout(_timeout);
      if (response.statusCode != 200) {
        print('HTTP ${response.statusCode}, skipped.');
        continue;
      }
      // Sanity check: must at least parse as XML before we mirror it.
      XmlDocument.parse(response.body);
      await File('$_outDir/vendor/$slug.xml').writeAsString(response.body);
      // Site-relative (from the deployed web root, not from $_outDir), so
      // the app can resolve it directly against Uri.base without needing
      // to know $_outDir's own name.
      manifest[vendor.inventoryUrl] = 'data/vendor/$slug.xml';
      print('OK (${response.body.length} bytes).');
    } catch (e) {
      print('failed: $e');
    }
  }

  final manifestJson = jsonEncode({
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'vendors': manifest,
  });
  await File('$_outDir/manifest.json').writeAsString(manifestJson);
  print('Mirrored ${manifest.length}/${vendors.length} vendor catalogs.');
}
