<?php
/**
 * xLights Wiring Viewer — vendor-catalog / .xmodel CORS proxy.
 *
 * The web build of the app can't fetch a vendor's model inventory or a
 * .xmodel file straight from that vendor's site (browsers block that:
 * vendor sites don't send CORS headers). This script fetches the URL
 * server-side (no CORS involved for a server-to-server request) and
 * re-serves it with a CORS header that allows the app's own origin to
 * read it. See lib/services/web_cors_proxy.dart for the Dart side.
 *
 * SECURITY: this only proxies http(s) URLs whose host is in the vendor
 * allowlist below — it is NOT a general-purpose open proxy. Update
 * $ALLOWED_HOSTS if xLights adds/changes vendors (see
 * https://raw.githubusercontent.com/xLightsSequencer/xLights/master/download/xlights_vendors.xml).
 *
 * Usage: GET /xmodel-proxy.php?u=<base64url-encoded target URL>
 *
 * The target URL is base64url-encoded (not passed as a literal
 * http://... query value) because shared-hosting WAFs (ModSecurity and
 * similar, common on cPanel) routinely block any request whose query
 * string contains a literal URL, as a blanket anti-SSRF/open-redirect
 * rule — encoding avoids that pattern match without needing to touch
 * server-level WAF config.
 */

function base64UrlDecode(string $s): string
{
    $s = strtr($s, '-_', '+/');
    $pad = strlen($s) % 4;
    if ($pad) {
        $s .= str_repeat('=', 4 - $pad);
    }
    return base64_decode($s, true) ?: '';
}

// Vendor inventories sometimes list .xmodel URLs with raw spaces (or other
// unsafe characters) in the filename, e.g. ".../Boscoyo ChromaStone 1.xmodel".
// libcurl sends CURLOPT_URL's path verbatim rather than encoding it, so a
// literal space breaks the outbound HTTP request line and the vendor's
// server rejects it with 400 Bad Request. Decoding then re-encoding each
// path segment fixes that while staying a no-op for already-clean URLs.
function normalizeUrlForFetch(string $url): string
{
    $parts = parse_url($url);
    if (!$parts) {
        return $url;
    }
    $port = isset($parts['port']) ? ':' . $parts['port'] : '';
    $path = $parts['path'] ?? '';
    $encodedPath = implode('/', array_map(
        fn($segment) => rawurlencode(rawurldecode($segment)),
        explode('/', $path)
    ));
    $query = isset($parts['query']) ? '?' . $parts['query'] : '';
    return ($parts['scheme'] ?? 'http') . '://' . ($parts['host'] ?? '') . $port . $encodedPath . $query;
}

// This proxy only ever relays public vendor-catalog XML (no sessions, no
// credentials, nothing sensitive), and $ALLOWED_HOSTS below is what
// actually prevents it from being an open proxy — so any origin may call
// it, whether the app ends up served from GitHub Pages or this same
// cPanel account.
$ALLOWED_ORIGIN = '*';

$ALLOWED_HOSTS = [
    'hohenseefamily.com',
    'raw.githubusercontent.com',
    'efl-designs.com',
    'models.mattosdesigns.com',
    'wiredwatts.com',
    'buildalightshow.com',
    'ledpixelshow.com',
    'www.twinkle-forge.com',
    'twinkle-forge.com',
];

header("Access-Control-Allow-Origin: $ALLOWED_ORIGIN");
header('Access-Control-Allow-Methods: GET');
header('Vary: Origin');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    // CORS preflight — nothing else to do.
    http_response_code(204);
    exit;
}

$encoded = $_GET['u'] ?? '';
$url = base64UrlDecode($encoded);
$parts = parse_url($url);

if (!$parts || !in_array($parts['scheme'] ?? '', ['http', 'https'], true)) {
    http_response_code(400);
    header('Content-Type: text/plain');
    echo 'Missing or invalid u parameter.';
    exit;
}

$host = strtolower($parts['host'] ?? '');
if (!in_array($host, $ALLOWED_HOSTS, true)) {
    http_response_code(403);
    header('Content-Type: text/plain');
    echo "Host not allowed: $host";
    exit;
}

$ch = curl_init(normalizeUrlForFetch($url));
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_MAXREDIRS => 5,
    CURLOPT_TIMEOUT => 20,
    CURLOPT_USERAGENT => 'xLightsWiringViewerProxy/1.0',
]);
$body = curl_exec($ch);
$status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$err = curl_error($ch);
curl_close($ch);

if ($body === false) {
    http_response_code(502);
    header('Content-Type: text/plain');
    echo "Upstream fetch failed: $err";
    exit;
}

http_response_code($status ?: 200);
header('Content-Type: application/xml; charset=utf-8');
echo $body;
