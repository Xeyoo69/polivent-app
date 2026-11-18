import '../utils/json_helper.dart';
import 'api_service.dart';

/// Informasi publik aplikasi yang bisa diakses sebelum login.
class AppInfoService {
  AppInfoService._();

  /// Nomor HP/WhatsApp admin untuk kontak bantuan.
  ///
  /// Sengaja tidak di-cache supaya perubahan nomor dari halaman admin
  /// langsung terlihat saat admin logout ke halaman login.
  /// Mengembalikan null jika admin belum mengatur nomor.
  static Future<String?> getAdminPhone() async {
    final data = await ApiService.instance.get('/app-info', auth: false);
    final phone = jsonStringOrNull(jsonMap(data)?['admin_phone'])?.trim();

    if (phone == null || phone.isEmpty) {
      return null;
    }

    return phone;
  }
}
