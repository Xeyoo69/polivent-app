import 'package:flutter/foundation.dart';

/// Notifier ringan untuk memberi tahu layar lain bahwa data berubah
/// (misalnya setelah mendaftar event atau CRUD admin).
class AppEvents {
  AppEvents._();

  static final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  static void notifyDataChanged() {
    dataVersion.value++;
  }
}
