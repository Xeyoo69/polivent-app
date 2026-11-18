import '../utils/json_helper.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    this.eventsCount,
  });

  final int id;
  final String name;
  final int? eventsCount;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: jsonInt(json['id']),
      name: jsonString(json['name'], 'Kategori'),
      eventsCount: json['events_count'] == null ? null : jsonInt(json['events_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'events_count': eventsCount,
    };
  }
}
