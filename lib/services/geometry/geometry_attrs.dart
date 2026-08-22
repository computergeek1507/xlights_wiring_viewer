import 'package:xml/xml.dart';

/// Modern xLights model files write named attributes (e.g. `NumStrings`);
/// older files only wrote the generic `parm1`/`parm2`/`parm3`. Every geometry
/// parser reads the named attribute first, falling back to the legacy parm
/// slot, so both file vintages work.
int attrInt(XmlElement e, String name, {String? parmFallback, int fallback = 0}) {
  final v = e.getAttribute(name) ??
      (parmFallback == null ? null : e.getAttribute(parmFallback));
  return int.tryParse(v ?? '') ?? fallback;
}

double attrDouble(XmlElement e, String name, {String? parmFallback, double fallback = 0}) {
  final v = e.getAttribute(name) ??
      (parmFallback == null ? null : e.getAttribute(parmFallback));
  return double.tryParse(v ?? '') ?? fallback;
}

bool attrBool(XmlElement e, String name, {bool fallback = false}) {
  final v = e.getAttribute(name)?.trim().toLowerCase();
  if (v == null || v.isEmpty) return fallback;
  return v == 'true' || v == '1';
}

String attrString(XmlElement e, String name, {String fallback = ''}) {
  final v = e.getAttribute(name);
  return (v == null || v.isEmpty) ? fallback : v;
}
