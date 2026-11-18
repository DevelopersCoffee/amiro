import 'dart:convert';
import 'dart:io';

class WebShareState {
  const WebShareState({
    this.consentGiven = false,
    this.activeToken,
    this.useHttpsForQr = false,
  });

  final bool consentGiven;
  final String? activeToken;

  /// When true and [activeToken] is set, QR/NFC prefer the https link.
  final bool useHttpsForQr;

  bool get isPublished => activeToken != null && activeToken!.isNotEmpty;

  WebShareState copyWith({
    bool? consentGiven,
    String? activeToken,
    bool clearToken = false,
    bool? useHttpsForQr,
  }) {
    return WebShareState(
      consentGiven: consentGiven ?? this.consentGiven,
      activeToken: clearToken ? null : (activeToken ?? this.activeToken),
      useHttpsForQr: useHttpsForQr ?? this.useHttpsForQr,
    );
  }

  Map<String, dynamic> toJson() => {
    'consentGiven': consentGiven,
    if (activeToken != null) 'activeToken': activeToken,
    'useHttpsForQr': useHttpsForQr,
  };

  factory WebShareState.fromJson(Map<String, dynamic> json) {
    return WebShareState(
      consentGiven: json['consentGiven'] as bool? ?? false,
      activeToken: json['activeToken'] as String?,
      useHttpsForQr: json['useHttpsForQr'] as bool? ?? false,
    );
  }

  static const empty = WebShareState();
}

class WebSharePreferences {
  WebSharePreferences(this._file);

  final File _file;

  factory WebSharePreferences.inDirectory(Directory directory) {
    return WebSharePreferences(File('${directory.path}/web_share_state.json'));
  }

  Future<WebShareState> read() async {
    if (!await _file.exists()) return WebShareState.empty;
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is Map<String, dynamic>) {
        return WebShareState.fromJson(decoded);
      }
    } catch (_) {}
    return WebShareState.empty;
  }

  Future<void> write(WebShareState state) async {
    await _file.writeAsString(jsonEncode(state.toJson()));
  }
}