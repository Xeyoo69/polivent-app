import '../utils/json_helper.dart';

/// Pengaturan pembayaran global yang diatur admin.
class PaymentSetting {
  const PaymentSetting({
    this.qrUrl,
    this.accountName,
    this.accountNumber,
    this.adminPhone,
    this.notes,
  });

  final String? qrUrl;
  final String? accountName;
  final String? accountNumber;
  final String? adminPhone;
  final String? notes;

  bool get hasQr => qrUrl != null && qrUrl!.isNotEmpty;

  factory PaymentSetting.fromJson(Map<String, dynamic> json) {
    return PaymentSetting(
      qrUrl: jsonStringOrNull(json['qr_url']),
      accountName: jsonStringOrNull(json['account_name']),
      accountNumber: jsonStringOrNull(json['account_number']),
      adminPhone: jsonStringOrNull(json['admin_phone']),
      notes: jsonStringOrNull(json['notes']),
    );
  }
}
