import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Vendor sites don't send CORS headers, so a browser can't download a
/// .xmodel file directly — only on web. This proxies the request through a
/// small server-side script (see xmodel-proxy.php in the repo) that fetches
/// the file and re-serves it with a CORS header allowing this app's origin.
/// Non-web platforms never hit CORS and always fetch the vendor URL directly.
const _proxyBaseUrl = 'https://wiring.scottnation.com/xmodel-proxy.php';

/// Downloads a vendor's `.xmodel` file. Transient — the view flow doesn't
/// need to persist it to disk, it's parsed straight into a [WiredModel].
class XmodelDownloadService {
  static const _timeout = Duration(seconds: 15);

  Future<String> downloadXmodel(String url) async {
    final fetchUrl = kIsWeb
        ? Uri.parse(_proxyBaseUrl).replace(queryParameters: {'url': url})
        : Uri.parse(url);

    final http.Response response;
    try {
      response = await http.get(fetchUrl).timeout(_timeout);
    } catch (e) {
      throw Exception('Could not download this model: $e');
    }
    if (response.statusCode != 200) {
      throw Exception('Server returned HTTP ${response.statusCode} for this model.');
    }
    return response.body;
  }
}
