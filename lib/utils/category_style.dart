import 'package:flutter/material.dart';

/// Warna + ikon per kategori event.
///
/// Dipakai untuk placeholder banner dan chip kategori supaya setiap jenis
/// kegiatan punya "wajah" sendiri, bukan biru yang sama terus.
class CategoryStyle {
  const CategoryStyle({required this.gradient, required this.icon});

  final List<Color> gradient;
  final IconData icon;

  static const CategoryStyle seminar = CategoryStyle(
    gradient: [Color(0xFF4338CA), Color(0xFF6366F1)],
    icon: Icons.school_rounded,
  );

  static const CategoryStyle webinar = CategoryStyle(
    gradient: [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
    icon: Icons.videocam_rounded,
  );

  static const CategoryStyle workshop = CategoryStyle(
    gradient: [Color(0xFF6D28D9), Color(0xFFA855F7)],
    icon: Icons.handyman_rounded,
  );

  static const CategoryStyle lomba = CategoryStyle(
    gradient: [Color(0xFFC2410C), Color(0xFFF59E0B)],
    icon: Icons.emoji_events_rounded,
  );

  static const CategoryStyle pelatihan = CategoryStyle(
    gradient: [Color(0xFF0F766E), Color(0xFF14B8A6)],
    icon: Icons.workspace_premium_rounded,
  );

  static const CategoryStyle organisasi = CategoryStyle(
    gradient: [Color(0xFFBE185D), Color(0xFFF43F5E)],
    icon: Icons.groups_rounded,
  );

  static const CategoryStyle fallback = CategoryStyle(
    gradient: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    icon: Icons.event_available_rounded,
  );

  /// Cocokkan berdasarkan nama kategori dari API (tidak case-sensitive).
  static CategoryStyle forName(String? name) {
    final value = (name ?? '').toLowerCase();

    if (value.contains('seminar')) {
      return seminar;
    }

    if (value.contains('webinar')) {
      return webinar;
    }

    if (value.contains('workshop') || value.contains('lokakarya')) {
      return workshop;
    }

    if (value.contains('lomba') || value.contains('kompetisi')) {
      return lomba;
    }

    if (value.contains('pelatihan') || value.contains('training')) {
      return pelatihan;
    }

    if (value.contains('organisasi') || value.contains('komunitas')) {
      return organisasi;
    }

    return fallback;
  }
}
