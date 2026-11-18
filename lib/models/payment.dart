import '../utils/json_helper.dart';

/// Informasi pembayaran sebuah pendaftaran (nominal, QR, dan status).
class PaymentInfo {
  const PaymentInfo({
    this.required = false,
    this.amount = 0,
    this.amountLabel = 'Gratis',
    this.status = 'paid',
    this.statusLabel = 'Pembayaran Lunas',
    this.qrUrl,
    this.accountName,
    this.accountNumber,
    this.notes,
    this.proofUrl,
    this.rejectionReason,
    this.canUploadProof = false,
    this.paidAt,
    this.verifiedAt,
  });

  final bool required;
  final int amount;
  final String amountLabel;
  final String status;
  final String statusLabel;
  final String? qrUrl;
  final String? accountName;
  final String? accountNumber;
  final String? notes;
  final String? proofUrl;
  final String? rejectionReason;
  final bool canUploadProof;
  final DateTime? paidAt;
  final DateTime? verifiedAt;

  bool get isPaid => status == 'paid';
  bool get isWaiting => status == 'waiting_confirmation';
  bool get isRejected => status == 'rejected';
  bool get isUnpaid => status == 'unpaid';

  /// Event berbayar yang belum lunas.
  bool get isPending => required && !isPaid;

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      required: jsonBool(json['required']),
      amount: jsonInt(json['amount']),
      amountLabel: jsonString(json['amount_label'], 'Gratis'),
      status: jsonString(json['status'], 'paid'),
      statusLabel: jsonString(json['status_label'], 'Pembayaran Lunas'),
      qrUrl: jsonStringOrNull(json['qr_url']),
      accountName: jsonStringOrNull(json['account_name']),
      accountNumber: jsonStringOrNull(json['account_number']),
      notes: jsonStringOrNull(json['notes']),
      proofUrl: jsonStringOrNull(json['proof_url']),
      rejectionReason: jsonStringOrNull(json['rejection_reason']),
      canUploadProof: jsonBool(json['can_upload_proof']),
      paidAt: jsonDate(json['paid_at']),
      verifiedAt: jsonDate(json['verified_at']),
    );
  }
}
