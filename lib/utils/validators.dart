/// Validasi form di sisi Flutter.
/// Aturan yang sama tetap divalidasi ulang di Laravel.
class Validators {
  Validators._();

  static String? required(String? value, {String label = 'Field ini'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi.';
    }

    return null;
  }

  static String? name(String? value) {
    final empty = required(value, label: 'Nama lengkap');
    if (empty != null) {
      return empty;
    }

    if (value!.trim().length < 3) {
      return 'Nama minimal 3 karakter.';
    }

    return null;
  }

  static String? nim(String? value) {
    final empty = required(value, label: 'NIM');
    if (empty != null) {
      return empty;
    }

    if (value!.trim().length < 6) {
      return 'NIM minimal 6 karakter.';
    }

    return null;
  }

  static String? email(String? value) {
    final empty = required(value, label: 'Email');
    if (empty != null) {
      return empty;
    }

    final pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(value!.trim())) {
      return 'Format email tidak valid.';
    }

    return null;
  }

  static String? password(String? value) {
    final empty = required(value, label: 'Password');
    if (empty != null) {
      return empty;
    }

    if (value!.length < 6) {
      return 'Password minimal 6 karakter.';
    }

    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final empty = required(value, label: 'Konfirmasi password');
    if (empty != null) {
      return empty;
    }

    if (value != password) {
      return 'Konfirmasi password tidak sama.';
    }

    return null;
  }

  /// Nomor HP/WA admin opsional untuk kontak bantuan.
  ///
  /// Aturannya sama dengan validasi Laravel: 8–30 karakter, hanya angka,
  /// spasi, `+`, `-`, atau tanda kurung.
  static String? adminPhone(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final allowed = RegExp(r'^[0-9+\-\s()]+$');
    if (!allowed.hasMatch(text)) {
      return 'Nomor HP hanya boleh angka, spasi, +, -, atau tanda kurung.';
    }

    if (text.length < 8) {
      return 'Nomor HP minimal 8 karakter.';
    }

    if (text.length > 30) {
      return 'Nomor HP maksimal 30 karakter.';
    }

    return null;
  }

  static String? quota(String? value) {
    final empty = required(value, label: 'Kuota');
    if (empty != null) {
      return empty;
    }

    final quota = int.tryParse(value!.trim());
    if (quota == null) {
      return 'Kuota harus berupa angka.';
    }

    if (quota < 1) {
      return 'Kuota minimal 1.';
    }

    return null;
  }

  /// Harga tiket dalam Rupiah. Boleh 0 (gratis), tidak boleh negatif.
  static String? price(String? value) {
    final empty = required(value, label: 'Harga tiket');
    if (empty != null) {
      return empty;
    }

    final price = int.tryParse(value!.replaceAll('.', '').trim());
    if (price == null) {
      return 'Harga tiket harus berupa angka.';
    }

    if (price < 0) {
      return 'Harga tiket tidak boleh negatif.';
    }

    if (price > 100000000) {
      return 'Harga tiket terlalu besar.';
    }

    return null;
  }
}
