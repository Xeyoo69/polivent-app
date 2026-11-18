import 'package:flutter/widgets.dart';

/// Navigator key global agar service bisa mengarahkan user ke Login
/// ketika token sudah tidak valid (401).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
