import '../utils/json_helper.dart';
import 'event.dart';
import 'payment.dart';
import 'user.dart';

class Registration {
  const Registration({
    required this.id,
    required this.status,
    this.ticketCode,
    this.registeredAt,
    this.event,
    this.user,
    this.payment = const PaymentInfo(),
    this.participantName,
    this.participantNim,
    this.participantEmail,
    this.ktmUrl,
    this.teamName,
    this.teamMembers = const [],
  });

  final int id;

  /// Null selama pembayaran event berbayar belum diverifikasi admin.
  final String? ticketCode;
  final String status;
  final DateTime? registeredAt;
  final Event? event;
  final User? user;
  final PaymentInfo payment;
  final String? participantName;
  final String? participantNim;
  final String? participantEmail;
  final String? ktmUrl;
  final String? teamName;
  final List<Map<String, dynamic>> teamMembers;

  int get totalTeamMembers => teamName == null ? 1 : teamMembers.length;

  /// Tiket sudah terbit (event gratis atau pembayaran sudah lunas).
  bool get hasTicket => ticketCode != null && ticketCode!.isNotEmpty;

  String get statusLabel {
    switch (status) {
      case 'attended':
        return 'Hadir';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Terdaftar';
    }
  }

  bool get isAttended => status == 'attended';
  bool get isCancelled => status == 'cancelled';

  factory Registration.fromJson(Map<String, dynamic> json) {
    final eventJson = jsonMap(json['event']);
    final userJson = jsonMap(json['user']);
    final paymentJson = jsonMap(json['payment']);

    return Registration(
      id: jsonInt(json['id']),
      ticketCode: jsonStringOrNull(json['ticket_code']),
      status: jsonString(json['status'], 'registered'),
      registeredAt: jsonDate(json['registered_at']),
      event: eventJson == null ? null : Event.fromJson(eventJson),
      user: userJson == null ? null : User.fromJson(userJson),
      payment: paymentJson == null
          ? const PaymentInfo()
          : PaymentInfo.fromJson(paymentJson),
      participantName: jsonStringOrNull(jsonMap(json['participant'])?['name']),
      participantNim: jsonStringOrNull(jsonMap(json['participant'])?['nim']),
      participantEmail: jsonStringOrNull(jsonMap(json['participant'])?['email']),
      ktmUrl: jsonStringOrNull(json['ktm_url']),
      teamName: jsonStringOrNull(jsonMap(json['team'])?['name']),
      teamMembers: jsonList(jsonMap(json['team'])?['members'])
          .map(jsonMap)
          .whereType<Map<String, dynamic>>()
          .toList(),
    );
  }
}
