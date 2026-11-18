import 'package:flutter_test/flutter_test.dart';
import 'package:polivent/models/event.dart';
import 'package:polivent/models/payment_setting.dart';
import 'package:polivent/models/registration.dart';
import 'package:polivent/models/user.dart';
import 'package:polivent/utils/formatters.dart';
import 'package:polivent/utils/validators.dart';

void main() {
  group('Event.fromJson', () {
    test('membaca data event lengkap', () {
      final event = Event.fromJson({
        'id': 1,
        'category_id': 2,
        'category': {'id': 2, 'name': 'Seminar'},
        'title': 'Seminar Nasional',
        'description': 'Deskripsi',
        'banner_url': null,
        'date': '2026-11-05',
        'start_time': '08:00:00',
        'end_time': '12:00:00',
        'location': 'Aula Polinela',
        'organizer': 'BEM Polinela',
        'quota': 100,
        'participants_count': 40,
        'remaining_quota': 60,
        'is_registered': false,
        'is_finished': false,
        'is_full': false,
      });

      expect(event.id, 1);
      expect(event.categoryName, 'Seminar');
      expect(event.date, DateTime(2026, 11, 5));
      expect(event.startsAt, DateTime(2026, 11, 5, 8, 0));
      expect(event.remainingQuota, 60);
      expect(event.isRegistered, isFalse);
      expect(event.quotaLabel, 'Sisa 60 dari 100 kuota');
      expect(event.isPaidEvent, isFalse);
      expect(event.priceLabel, 'Gratis');
    });

    test('membaca harga tiket event berbayar', () {
      final event = Event.fromJson({
        'id': 2,
        'title': 'Workshop Flutter',
        'quota': 30,
        'price': 25000,
        'price_label': 'Rp 25.000',
        'is_paid': true,
      });

      expect(event.price, 25000);
      expect(event.isPaidEvent, isTrue);
      expect(event.priceLabel, 'Rp 25.000');
    });

    test('membaca URL QRIS event', () {
      final event = Event.fromJson({
        'id': 3,
        'qr_url': 'https://example.test/qr-event.png',
      });

      expect(event.qrUrl, 'https://example.test/qr-event.png');
    });

    test('aman terhadap nilai null', () {
      final event = Event.fromJson({'id': 5});

      expect(event.id, 5);
      expect(event.categoryName, 'Lainnya');
      expect(event.date, isNull);
      expect(event.quota, 0);
      expect(event.description, '');
    });
  });

  group('Registration.fromJson', () {
    test('membaca tiket dan relasi event', () {
      final registration = Registration.fromJson({
        'id': 9,
        'ticket_code': 'POLI-2026-ABC123',
        'status': 'registered',
        'registered_at': '2026-10-28T10:00:00+07:00',
        'event': {'id': 1, 'title': 'Seminar'},
        'user': {
          'id': 2,
          'name': 'Mahasiswa Demo',
          'nim': '12345678',
          'email': 'mahasiswa@polivent.test',
          'role': 'user',
        },
      });

      expect(registration.ticketCode, 'POLI-2026-ABC123');
      expect(registration.statusLabel, 'Terdaftar');
      expect(registration.event?.title, 'Seminar');
      expect(registration.user?.nim, '12345678');
      expect(registration.user?.initials, 'MD');
    });

    test('pendaftaran berbayar belum punya tiket sampai diverifikasi', () {
      final registration = Registration.fromJson({
        'id': 10,
        'ticket_code': null,
        'status': 'registered',
        'payment': {
          'required': true,
          'amount': 25000,
          'amount_label': 'Rp 25.000',
          'status': 'waiting_confirmation',
          'status_label': 'Menunggu Verifikasi',
          'can_upload_proof': false,
        },
      });

      expect(registration.hasTicket, isFalse);
      expect(registration.payment.required, isTrue);
      expect(registration.payment.amount, 25000);
      expect(registration.payment.isWaiting, isTrue);
      expect(registration.payment.isPending, isTrue);
      expect(registration.payment.canUploadProof, isFalse);
      expect(registration.payment.statusLabel, 'Menunggu Verifikasi');
    });

    test('pendaftaran lunas punya tiket', () {
      final registration = Registration.fromJson({
        'id': 11,
        'ticket_code': 'POLI-2026-PAID01',
        'status': 'registered',
        'payment': {'required': true, 'status': 'paid'},
      });

      expect(registration.hasTicket, isTrue);
      expect(registration.payment.isPaid, isTrue);
      expect(registration.payment.isPending, isFalse);
    });
  });

  test('User.isAdmin mengikuti role', () {
    const admin = User(
      id: 1,
      name: 'Admin PoliVent',
      nim: '1',
      email: 'a@b.c',
      role: 'admin',
    );
    const user = User(
      id: 2,
      name: 'Mahasiswa',
      nim: '2',
      email: 'm@b.c',
      role: 'user',
    );

    expect(admin.isAdmin, isTrue);
    expect(user.isAdmin, isFalse);
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('salah'), isNotNull);
      expect(Validators.email('mahasiswa@polivent.test'), isNull);
    });

    test('password minimal 6 karakter', () {
      expect(Validators.password('123'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('konfirmasi password', () {
      expect(Validators.confirmPassword('abc', 'xyz'), isNotNull);
      expect(Validators.confirmPassword('abc', 'abc'), isNull);
    });

    test('kuota minimal 1', () {
      expect(Validators.quota('0'), isNotNull);
      expect(Validators.quota('abc'), isNotNull);
      expect(Validators.quota('10'), isNull);
    });

    test('harga tiket boleh 0 tetapi tidak negatif', () {
      expect(Validators.price(null), isNotNull);
      expect(Validators.price('abc'), isNotNull);
      expect(Validators.price('-5000'), isNotNull);
      expect(Validators.price('0'), isNull);
      expect(Validators.price('25.000'), isNull);
    });

    test('nomor admin opsional tetapi formatnya dijaga', () {
      expect(Validators.adminPhone(''), isNull);
      expect(Validators.adminPhone(null), isNull);
      expect(Validators.adminPhone('0812-3456-7890'), isNull);
      expect(Validators.adminPhone('+62 812 3456 7890'), isNull);
      expect(Validators.adminPhone('bukan-nomor'), isNotNull);
      expect(Validators.adminPhone('123'), isNotNull);
      expect(
        Validators.adminPhone('081234567890123456789012345678901'),
        isNotNull,
      );
    });
  });

  test('PaymentSetting membaca nomor admin', () {
    final setting = PaymentSetting.fromJson({
      'account_name': 'BEM Polinela',
      'account_number': '1234567890',
      'admin_phone': '0812-3456-7890',
    });

    expect(setting.adminPhone, '0812-3456-7890');
    expect(setting.hasQr, isFalse);
  });

  test('Formatters menampilkan rupiah', () {
    expect(Formatters.rupiah(0), 'Gratis');
    expect(Formatters.rupiah(25000), 'Rp 25.000');
    expect(Formatters.rupiah(1250000), 'Rp 1.250.000');
  });

  test('Formatters menampilkan tanggal Indonesia', () {
    expect(Formatters.fullDate(DateTime(2026, 1, 5)), 'Senin, 5 Januari 2026');
    expect(Formatters.shortDate(DateTime(2026, 1, 5)), '5 Jan 2026');
    expect(Formatters.timeRange('08:00:00', '12:30:00'), '08:00 - 12:30 WIB');
    expect(Formatters.apiDate(DateTime(2026, 1, 5)), '2026-01-05');
  });
}
