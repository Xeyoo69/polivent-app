import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../models/event.dart';
import '../models/registration.dart';
import '../utils/formatters.dart';
import '../utils/json_helper.dart';
import 'api_service.dart';

class EventPage {
  const EventPage({
    required this.events,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  final List<Event> events;
  final int total;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;
}

class ParticipantsResult {
  const ParticipantsResult({
    this.event,
    required this.participants,
    required this.total,
  });

  final Event? event;
  final List<Registration> participants;
  final int total;
}

class AdminStats {
  const AdminStats({
    this.totalEvents = 0,
    this.activeEvents = 0,
    this.finishedEvents = 0,
    this.totalParticipants = 0,
    this.totalUsers = 0,
    this.pendingPayments = 0,
    this.paidRegistrations = 0,
    this.revenue = 0,
  });

  final int totalEvents;
  final int activeEvents;
  final int finishedEvents;
  final int totalParticipants;
  final int totalUsers;
  final int pendingPayments;
  final int paidRegistrations;
  final int revenue;

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalEvents: jsonInt(json['total_events']),
      activeEvents: jsonInt(json['active_events']),
      finishedEvents: jsonInt(json['finished_events']),
      totalParticipants: jsonInt(json['total_participants']),
      totalUsers: jsonInt(json['total_users']),
      pendingPayments: jsonInt(json['pending_payments']),
      paidRegistrations: jsonInt(json['paid_registrations']),
      revenue: jsonInt(json['revenue']),
    );
  }
}

class EventService {
  EventService._();

  static Future<EventPage> getEvents({
    String? query,
    int? categoryId,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final data = await ApiService.instance.get(
      '/events',
      query: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (categoryId != null) 'category_id': '$categoryId',
        if (status != null && status.isNotEmpty) 'status': status,
        'page': '$page',
        'per_page': '$perPage',
      },
    );

    final map = jsonMap(data) ?? const <String, dynamic>{};
    final meta = jsonMap(map['meta']) ?? const <String, dynamic>{};

    final events = jsonList(map['events'])
        .map(jsonMap)
        .whereType<Map<String, dynamic>>()
        .map(Event.fromJson)
        .toList();

    return EventPage(
      events: events,
      total: jsonInt(meta['total']),
      currentPage: jsonInt(meta['current_page'], 1),
      lastPage: jsonInt(meta['last_page'], 1),
    );
  }

  static Future<Event> getEvent(int id) async {
    final data = await ApiService.instance.get('/events/$id');

    return Event.fromJson(jsonMap(data) ?? const <String, dynamic>{});
  }

  static Future<List<Category>> getCategories() async {
    final data = await ApiService.instance.get('/categories');

    return jsonList(data)
        .map(jsonMap)
        .whereType<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
  }

  static Future<AdminStats> getStats() async {
    final data = await ApiService.instance.get('/admin/stats');

    return AdminStats.fromJson(jsonMap(data) ?? const <String, dynamic>{});
  }

  static Future<Event> createEvent({
    required int categoryId,
    required String title,
    required String description,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String location,
    required String organizer,
    required int quota,
    required int price,
    required bool requiresKtm,
    required String registrationType,
    int? teamMinMembers,
    int? teamMaxMembers,
    DateTime? registrationDeadlineDate,
    String? registrationDeadlineTime,
    XFile? banner,
    XFile? qr,
  }) async {
    final data = await ApiService.instance.multipart(
      'POST',
      '/events',
      fields: _eventFields(
        categoryId: categoryId,
        title: title,
        description: description,
        date: date,
        startTime: startTime,
        endTime: endTime,
        location: location,
        organizer: organizer,
        quota: quota,
        price: price,
        requiresKtm: requiresKtm,
        registrationType: registrationType,
        teamMinMembers: teamMinMembers,
        teamMaxMembers: teamMaxMembers,
        registrationDeadlineDate: registrationDeadlineDate,
        registrationDeadlineTime: registrationDeadlineTime,
      ),
      file: banner,
      namedFiles: qr == null ? null : {'qr': qr},
    );

    return Event.fromJson(jsonMap(data) ?? const <String, dynamic>{});
  }

  static Future<Event> updateEvent({
    required int id,
    required int categoryId,
    required String title,
    required String description,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String location,
    required String organizer,
    required int quota,
    required int price,
    required bool requiresKtm,
    required String registrationType,
    int? teamMinMembers,
    int? teamMaxMembers,
    DateTime? registrationDeadlineDate,
    String? registrationDeadlineTime,
    XFile? banner,
    XFile? qr,
  }) async {
    final data = await ApiService.instance.multipart(
      'PUT',
      '/events/$id',
      fields: _eventFields(
        categoryId: categoryId,
        title: title,
        description: description,
        date: date,
        startTime: startTime,
        endTime: endTime,
        location: location,
        organizer: organizer,
        quota: quota,
        price: price,
        requiresKtm: requiresKtm,
        registrationType: registrationType,
        teamMinMembers: teamMinMembers,
        teamMaxMembers: teamMaxMembers,
        registrationDeadlineDate: registrationDeadlineDate,
        registrationDeadlineTime: registrationDeadlineTime,
      ),
      file: banner,
      namedFiles: qr == null ? null : {'qr': qr},
    );

    return Event.fromJson(jsonMap(data) ?? const <String, dynamic>{});
  }

  static Future<void> deleteEvent(int id) async {
    await ApiService.instance.delete('/events/$id');
  }

  static Future<ParticipantsResult> getParticipants(
    int eventId, {
    String? query,
  }) async {
    final data = await ApiService.instance.get(
      '/events/$eventId/participants',
      query: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );

    final map = jsonMap(data) ?? const <String, dynamic>{};
    final eventJson = jsonMap(map['event']);

    final participants = jsonList(map['participants'])
        .map(jsonMap)
        .whereType<Map<String, dynamic>>()
        .map(Registration.fromJson)
        .toList();

    return ParticipantsResult(
      event: eventJson == null ? null : Event.fromJson(eventJson),
      participants: participants,
      total: jsonInt(map['total']),
    );
  }

  static Map<String, String> _eventFields({
    required int categoryId,
    required String title,
    required String description,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String location,
    required String organizer,
    required int quota,
    required int price,
    required bool requiresKtm,
    required String registrationType,
    int? teamMinMembers,
    int? teamMaxMembers,
    DateTime? registrationDeadlineDate,
    String? registrationDeadlineTime,
  }) {
    return {
      'category_id': '$categoryId',
      'title': title.trim(),
      'description': description.trim(),
      'date': Formatters.apiDate(date),
      'start_time': startTime,
      'end_time': endTime,
      'location': location.trim(),
      'organizer': organizer.trim(),
      'quota': '$quota',
      'price': '$price',
      'requires_ktm': requiresKtm ? '1' : '0',
      'registration_type': registrationType,
      if (teamMinMembers != null) 'team_min_members': '$teamMinMembers',
      if (teamMaxMembers != null) 'team_max_members': '$teamMaxMembers',
      if (registrationDeadlineDate != null)
        'registration_deadline_date': Formatters.apiDate(registrationDeadlineDate),
      'registration_deadline_time': ?registrationDeadlineTime,
    };
  }
}
