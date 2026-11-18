import '../utils/json_helper.dart';
import 'category.dart';

class Event {
  const Event({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.organizer,
    required this.quota,
    this.price = 0,
    this.category,
    this.bannerUrl,
    this.qrUrl,
    this.participantsCount = 0,
    this.remainingQuota = 0,
    this.isRegistered = false,
    this.isFinished = false,
    this.isFull = false,
    this.requiresKtm = false,
    this.registrationType = 'individual',
    this.teamMinMembers,
    this.teamMaxMembers,
    this.registrationDeadlineDate,
    this.registrationDeadlineTime,
    this.isRegistrationClosed = false,
  });

  final int id;
  final int categoryId;
  final Category? category;
  final String title;
  final String description;
  final String? bannerUrl;
  final String? qrUrl;
  final DateTime? date;
  final String startTime;
  final String endTime;
  final String location;
  final String organizer;
  final int quota;
  final int price;
  final int participantsCount;
  final int remainingQuota;
  final bool isRegistered;
  final bool isFinished;
  final bool isFull;
  final bool requiresKtm;
  final String registrationType;
  final int? teamMinMembers;
  final int? teamMaxMembers;
  final DateTime? registrationDeadlineDate;
  final String? registrationDeadlineTime;
  final bool isRegistrationClosed;

  bool get isTeamEvent => registrationType == 'team';

  String get categoryName => category?.name ?? 'Lainnya';

  DateTime? get startsAt {
    if (date == null) {
      return null;
    }

    return DateTime(
      date!.year,
      date!.month,
      date!.day,
      _hour(startTime),
      _minute(startTime),
    );
  }

  bool get isAlmostFull => !isFull && remainingQuota > 0 && remainingQuota <= 5;

  /// Event berbayar (harga tiket lebih dari 0).
  bool get isPaidEvent => price > 0;

  /// Label harga untuk ditampilkan: "Rp 25.000" atau "Gratis".
  String get priceLabel {
    if (!isPaidEvent) {
      return 'Gratis';
    }

    return 'Rp ${_thousands(price)}';
  }

  static String _thousands(int value) {
    final text = value.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  String get quotaLabel {
    if (isFinished) {
      return 'Selesai';
    }

    if (isFull || remainingQuota <= 0) {
      return 'Kuota penuh';
    }

    return 'Sisa $remainingQuota dari $quota kuota';
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: jsonInt(json['id']),
      categoryId: jsonInt(json['category_id']),
      category: jsonMap(json['category']) == null
          ? null
          : Category.fromJson(jsonMap(json['category'])!),
      title: jsonString(json['title'], 'Event'),
      description: jsonString(json['description']),
      bannerUrl: jsonStringOrNull(json['banner_url']),
      qrUrl: jsonStringOrNull(json['qr_url']),
      date: jsonDate(json['date']),
      startTime: jsonString(json['start_time'], '00:00:00'),
      endTime: jsonString(json['end_time'], '00:00:00'),
      location: jsonString(json['location'], '-'),
      organizer: jsonString(json['organizer'], '-'),
      quota: jsonInt(json['quota']),
      price: jsonInt(json['price']),
      participantsCount: jsonInt(json['participants_count']),
      remainingQuota: jsonInt(json['remaining_quota']),
      isRegistered: jsonBool(json['is_registered']),
      isFinished: jsonBool(json['is_finished']),
      isFull: jsonBool(json['is_full']),
      requiresKtm: jsonBool(json['requires_ktm']),
      registrationType: jsonString(json['registration_type'], 'individual'),
      teamMinMembers: json['team_min_members'] == null
          ? null
          : jsonInt(json['team_min_members']),
      teamMaxMembers: json['team_max_members'] == null
          ? null
          : jsonInt(json['team_max_members']),
      registrationDeadlineDate: jsonDate(json['registration_deadline_date']),
      registrationDeadlineTime: jsonStringOrNull(json['registration_deadline_time']),
      isRegistrationClosed: jsonBool(json['registration_closed']),
    );
  }

  static int _hour(String time) {
    final parts = time.split(':');

    return parts.isEmpty ? 0 : (int.tryParse(parts[0]) ?? 0);
  }

  static int _minute(String time) {
    final parts = time.split(':');

    return parts.length < 2 ? 0 : (int.tryParse(parts[1]) ?? 0);
  }
}
