/// Helper untuk membaca JSON dari API dengan aman (null-safe).
int jsonInt(dynamic value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double jsonDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

String jsonString(dynamic value, [String fallback = '']) {
  if (value == null) {
    return fallback;
  }

  return value.toString();
}

String? jsonStringOrNull(dynamic value) {
  if (value == null) {
    return null;
  }

  final text = value.toString();

  return text.isEmpty ? null : text;
}

bool jsonBool(dynamic value, [bool fallback = false]) {
  if (value == null) {
    return fallback;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final text = value.toString().toLowerCase();

  return text == 'true' || text == '1';
}

DateTime? jsonDate(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value.toString());
}

Map<String, dynamic>? jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  return null;
}

List<dynamic> jsonList(dynamic value) {
  if (value is List) {
    return value;
  }

  return const [];
}
