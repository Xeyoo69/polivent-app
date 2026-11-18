import 'package:image_picker/image_picker.dart';

import '../models/payment_setting.dart';
import '../models/registration.dart';
import '../utils/json_helper.dart';
import 'api_service.dart';

/// Ringkasan jumlah pembayaran per status (untuk chip filter admin).
class PaymentSummary {
  const PaymentSummary({
    this.unpaid = 0,
    this.waiting = 0,
    this.paid = 0,
    this.rejected = 0,
  });

  final int unpaid;
  final int waiting;
  final int paid;
  final int rejected;

  int get total => unpaid + waiting + paid + rejected;

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      unpaid: jsonInt(json['unpaid']),
      waiting: jsonInt(json['waiting_confirmation']),
      paid: jsonInt(json['paid']),
      rejected: jsonInt(json['rejected']),
    );
  }
}

class PaymentPage {
  const PaymentPage({
    required this.payments,
    required this.summary,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  final List<Registration> payments;
  final PaymentSummary summary;
  final int total;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;
}

class PaymentService {
  PaymentService._();

  /// Pengaturan QR + rekening global.
  static Future<PaymentSetting> getSetting() async {
    final data = await ApiService.instance.get('/admin/payment-settings');

    return PaymentSetting.fromJson(jsonMap(data) ?? const <String, dynamic>{});
  }

  /// Simpan pengaturan pembayaran (QR opsional diganti).
  static Future<PaymentSetting> updateSetting({
    XFile? qr,
    String? accountName,
    String? accountNumber,
    String? adminPhone,
    String? notes,
  }) async {
    final data = await ApiService.instance.multipart(
      'PUT',
      '/admin/payment-settings',
      fields: {
        'account_name': accountName?.trim() ?? '',
        'account_number': accountNumber?.trim() ?? '',
        'admin_phone': adminPhone?.trim() ?? '',
        'notes': notes?.trim() ?? '',
      },
      file: qr,
      fileField: 'qr',
    );

    return PaymentSetting.fromJson(jsonMap(data) ?? const <String, dynamic>{});
  }

  /// Daftar pembayaran event berbayar.
  static Future<PaymentPage> getPayments({
    String? status,
    String? query,
    int page = 1,
    int perPage = 30,
  }) async {
    final data = await ApiService.instance.get(
      '/admin/payments',
      query: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        'page': '$page',
        'per_page': '$perPage',
      },
    );

    final map = jsonMap(data) ?? const <String, dynamic>{};
    final meta = jsonMap(map['meta']) ?? const <String, dynamic>{};

    final payments = jsonList(map['payments'])
        .map(jsonMap)
        .whereType<Map<String, dynamic>>()
        .map(Registration.fromJson)
        .toList();

    return PaymentPage(
      payments: payments,
      summary: PaymentSummary.fromJson(
        jsonMap(map['summary']) ?? const <String, dynamic>{},
      ),
      total: jsonInt(meta['total']),
      currentPage: jsonInt(meta['current_page'], 1),
      lastPage: jsonInt(meta['last_page'], 1),
    );
  }

  /// Setujui pembayaran; tiket peserta langsung terbit di server.
  static Future<Registration> verify(int registrationId) async {
    final data = await ApiService.instance.post(
      '/admin/registrations/$registrationId/verify',
    );

    return Registration.fromJson(jsonMap(data) ?? const <String, dynamic>{});
  }

  /// Tolak pembayaran dengan alasan yang terlihat oleh peserta.
  static Future<Registration> reject(int registrationId, String reason) async {
    final data = await ApiService.instance.post(
      '/admin/registrations/$registrationId/reject',
      body: {'reason': reason},
    );

    return Registration.fromJson(jsonMap(data) ?? const <String, dynamic>{});
  }
}
