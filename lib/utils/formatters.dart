/// Format tanggal & waktu dalam Bahasa Indonesia tanpa dependency tambahan.
class Formatters {
  Formatters._();

  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Contoh: "Senin, 5 Januari 2026".
  static String fullDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final dayName = _dayNames[(date.weekday - 1) % 7];

    return '$dayName, ${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  /// Contoh: "5 Jan 2026".
  static String shortDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final month = _monthNames[date.month - 1];

    return '${date.day} ${month.substring(0, 3)} ${date.year}';
  }

  /// Contoh: "08:00".
  static String time(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    final parts = value.split(':');

    if (parts.length < 2) {
      return value;
    }

    return '${parts[0]}:${parts[1]}';
  }

  /// Contoh: "08:00 - 12:00 WIB".
  static String timeRange(String? start, String? end) {
    return '${time(start)} - ${time(end)} WIB';
  }

  /// Contoh: "11/04/2026 09:15" dari ISO-8601.
  static String dateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(isoString);

    if (date == null) {
      return '-';
    }

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/${local.year} $hour:$minute';
  }

  /// Contoh: "Rp 25.000". Nilai 0 dianggap gratis.
  static String rupiah(num value) {
    final rounded = value.round();

    if (rounded <= 0) {
      return 'Gratis';
    }

    return 'Rp ${_thousands(rounded)}';
  }

  /// Contoh: "25.000" (tanpa awalan Rp) untuk isian form.
  static String thousands(num value) => _thousands(value.round());

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

  /// Format tanggal untuk dikirim ke API: "2026-01-05".
  static String apiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  /// Format jam untuk dikirim ke API: "08:00".
  static String apiTime(int hour, int minute) {
    final hourText = hour.toString().padLeft(2, '0');
    final minuteText = minute.toString().padLeft(2, '0');

    return '$hourText:$minuteText';
  }

  /// Selisih waktu sederhana untuk label kecil.
  static String relative(DateTime? date) {
    if (date == null) {
      return '';
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfDate = DateTime(date.year, date.month, date.day);
    final difference = startOfDate.difference(startOfToday).inDays;

    if (difference == 0) {
      return 'Hari ini';
    }

    if (difference == 1) {
      return 'Besok';
    }

    if (difference > 1) {
      return '$difference hari lagi';
    }

    if (difference == -1) {
      return 'Kemarin';
    }

    return '${difference.abs()} hari lalu';
  }
}
