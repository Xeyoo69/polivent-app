import 'package:flutter/foundation.dart';

/// Konfigurasi alamat API PoliVent.
///
/// - Android Emulator : http://10.0.2.2:8000/api
/// - Windows / Web    : http://127.0.0.1:8000/api
/// - HP fisik         : jalankan dengan
///                      `--dart-define=API_BASE_URL=http://<IP-LAN>:8000/api`
///                      atau isi [_lanOverride] dengan IP LAN laptop.
class ApiConfig {
  ApiConfig._();

  /// Isi hanya jika memakai HP Android fisik tanpa `--dart-define`.
  static const String? _lanOverride = null;

  /// Override saat menjalankan aplikasi, tanpa mengubah kode:
  ///
  /// ```bash
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
  /// ```
  static const String _envOverride = String.fromEnvironment('API_BASE_URL');

  static const String _androidEmulatorUrl = 'http://10.0.2.2:8000/api';
  static const String _localhostUrl = 'http://127.0.0.1:8000/api';

  /// Ngrok's free interstitial returns HTML instead of media unless bypassed.
  static Map<String, String> get mediaHeaders {
    final host = Uri.parse(baseUrl).host;
    if (host.endsWith('.ngrok-free.dev') ||
        host.endsWith('.ngrok-free.app') ||
        host.endsWith('.ngrok.app')) {
      return const {'ngrok-skip-browser-warning': 'true'};
    }

    return const {};
  }

  static String get baseUrl {
    if (_envOverride.isNotEmpty) {
      return _envOverride;
    }

    final override = _lanOverride;

    if (override != null && override.isNotEmpty) {
      return override;
    }

    if (kIsWeb) {
      final origin = Uri.base;
      final host = origin.host.toLowerCase();

      if (host != '127.0.0.1' && host != 'localhost') {
        return '${origin.scheme}://${origin.authority}/api';
      }

      return _localhostUrl;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorUrl;
    }

    return _localhostUrl;
  }

  /// Alamat asal server (tanpa /api), dipakai untuk keperluan gambar.
  static String get origin => baseUrl.replaceFirst(RegExp(r'/api$'), '');

  static const Duration requestTimeout = Duration(seconds: 25);
}
