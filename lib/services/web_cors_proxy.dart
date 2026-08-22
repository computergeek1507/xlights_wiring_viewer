import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;

/// Vendor sites don't send CORS headers, so a browser can't fetch a vendor's
/// model inventory or a .xmodel file directly — only on web. This proxies
/// the request through a small server-side script (xmodel-proxy.php,
/// deployed by the app's operator on their own host) that fetches the URL
/// server-side and re-serves it with a CORS header. Non-web platforms never
/// hit CORS and always fetch the vendor URL directly.
const proxyBaseUrl = 'https://wiring.scottnation.com/xmodel-proxy.php';

/// Returns the URL to actually fetch for [target]: proxied through
/// [proxyBaseUrl] on web, unchanged everywhere else. The target is
/// base64url-encoded rather than passed as a literal `?u=http://...` query
/// value — shared-hosting WAFs (ModSecurity and similar, common on cPanel)
/// routinely block any request whose query string contains a literal URL as
/// a blanket anti-SSRF rule.
Uri maybeProxied(String target) {
  if (!kIsWeb) return Uri.parse(target);
  return Uri.parse(proxyBaseUrl).replace(queryParameters: {
    'u': base64UrlEncode(utf8.encode(target)),
  });
}
