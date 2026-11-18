import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polivent/config/app_theme.dart';
import 'package:polivent/widgets/admin_contact_card.dart';
import 'package:polivent/widgets/decorative_pattern.dart';
import 'package:polivent/widgets/event_banner.dart';
import 'package:polivent/widgets/fade_slide_in.dart';
import 'package:polivent/widgets/press_scale.dart';
import 'package:polivent/widgets/section_header.dart';
import 'package:polivent/widgets/skeleton.dart';

void main() {
  testWidgets('Skeleton list tampil dan controller dibersihkan',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EventListSkeleton(itemCount: 3),
        ),
      ),
    );

    expect(find.byType(EventCardSkeleton), findsNWidgets(3));

    await tester.pump(const Duration(milliseconds: 200));

    // Ganti widget: AnimationController shimmer harus ter-dispose.
    await tester.pumpWidget(const SizedBox.shrink());

    expect(tester.takeException(), isNull);
  });

  testWidgets('PressScale mengecil saat ditekan lalu kembali normal',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Center(
          child: PressScale(
            child: Container(
              key: const Key('press-target'),
              width: 120,
              height: 120,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('press-target'))),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0.97,
    );

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      1.0,
    );
  });

  testWidgets('FadeSlideIn berakhir sepenuhnya terlihat',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FadeSlideIn(child: Text('Halo PoliVent')),
      ),
    );

    await tester.pump(const Duration(milliseconds: 800));

    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(FadeSlideIn),
        matching: find.byType(Opacity),
      ),
    );

    expect(opacity.opacity, 1.0);
    expect(find.text('Halo PoliVent'), findsOneWidget);
  });

  testWidgets('SectionHeader menampilkan aksen dan menjalankan aksi',
      (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SectionHeader(
            title: 'Event Pilihan',
            actionLabel: 'Lihat semua',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Event Pilihan'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    await tester.tap(find.text('Lihat semua'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('Kartu kontak admin menyalin nomor ke clipboard',
      (WidgetTester tester) async {
    String? copied;

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }

        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: AdminContactCard(phone: '0812-3456-7890'),
          ),
        ),
      ),
    );

    expect(find.text('Butuh bantuan? Hubungi admin'), findsOneWidget);
    expect(find.text('0812-3456-7890'), findsOneWidget);

    await tester.tap(find.text('Salin'));
    await tester.pump();

    expect(copied, '0812-3456-7890');
    expect(find.text('Nomor admin berhasil disalin.'), findsOneWidget);
  });

  testWidgets('Banner tanpa gambar memakai placeholder berornamen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: EventBanner(height: 120),
          ),
        ),
      ),
    );

    expect(find.byType(DecorativePattern), findsOneWidget);
    expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);
  });
}
