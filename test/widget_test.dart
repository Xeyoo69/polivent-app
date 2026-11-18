import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polivent/config/app_theme.dart';
import 'package:polivent/screens/auth/login_screen.dart';

void main() {
  testWidgets('Halaman login menampilkan form email dan password',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    );

    expect(find.text('POLIVENT'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('MASUK'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'bukan-email');
    await tester.tap(find.text('MASUK'));
    await tester.pump();

    expect(find.text('Format email tidak valid.'), findsOneWidget);
  });

  testWidgets('Chip akun demo mengisi email dan password',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    );

    // Tombol pintasan development harus mengisi kedua field sekaligus.
    await tester.ensureVisible(find.text('Mahasiswa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mahasiswa'));
    await tester.pump();

    expect(find.text('mahasiswa@polivent.test'), findsOneWidget);
    expect(find.text('password'), findsOneWidget);
  });
}
