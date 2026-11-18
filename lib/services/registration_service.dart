import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import '../models/registration.dart';
import '../utils/json_helper.dart';
import 'api_service.dart';

class TeamMemberInput {
  const TeamMemberInput({required this.name, required this.nim, this.ktm});

  final String name;
  final String nim;
  final XFile? ktm;

  Map<String, String> toJson() => {'name': name.trim(), 'nim': nim.trim()};
}

class RegistrationService {
  RegistrationService._();

  static Future<List<Registration>> myRegistrations({String? status}) async {
    final data = await ApiService.instance.get(
      '/my-registrations',
      query: {if (status != null && status.isNotEmpty) 'status': status},
    );

    return jsonList(data)
        .map(jsonMap)
        .whereType<Map<String, dynamic>>()
        .map(Registration.fromJson)
        .toList();
  }

  static Future<Registration> register(
    int eventId, {
    required String participantName,
    required String participantNim,
    required String participantEmail,
    XFile? ktm,
    String? teamName,
    List<TeamMemberInput> teamMembers = const [],
  }) async {
    final files = <XFile>[
      if (teamMembers.isNotEmpty && teamMembers.first.ktm != null)
        teamMembers.first.ktm!,
      ...teamMembers.skip(1).map((member) => member.ktm).whereType<XFile>(),
    ];

    final data = await ApiService.instance.multipart(
      'POST',
      '/events/$eventId/register',
      fields: {
        'participant_name': participantName.trim(),
        'participant_nim': participantNim.trim(),
        'participant_email': participantEmail.trim(),
        if (teamName != null) 'team_name': teamName.trim(),
        if (teamName != null)
          'team_members': jsonEncode(
            teamMembers.map((member) => member.toJson()).toList(),
          ),
      },
      file: teamName == null ? ktm : null,
      fileField: 'ktm',
      files: files.isEmpty ? null : files,
    );

    return Registration.fromJson(jsonMap(data) ?? const <String, dynamic>{});
  }

  static Future<Registration> getTicket(int registrationId) async {
    final data = await ApiService.instance.get(
      '/registrations/$registrationId',
    );

    return Registration.fromJson(jsonMap(data) ?? const <String, dynamic>{});
  }

  static Future<Registration> uploadPaymentProof(
    int registrationId,
    XFile proof,
  ) async {
    final data = await ApiService.instance.multipart(
      'POST',
      '/registrations/$registrationId/payment',
      fields: const {},
      file: proof,
      fileField: 'proof',
    );

    return Registration.fromJson(jsonMap(data) ?? const <String, dynamic>{});
  }
}
