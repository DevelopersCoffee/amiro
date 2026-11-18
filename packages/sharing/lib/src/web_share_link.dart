import 'dart:convert';
import 'dart:math';

/// Default host for published web shares (override with dart-define in the app).
const defaultWebShareHost = 'id.amiro.app';

const webSharePathPrefix = '/u/';

/// At least 128 bits of entropy in the opaque path token.
const webShareTokenByteLength = 16;

/// Builds `https://<host>/u/<token>` with no query or fragment.
String buildWebShareUri(String token, {String host = defaultWebShareHost}) {
  return Uri(
    scheme: 'https',
    host: host,
    path: '$webSharePathPrefix$token',
  ).toString();
}

/// Generates a URL-safe opaque token (128+ bits).
String generateWebShareToken([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(webShareTokenByteLength, (_) => rng.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// True when [uri] is a web share link with only an opaque token (no `#`).
bool isWebShareUri(Uri uri, {Iterable<String> allowedHosts = const [defaultWebShareHost]}) {
  if (uri.scheme != 'https') return false;
  if (!allowedHosts.contains(uri.host)) return false;
  if (uri.hasFragment) return false;
  if (uri.queryParameters.isNotEmpty) return false;
  final segments = uri.pathSegments;
  if (segments.length != 2 || segments.first != 'u') return false;
  final token = segments[1];
  if (token.length < 22 || token.length > 64) return false;
  return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(token);
}

String? parseWebShareToken(String raw, {Iterable<String> allowedHosts = const [defaultWebShareHost]}) {
  final Uri parsed;
  try {
    parsed = Uri.parse(raw);
  } on FormatException {
    return null;
  }
  if (!isWebShareUri(parsed, allowedHosts: allowedHosts)) return null;
  return parsed.pathSegments[1];
}

/// Ensures share URIs never embed contact data or payloads in the URL.
bool webShareUriContainsNoPii(String uri) {
  final lower = uri.toLowerCase();
  if (lower.contains('@')) return false;
  if (lower.contains('mailto:')) return false;
  if (lower.contains('tel:')) return false;
  if (uri.contains('#')) return false;
  if (uri.contains('?d=') || uri.contains('&c=')) return false;
  return true;
}